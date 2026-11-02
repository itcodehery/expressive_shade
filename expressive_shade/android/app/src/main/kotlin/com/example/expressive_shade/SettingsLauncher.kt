package com.example.expressive_shade

import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.MethodChannel

/** Shared helper for the many "open a system settings screen" channel methods. */
object SettingsLauncher {
    /**
     * Starts the first intent that can be launched and reports success.
     * If every candidate fails the error of the last one is returned to Dart.
     */
    fun startFirst(context: Context, result: MethodChannel.Result, vararg candidates: () -> Intent) {
        var lastError: Exception? = null
        for (candidate in candidates) {
            try {
                context.startActivity(candidate().apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) })
                result.success(true)
                return
            } catch (e: Exception) {
                lastError = e
            }
        }
        result.error("ERROR", lastError?.message, null)
    }

    /** Variant for calls that must report `false` instead of an error when launching fails. */
    fun startQuietly(context: Context, intent: Intent): Boolean = try {
        context.startActivity(intent.apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) })
        true
    } catch (_: Exception) {
        false
    }
}
