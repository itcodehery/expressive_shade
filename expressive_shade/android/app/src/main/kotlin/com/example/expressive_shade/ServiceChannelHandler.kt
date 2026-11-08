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
            "getInstalledApps" -> {
                try {
                    val pm = context.packageManager
                    val intent = Intent(Intent.ACTION_MAIN, null).apply {
                        addCategory(Intent.CATEGORY_LAUNCHER)
                    }
                    val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        android.content.pm.PackageManager.MATCH_ALL
                    } else {
                        0
                    }
                    val resolveInfos = pm.queryIntentActivities(intent, flags)
                    val appsList = mutableListOf<Map<String, Any>>()
                    val seen = mutableSetOf<String>()
                    for (info in resolveInfos) {
                        val pkg = info.activityInfo?.packageName ?: continue
                        if (pkg == context.packageName || seen.contains(pkg)) continue
                        seen.add(pkg)
                        val label = info.loadLabel(pm)?.toString() ?: pkg
                        appsList.add(mapOf("packageName" to pkg, "appName" to label))
                    }
                    appsList.sortBy { (it["appName"] as String).lowercase() }
                    result.success(appsList)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            "getAppIcon" -> {
                val pkg = call.argument<String>("packageName")
                if (pkg == null) {
                    result.success(null)
                    return
                }
                try {
                    val pm = context.packageManager
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
                    result.success(stream.toByteArray())
                } catch (_: Exception) {
                    result.success(null)
                }
            }
            "launchApp" -> {
                val pkg = call.argument<String>("packageName")
                if (pkg.isNullOrEmpty()) {
                    result.success(false)
                    return
                }
                try {
                    val pm = context.packageManager
                    val launchIntent = pm.getLaunchIntentForPackage(pkg)
                    if (launchIntent != null) {
                        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        context.startActivity(launchIntent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                } catch (_: Exception) {
                    result.success(false)
                }
            }
            else -> result.notImplemented()
        }
    }
}
