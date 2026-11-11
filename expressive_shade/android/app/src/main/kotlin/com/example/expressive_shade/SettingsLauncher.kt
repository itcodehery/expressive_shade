package com.example.expressive_shade

import android.app.Activity
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference

/** Shared helper for the many "open a system settings screen" channel methods. */
object SettingsLauncher {
    private var currentActivityRef: WeakReference<Activity>? = null

    fun setCurrentActivity(activity: Activity?) {
        currentActivityRef = if (activity != null) WeakReference(activity) else null
    }

    private fun launchIntent(fallbackContext: Context, intent: Intent) {
        val act = currentActivityRef?.get()
        if (act != null && !act.isFinishing && !act.isDestroyed) {
            act.startActivity(intent)
        } else {
            fallbackContext.startActivity(intent.apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) })
        }
    }

    /**
     * Starts the first intent that can be launched and reports success.
     * If every candidate fails the error of the last one is returned to Dart.
     */
    fun startFirst(context: Context, result: MethodChannel.Result, vararg candidates: () -> Intent) {
        var lastError: Exception? = null
        for (candidate in candidates) {
            try {
                launchIntent(context, candidate())
                result.success(true)
                return
            } catch (e: Exception) {
                lastError = e
            }
        }
        result.error("ERROR", lastError?.message, null)
    }

    /** Variant for calls that must report `false` instead of an error when launching fails. */
    fun startQuietly(context: Context, vararg intents: Intent): Boolean {
        for (intent in intents) {
            try {
                launchIntent(context, intent)
                return true
            } catch (_: Exception) {}
        }
        return false
    }
}
