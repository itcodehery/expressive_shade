package com.example.expressive_shade

import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Handles `com.expressive_shade/notifications`.
 *
 * Reading the active notifications (and rendering app icons) is slow, so it runs on a
 * single background worker and results are posted back to the main thread. A single
 * worker also keeps the non-thread-safe date formatter in the listener service safe.
 */
class NotificationsChannelHandler(private val context: Context? = null) : MethodChannel.MethodCallHandler {

    private val worker = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private val service get() = ExpressiveNotificationListenerService.instance

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getNotifications" -> runOffMain(result) {
                service?.getNotificationList() ?: emptyList<Map<String, Any>>()
            }
            // Icons are fetched once per package; Dart caches them.
            "getAppIcon" -> {
                val pkg = call.argument<String>("packageName")
                runOffMain(result) {
                    if (pkg == null) null
                    else {
                        service?.getAppIconBytes(pkg) ?: context?.let { ctx ->
                            try {
                                val pm = ctx.packageManager
                                val launchIntent = pm.getLaunchIntentForPackage(pkg)
                                val resolveInfo = if (launchIntent != null) pm.resolveActivity(launchIntent, 0) else null
                                val drawable = resolveInfo?.loadIcon(pm) ?: pm.getApplicationIcon(pkg)
                                val bitmap = if (drawable is android.graphics.drawable.BitmapDrawable && drawable.bitmap != null && !drawable.bitmap.isRecycled) {
                                    drawable.bitmap
                                } else {
                                    val targetW = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth.coerceIn(48, 192) else 128
                                    val targetH = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight.coerceIn(48, 192) else 128
                                    val bmp = android.graphics.Bitmap.createBitmap(targetW, targetH, android.graphics.Bitmap.Config.ARGB_8888)
                                    val canvas = android.graphics.Canvas(bmp)
                                    drawable.setBounds(0, 0, targetW, targetH)
                                    drawable.draw(canvas)
                                    bmp
                                }
                                val stream = java.io.ByteArrayOutputStream()
                                bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 95, stream)
                                stream.toByteArray()
                            } catch (_: Exception) { null }
                        }
                    }
                }
            }
            "cancelNotification" -> {
                val id = call.argument<String>("id")
                var cancelled = false
                val s = service
                if (id != null && s != null) {
                    try {
                        s.cancelNotification(id)
                        cancelled = true
                    } catch (_: Exception) {}
                    try {
                        val sbn = s.activeNotifications?.firstOrNull { it.key == id }
                        if (sbn != null && sbn.isClearable) {
                            @Suppress("DEPRECATION")
                            s.cancelNotification(sbn.packageName, sbn.tag, sbn.id)
                            cancelled = true
                        }
                    } catch (_: Exception) {}
                } else if (context != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    try {
                        NotificationListenerService.requestRebind(
                            ComponentName(context, ExpressiveNotificationListenerService::class.java)
                        )
                    } catch (_: Exception) {}
                }
                result.success(cancelled)
            }
            "performNotificationAction" -> {
                val id = call.argument<String>("id")
                val index = call.argument<Int>("index")
                val reply = call.argument<String>("replyText")
                result.success(
                    if (id != null && index != null) service?.performNotificationAction(id, index, reply) ?: false
                    else false
                )
            }
            "openNotification" -> {
                val id = call.argument<String>("id")
                result.success(id != null && (service?.openNotification(id) ?: false))
            }
            "snoozeNotification" -> {
                val id = call.argument<String>("id")
                val durationMs = call.argument<Number>("durationMs")?.toLong() ?: 3_600_000L
                result.success(id != null && (service?.snoozeNotificationByKey(id, durationMs) ?: false))
            }
            "cancelAllNotifications" -> {
                service?.cancelAllNotifications()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun runOffMain(result: MethodChannel.Result, block: () -> Any?) {
        worker.execute {
            val value = try {
                block()
            } catch (e: Exception) {
                null
            }
            mainHandler.post { result.success(value) }
        }
    }
}
