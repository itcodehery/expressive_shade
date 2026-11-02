package com.example.expressive_shade

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Handles `com.expressive_shade/media`. */
class MediaChannelHandler : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val service = ExpressiveNotificationListenerService.instance
        when (call.method) {
            "getMediaState" -> result.success(service?.getActiveMediaState())
            "controlMedia" -> {
                service?.controlMedia(call.argument<String>("action") ?: "toggle")
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
}
