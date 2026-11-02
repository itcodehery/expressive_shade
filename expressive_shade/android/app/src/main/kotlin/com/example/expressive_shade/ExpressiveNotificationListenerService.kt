package com.example.expressive_shade

import android.app.Notification
import android.app.PendingIntent
import android.app.RemoteInput
import android.content.Intent
import android.os.Bundle
import android.content.ComponentName
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import java.io.ByteArrayOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class ExpressiveNotificationListenerService : NotificationListenerService() {
    companion object {
        var instance: ExpressiveNotificationListenerService? = null
            private set

        var onNotificationsChangedListener: (() -> Unit)? = null
        var onMediaChangedListener: (() -> Unit)? = null
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        instance = this
        onNotificationsChangedListener?.invoke()
        onMediaChangedListener?.invoke()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        onNotificationsChangedListener?.invoke()
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        onNotificationsChangedListener?.invoke()
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        instance = null
    }

    private val appIconCache = mutableMapOf<String, ByteArray>()
    private val appLabelCache = java.util.concurrent.ConcurrentHashMap<String, String>()
    // Only used from the bridge's single notification worker thread.
    private val timeFormatter = SimpleDateFormat("h:mm a", Locale.getDefault())

    private fun getAppLabel(packageName: String): String {
        appLabelCache[packageName]?.let { return it }
        val label = try {
            val pm = packageManager
            pm.getApplicationLabel(pm.getApplicationInfo(packageName, 0)).toString()
        } catch (e: Exception) {
            packageName
        }
        appLabelCache[packageName] = label
        return label
    }

    private fun drawableToPngByteArray(drawable: Drawable, width: Int = 96, height: Int = 96): ByteArray? {
        return try {
            val targetW = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth.coerceAtMost(192) else width
            val targetH = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight.coerceAtMost(192) else height
            val bitmap = Bitmap.createBitmap(targetW, targetH, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 90, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            null
        }
    }

    @Synchronized
    fun getAppIconBytes(packageName: String): ByteArray? {
        appIconCache[packageName]?.let { return it }
        return try {
            val drawable = packageManager.getApplicationIcon(packageName)
            val bytes = drawableToPngByteArray(drawable, 96, 96)
            if (bytes != null) {
                appIconCache[packageName] = bytes
            }
            bytes
        } catch (e: Exception) {
            null
        }
    }

    fun getNotificationList(): List<Map<String, Any>> {
        val list = mutableListOf<Map<String, Any>>()
        try {
            val sbns = activeNotifications ?: return list
            val timeFormat = timeFormatter

            for (sbn in sbns) {
                val notification = sbn.notification ?: continue
                val extras = notification.extras ?: continue

                // 1. Filter out Media Player notifications (these are displayed in the dedicated Media Player Card)
                val isMediaCategory = notification.category == Notification.CATEGORY_TRANSPORT
                val hasMediaSession = extras.containsKey(Notification.EXTRA_MEDIA_SESSION)
                val template = extras.getString(Notification.EXTRA_TEMPLATE) ?: ""
                val isMediaTemplate = template.contains("MediaStyle", ignoreCase = true)
                if (isMediaCategory || hasMediaSession || isMediaTemplate) {
                    continue
                }

                val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
                val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
                if (title.isNullOrBlank() && text.isNullOrBlank()) continue

                // 2. Filter out Android system notifications about ExpressiveShade overlaying/displaying over other apps
                val combinedText = "${title ?: ""} ${text ?: ""}"
                val isOwnPackage = sbn.packageName == packageName
                val isSystemOverlayAlert = (sbn.packageName == "android" || sbn.packageName == "com.android.systemui" || isOwnPackage) &&
                        (combinedText.contains("ExpressiveShade", ignoreCase = true) &&
                         (combinedText.contains("displaying over", ignoreCase = true) ||
                          combinedText.contains("displayed over", ignoreCase = true) ||
                          combinedText.contains("drawing over", ignoreCase = true) ||
                          combinedText.contains("active", ignoreCase = true)))
                if (isSystemOverlayAlert || (isOwnPackage && sbn.id == 1001)) {
                    continue
                }

                val appName = getAppLabel(sbn.packageName)

                // Each action keeps its original index so Dart can trigger it later.
                val actions = mutableListOf<Map<String, Any>>()
                notification.actions?.forEachIndexed { index, action ->
                    if (!action.title.isNullOrBlank() && action.actionIntent != null) {
                        actions.add(
                            mapOf(
                                "index" to index,
                                "title" to action.title.toString(),
                                "hasRemoteInput" to (action.remoteInputs?.isNotEmpty() == true)
                            )
                        )
                    }
                }

                val timestamp = timeFormat.format(Date(sbn.postTime))

                val itemMap = mutableMapOf<String, Any>(
                    "id" to sbn.key,
                    "packageName" to sbn.packageName,
                    "appName" to appName,
                    "title" to (title ?: ""),
                    "content" to (text ?: ""),
                    "timestamp" to timestamp,
                    "isOngoing" to sbn.isOngoing,
                    "actions" to actions,
                    "canOpen" to (notification.contentIntent != null)
                )
                list.add(itemMap)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return list
    }

    private fun findNotification(key: String): StatusBarNotification? =
        try { activeNotifications?.firstOrNull { it.key == key } } catch (_: Exception) { null }

    /** Fires a notification action. When [replyText] is set it is delivered through the action's RemoteInput. */
    fun performNotificationAction(key: String, index: Int, replyText: String?): Boolean {
        val sbn = findNotification(key) ?: return false
        val action = sbn.notification.actions?.getOrNull(index) ?: return false
        val pendingIntent = action.actionIntent ?: return false
        return try {
            if (replyText != null) {
                val remoteInputs = action.remoteInputs ?: return false
                val fillIn = Intent()
                val results = Bundle()
                remoteInputs.forEach { results.putCharSequence(it.resultKey, replyText) }
                RemoteInput.addResultsToIntent(remoteInputs, fillIn, results)
                pendingIntent.send(this, 0, fillIn)
            } else {
                pendingIntent.send()
            }
            true
        } catch (e: PendingIntent.CanceledException) {
            false
        }
    }

    /** Launches the notification's content intent and clears it when it is auto-cancel. */
    fun openNotification(key: String): Boolean {
        val sbn = findNotification(key) ?: return false
        val intent = sbn.notification.contentIntent ?: return false
        return try {
            intent.send()
            if (sbn.notification.flags and Notification.FLAG_AUTO_CANCEL != 0) {
                cancelNotification(key)
            }
            true
        } catch (e: PendingIntent.CanceledException) {
            false
        }
    }

    fun snoozeNotificationByKey(key: String, durationMs: Long): Boolean {
        return try {
            snoozeNotification(key, durationMs)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun getActiveMediaState(): Map<String, Any>? {
        return try {
            val mediaSessionManager = getSystemService(Context.MEDIA_SESSION_SERVICE) as? MediaSessionManager ?: return null
            val componentName = ComponentName(this, ExpressiveNotificationListenerService::class.java)
            val controllers = mediaSessionManager.getActiveSessions(componentName)
            val activeController = controllers.firstOrNull { it.playbackState?.state == PlaybackState.STATE_PLAYING }
                ?: controllers.firstOrNull() ?: return null

            val metadata = activeController.metadata
            val playbackState = activeController.playbackState
            val isPlaying = playbackState?.state == PlaybackState.STATE_PLAYING
            val title = metadata?.getString(MediaMetadata.METADATA_KEY_TITLE) ?: "No Media Playing"
            val artist = metadata?.getString(MediaMetadata.METADATA_KEY_ARTIST)
                ?: (metadata?.getString(MediaMetadata.METADATA_KEY_ALBUM_ARTIST) ?: "")
            val duration = metadata?.getLong(MediaMetadata.METADATA_KEY_DURATION) ?: 0L
            val position = playbackState?.position ?: 0L
            val progress = if (duration > 0) (position.toDouble() / duration.toDouble()).coerceIn(0.0, 1.0) else 0.0

            val appName = try {
                val pm = packageManager
                val appInfo = pm.getApplicationInfo(activeController.packageName, 0)
                pm.getApplicationLabel(appInfo).toString()
            } catch (e: Exception) {
                activeController.packageName
            }

            // Extract album artwork bitmap if available
            val artBitmap = metadata?.getBitmap(MediaMetadata.METADATA_KEY_ART)
                ?: metadata?.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)
            val artBytes = artBitmap?.let { bmp ->
                try {
                    val stream = ByteArrayOutputStream()
                    val scaled = Bitmap.createScaledBitmap(bmp, 256, 256, true)
                    scaled.compress(Bitmap.CompressFormat.JPEG, 80, stream)
                    stream.toByteArray()
                } catch (_: Exception) {
                    null
                }
            }

            val res = mutableMapOf<String, Any>(
                "title" to title,
                "artist" to artist,
                "appName" to appName,
                "isPlaying" to isPlaying,
                "progress" to progress
            )
            if (artBytes != null) {
                res["artwork"] = artBytes
            }
            res
        } catch (e: Exception) {
            null
        }
    }

    fun controlMedia(action: String) {
        try {
            val mediaSessionManager = getSystemService(Context.MEDIA_SESSION_SERVICE) as? MediaSessionManager ?: return
            val componentName = ComponentName(this, ExpressiveNotificationListenerService::class.java)
            val controllers = mediaSessionManager.getActiveSessions(componentName)
            val activeController = controllers.firstOrNull { it.playbackState?.state == PlaybackState.STATE_PLAYING }
                ?: controllers.firstOrNull() ?: return

            when (action) {
                "play" -> activeController.transportControls.play()
                "pause" -> activeController.transportControls.pause()
                "toggle" -> {
                    if (activeController.playbackState?.state == PlaybackState.STATE_PLAYING) {
                        activeController.transportControls.pause()
                    } else {
                        activeController.transportControls.play()
                    }
                }
                "next" -> activeController.transportControls.skipToNext()
                "prev" -> activeController.transportControls.skipToPrevious()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun seekTo(progress: Double) {
        try {
            val mediaSessionManager = getSystemService(Context.MEDIA_SESSION_SERVICE) as? MediaSessionManager ?: return
            val componentName = ComponentName(this, ExpressiveNotificationListenerService::class.java)
            val controllers = mediaSessionManager.getActiveSessions(componentName)
            val activeController = controllers.firstOrNull { it.playbackState?.state == PlaybackState.STATE_PLAYING }
                ?: controllers.firstOrNull() ?: return
            val duration = activeController.metadata?.getLong(MediaMetadata.METADATA_KEY_DURATION) ?: 0L
            if (duration > 0) {
                val targetMs = (duration * progress.coerceIn(0.0, 1.0)).toLong()
                activeController.transportControls.seekTo(targetMs)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
