package com.example.expressive_shade

import android.content.Context
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Handles `com.expressive_shade/monet` (Material You accent color). */
class MonetChannelHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "getSystemAccentColor") {
            result.notImplemented()
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                result.success(context.resources.getColor(android.R.color.system_accent1_500, context.theme))
            } catch (_: Exception) {
                result.success(null)
            }
        } else {
            result.success(null)
        }
    }
}
