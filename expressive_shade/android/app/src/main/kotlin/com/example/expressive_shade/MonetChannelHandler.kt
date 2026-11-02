package com.example.expressive_shade

import android.app.WallpaperColors
import android.app.WallpaperManager
import android.content.Context
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Handles `com.expressive_shade/monet` (Material You / Dynamic Wallpaper Colors). */
class MonetChannelHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "getSystemAccentColor") {
            result.notImplemented()
            return
        }

        try {
            // 1. First choice: Android WallpaperColors API (API 27+ / Android 8.1+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                val wallpaperManager = WallpaperManager.getInstance(context)
                val colors: WallpaperColors? = wallpaperManager.getWallpaperColors(WallpaperManager.FLAG_SYSTEM)
                val primaryColor = colors?.primaryColor
                if (primaryColor != null) {
                    result.success(primaryColor.toArgb())
                    return
                }
            }

            // 2. Second choice: Android 12+ system accent token fallback
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val accentColor = context.resources.getColor(android.R.color.system_accent1_500, context.theme)
                result.success(accentColor)
                return
            }

            result.success(null)
        } catch (_: Exception) {
            result.success(null)
        }
    }
}
