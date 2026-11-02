package com.example.expressive_shade

import android.os.Handler
import android.os.Looper
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
class NotificationsChannelHandler : MethodChannel.MethodCallHandler {

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
                runOffMain(result) { pkg?.let { service?.getAppIconBytes(it) } }
            }
            "cancelNotification" -> {
                val id = call.argument<String>("id")
                if (id != null) service?.cancelNotification(id)
                result.success(id != null)
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
