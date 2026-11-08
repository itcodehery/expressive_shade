package com.example.expressive_shade

import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Handles `com.expressive_shade/service` (overlay service lifecycle and shade deployment). */
class ServiceChannelHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startOverlayService" -> {
                ServicePrefs.setEnabled(context, true)
                val intent = Intent(context, ExpressiveOverlayService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                ExpressiveAccessibilityService.isEnabled = true
                ExpressiveAccessibilityService.instance?.setupTopGestureTrigger()
                result.success(true)
            }
            "stopOverlayService" -> {
                ServicePrefs.setEnabled(context, false)
                context.stopService(Intent(context, ExpressiveOverlayService::class.java))
                ExpressiveAccessibilityService.isEnabled = false
                ExpressiveAccessibilityService.instance?.removeTopGestureTrigger()
                result.success(true)
            }
            "isServiceRunning" -> result.success(ServicePrefs.isEnabled(context) && ExpressiveOverlayService.isRunning)
            "deployCustomShade" -> {
                val target = call.argument<String>("target") ?: "quick_settings"
                if (ExpressiveAccessibilityService.instance != null) {
                    ExpressiveAccessibilityService.instance?.deployCustomShade(target)
                } else if (ExpressiveOverlayService.instance != null) {
                    ExpressiveOverlayService.instance?.onTopSwipeTriggered(target)
                } else {
                    val intent = Intent(context, ShadeOverlayActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                                Intent.FLAG_ACTIVITY_NO_ANIMATION
                        putExtra("EXTRA_PANEL_TARGET", target)
                    }
                    context.startActivity(intent)
                }
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
}
