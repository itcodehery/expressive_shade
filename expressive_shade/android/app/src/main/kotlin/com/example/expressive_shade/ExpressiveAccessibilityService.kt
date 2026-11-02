package com.example.expressive_shade

import android.accessibilityservice.AccessibilityService
import android.app.ActivityOptions
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent

class ExpressiveAccessibilityService : AccessibilityService() {
    companion object {
        var instance: ExpressiveAccessibilityService? = null
            private set
        var isEnabled = true
        var isOverlayShowing = false
    }

    private var windowManager: WindowManager? = null
    private var topTriggerView: View? = null
    private var lastTriggerTime = 0L
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        if (isEnabled) {
            setupTopGestureTrigger()
        }
    }

    fun setupTopGestureTrigger() {
        mainHandler.post {
            try {
                removeTopGestureTrigger()

                val resId = resources.getIdentifier("status_bar_height", "dimen", "android")
                val sbHeight = if (resId > 0) resources.getDimensionPixelSize(resId) else (40 * resources.displayMetrics.density).toInt()
                val heightPx = sbHeight.coerceAtLeast((48 * resources.displayMetrics.density).toInt()) + (12 * resources.displayMetrics.density).toInt()

                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    heightPx,
                    WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.TOP or Gravity.START
                    x = 0
                    y = 0
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                    }
                }

                var startX = 0f
                var startY = 0f
                var isSwipeTriggered = false

                topTriggerView = View(this).apply {
                    setOnTouchListener { _, event ->
                        if (!isEnabled || isOverlayShowing) {
                            return@setOnTouchListener false
                        }

                        when (event.actionMasked) {
                            MotionEvent.ACTION_DOWN -> {
                                startX = event.rawX
                                startY = event.rawY
                                isSwipeTriggered = false
                                true // Must return true to receive subsequent ACTION_MOVE events
                            }
                            MotionEvent.ACTION_MOVE -> {
                                val dy = event.rawY - startY
                                val dx = Math.abs(event.rawX - startX)
                                if (dy > 20 && dy > dx * 0.7 && !isSwipeTriggered) {
                                    isSwipeTriggered = true
                                    val screenWidth = resources.displayMetrics.widthPixels
                                    val isLeftSwipe = startX < screenWidth / 2
                                    val target = if (isLeftSwipe) "notifications" else "quick_settings"

                                    // Instantly dismiss any system shade that may have started peek
                                    performGlobalAction(GLOBAL_ACTION_DISMISS_NOTIFICATION_SHADE)
                                    deployCustomShade(target)
                                    true
                                } else {
                                    true
                                }
                            }
                            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                                isSwipeTriggered = false
                                true
                            }
                            else -> false
                        }
                    }
                }

                windowManager?.addView(topTriggerView, params)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    fun removeTopGestureTrigger() {
        try {
            if (topTriggerView != null && windowManager != null) {
                windowManager?.removeView(topTriggerView)
                topTriggerView = null
            }
        } catch (_: Exception) {}
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        if (isEnabled) {
            setupTopGestureTrigger()
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isEnabled || event == null || isOverlayShowing) return

        val eventType = event.eventType
        if (eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val pkg = event.packageName?.toString() ?: ""
            val cls = event.className?.toString() ?: ""

            // Fallback catch: when SystemUI expands a window (like notification shade or quick settings)
            if (pkg.contains("systemui", ignoreCase = true)) {
                val isExcluded = cls.contains("Volume", ignoreCase = true) ||
                        cls.contains("Screenshot", ignoreCase = true) ||
                        cls.contains("Toast", ignoreCase = true) ||
                        cls.contains("Power", ignoreCase = true) ||
                        cls.contains("GlobalActions", ignoreCase = true) ||
                        cls.contains("Biometric", ignoreCase = true) ||
                        cls.contains("Fingerprint", ignoreCase = true)

                if (!isExcluded) {
                    val now = System.currentTimeMillis()
                    if (now - lastTriggerTime > 800) {
                        lastTriggerTime = now
                        performGlobalAction(GLOBAL_ACTION_DISMISS_NOTIFICATION_SHADE)
                        deployCustomShade("notifications")
                    }
                }
            }
        }
    }

    fun deployCustomShade(target: String) {
        if (isOverlayShowing) return
        isOverlayShowing = true

        // Watchdog failsafe: automatically reset flag after 8 seconds
        mainHandler.postDelayed({
            isOverlayShowing = false
        }, 8000)

        val intent = Intent(this, ShadeOverlayActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_NO_ANIMATION
            putExtra("EXTRA_PANEL_TARGET", target)
        }

        try {
            // Android 14 (API 34) and 15 (API 35) Background Activity Launch (BAL) bypass
            val options = ActivityOptions.makeBasic()
            if (Build.VERSION.SDK_INT >= 34) {
                try {
                    val method = ActivityOptions::class.java.getMethod(
                        "setPendingIntentBackgroundActivityStartMode",
                        Int::class.javaPrimitiveType
                    )
                    method.invoke(options, 1) // 1 = MODE_BACKGROUND_ACTIVITY_START_ALLOWED
                } catch (_: Exception) {}
            }

            val pendingIntent = PendingIntent.getActivity(
                this,
                1001,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )
            pendingIntent.send(this, 0, null, null, null, null, options.toBundle())
        } catch (_: Exception) {
            // Fallback to direct startActivity
            try {
                startActivity(intent)
            } catch (e2: Exception) {
                e2.printStackTrace()
                isOverlayShowing = false
            }
        }
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        removeTopGestureTrigger()
        instance = null
        isOverlayShowing = false
    }
}
