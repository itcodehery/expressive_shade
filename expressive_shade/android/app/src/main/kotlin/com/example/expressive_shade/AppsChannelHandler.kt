package com.example.expressive_shade

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

/**
 * Handles `com.expressive_shade/apps`: queries launchable applications,
 * fetches app icons as PNG byte arrays, and launches apps.
 */
class AppsChannelHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val iconCache = ConcurrentHashMap<String, ByteArray>()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInstalledApps" -> {
                executor.execute {
                    try {
                        val pm = context.packageManager
                        val intent = Intent(Intent.ACTION_MAIN, null).apply {
                            addCategory(Intent.CATEGORY_LAUNCHER)
                        }
                        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            PackageManager.MATCH_ALL
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
                            appsList.add(
                                mapOf(
                                    "packageName" to pkg,
                                    "appName" to label
                                )
                            )
                        }
                        appsList.sortBy { (it["appName"] as String).lowercase() }
                        mainHandler.post { result.success(appsList) }
                    } catch (e: Exception) {
                        mainHandler.post { result.error("ERROR", e.message, null) }
                    }
                }
            }
            "getAppIcon" -> {
                val pkg = call.argument<String>("packageName")
                if (pkg.isNullOrEmpty()) {
                    result.success(null)
                    return
                }
                val cached = iconCache[pkg]
                if (cached != null) {
                    result.success(cached)
                    return
                }
                executor.execute {
                    try {
                        val pm = context.packageManager
                        val launchIntent = pm.getLaunchIntentForPackage(pkg)
                        val resolveInfo = if (launchIntent != null) pm.resolveActivity(launchIntent, 0) else null
                        val drawable = resolveInfo?.loadIcon(pm) ?: pm.getApplicationIcon(pkg)
                        val bytes = drawableToPng(drawable)
                        if (bytes != null) {
                            iconCache[pkg] = bytes
                        }
                        mainHandler.post { result.success(bytes) }
                    } catch (_: Exception) {
                        mainHandler.post { result.success(null) }
                    }
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

    private fun drawableToPng(drawable: Drawable, width: Int = 128, height: Int = 128): ByteArray? {
        return try {
            val bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null && !drawable.bitmap.isRecycled) {
                drawable.bitmap
            } else {
                val targetW = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth.coerceIn(48, 192) else width
                val targetH = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight.coerceIn(48, 192) else height
                val bmp = Bitmap.createBitmap(targetW, targetH, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bmp)
                drawable.setBounds(0, 0, targetW, targetH)
                drawable.draw(canvas)
                bmp
            }
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 95, stream)
            stream.toByteArray()
        } catch (_: Exception) {
            null
        }
    }
}
