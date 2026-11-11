package com.example.expressive_shade

import android.content.Context

/** Persists whether the user has turned the shade service on, so every native component honours it. */
object ServicePrefs {
    private const val FILE = "expressive_shade_service"
    private const val KEY_ENABLED = "service_enabled"
    private const val KEY_TRIGGER_BALL = "trigger_ball_enabled"

    fun isEnabled(context: Context): Boolean =
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE).getBoolean(KEY_ENABLED, false)

    fun setEnabled(context: Context, enabled: Boolean) {
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE).edit().putBoolean(KEY_ENABLED, enabled).apply()
    }

    fun isTriggerBallEnabled(context: Context): Boolean =
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE).getBoolean(KEY_TRIGGER_BALL, true)

    fun setTriggerBallEnabled(context: Context, enabled: Boolean) {
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE).edit().putBoolean(KEY_TRIGGER_BALL, enabled).apply()
    }
}
