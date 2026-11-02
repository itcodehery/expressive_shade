package com.example.expressive_shade

import android.app.Notification
import android.content.ComponentName
import android.content.Context
import android.graphics.Bitmap
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

    fun getNotificationList(): List<Map<String, Any>> {
        val list = mutableListOf<Map<String, Any>>()
        try {
            val sbns = activeNotifications ?: return list
            val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())
            val pm = packageManager

            for (sbn in sbns) {
                val notification = sbn.notification ?: continue
                val extras = notification.extras ?: continue
                val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
                val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
                if (title.isNullOrBlank() && text.isNullOrBlank()) continue

                val appName = try {
                    val appInfo = pm.getApplicationInfo(sbn.packageName, 0)
                    pm.getApplicationLabel(appInfo).toString()
                } catch (e: Exception) {
                    sbn.packageName
                }

                val actions = mutableListOf<String>()
                notification.actions?.forEach { action ->
                    if (!action.title.isNullOrBlank()) {
                        actions.add(action.title.toString())
                    }
                }

                val timestamp = timeFormat.format(Date(sbn.postTime))

                list.add(
                    mapOf(
                        "id" to sbn.key,
                        "packageName" to sbn.packageName,
                        "appName" to appName,
                        "title" to (title ?: ""),
                        "content" to (text ?: ""),
                        "timestamp" to timestamp,
                        "isOngoing" to sbn.isOngoing,
                        "actions" to actions
                    )
                )
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return list
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
}
