package com.example.expressive_shade

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Handles `com.expressive_shade/settings`: persists shade settings in SharedPreferences
 * and fans changed keys out to every active Flutter engine.
 */
class SettingsChannelHandler(
    context: Context,
    private val broadcast: (Map<*, *>) -> Unit
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val PREFS_SETTINGS = "expressive_shade_settings"
    }

    private val prefs = context.getSharedPreferences(PREFS_SETTINGS, Context.MODE_PRIVATE)
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getSettings" -> {
                val res = mutableMapOf<String, Any>()
                for ((k, v) in prefs.all) {
                    if (v != null) res[k] = v
                }
                result.success(res)
            }
            "saveSettings" -> {
                val map = call.arguments as? Map<*, *>
                if (map == null) {
                    result.success(false)
                    return
                }
                // Only the keys Dart sent (the changed ones) are written.
                val editor = prefs.edit()
                for ((k, v) in map) {
                    val key = k.toString()
                    when (v) {
                        is Boolean -> editor.putBoolean(key, v)
                        is Int -> editor.putInt(key, v)
                        is Long -> editor.putLong(key, v)
                        is Float -> editor.putFloat(key, v)
                        is Double -> editor.putFloat(key, v.toFloat())
                        is String -> editor.putString(key, v)
                    }
                }
                editor.apply() // asynchronous disk write; in-memory values are updated immediately
                mainHandler.post { broadcast(map) }
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
}
