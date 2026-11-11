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
        var isEnabled = false
        var isOverlayShowing = false
    }

    private var windowManager: WindowManager? = null
    private var topTriggerView: View? = null
    private var triggerBallView: View? = null
    private var lastTriggerTime = 0L
    private var lastDeployTime = 0L
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        isEnabled = ServicePrefs.isEnabled(this)
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        if (isEnabled) {
            setupTopGestureTrigger()
        }
        if (ServicePrefs.isTriggerBallEnabled(this)) {
            setupTriggerBall()
        }
    }

    fun setupTopGestureTrigger() {
        mainHandler.post {
            try {
                removeTopGestureTrigger()

                // Strictly match the physical status bar height with no extra padding below it
                val resId = resources.getIdentifier("status_bar_height", "dimen", "android")
                val heightPx = if (resId > 0) resources.getDimensionPixelSize(resId) else (28 * resources.displayMetrics.density).toInt()

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
                                // Only consume touches originating strictly inside the status bar
                                if (startY <= heightPx) true else false
                            }
                            MotionEvent.ACTION_MOVE -> {
                                val dy = event.rawY - startY
                                val dx = Math.abs(event.rawX - startX)
                                // Require a deliberate downward pull (at least 32dp / 60px) and distinctly vertical
                                val minSwipeDistance = (32 * resources.displayMetrics.density).toInt().coerceAtLeast(60)
                                if (dy > minSwipeDistance && dy > dx * 1.5 && !isSwipeTriggered) {
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

                // If accessibility service trigger is active, remove redundant fallback overlay trigger
                ExpressiveOverlayService.instance?.removeFallbackOverlayTrigger()
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

    fun setupTriggerBall() {
        mainHandler.post {
            try {
                removeTriggerBall()
                if (!ServicePrefs.isTriggerBallEnabled(this)) return@post

                val density = resources.displayMetrics.density
                val ballSize = (48 * density).toInt()

                val ballParams = WindowManager.LayoutParams(
                    ballSize,
                    ballSize,
                    WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.END or Gravity.CENTER_VERTICAL
                    x = (4 * density).toInt()
                    y = 0
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                    }
                }

                val ballView = android.widget.FrameLayout(this).apply {
                    val circleDrawable = android.graphics.drawable.GradientDrawable().apply {
                        shape = android.graphics.drawable.GradientDrawable.OVAL
                        setColor(0xEE1E1F22.toInt()) // Deep Material Expressive pill background
                        setStroke((1.5f * density).toInt(), 0x66A8C7FA.toInt()) // Subtle Google Blue accent border
                    }
                    background = circleDrawable
                    elevation = 10f * density

                    // Add an icon inside the ball
                    val icon = android.widget.ImageView(context).apply {
                        val innerDot = android.graphics.drawable.GradientDrawable().apply {
                            shape = android.graphics.drawable.GradientDrawable.OVAL
                            setColor(0xFFD3E3FD.toInt())
                        }
                        setImageDrawable(innerDot)
                        val iconSize = (14 * density).toInt()
                        val lp = android.widget.FrameLayout.LayoutParams(iconSize, iconSize, Gravity.CENTER)
                        layoutParams = lp
                    }
                    addView(icon)

                    var startX = 0f
                    var startY = 0f
                    var initialY = 0
                    var initialTouchY = 0f
                    var isDrag = false

                    setOnTouchListener { v, event ->
                        when (event.actionMasked) {
                            MotionEvent.ACTION_DOWN -> {
                                startX = event.rawX
                                startY = event.rawY
                                initialY = ballParams.y
                                initialTouchY = event.rawY
                                isDrag = false
                                v.animate().scaleX(0.85f).scaleY(0.85f).setDuration(100).start()
                                true
                            }
                            MotionEvent.ACTION_MOVE -> {
                                val deltaY = (event.rawY - initialTouchY).toInt()
                                val dx = Math.abs(event.rawX - startX)
                                val dy = Math.abs(event.rawY - startY)
                                if (dy > 8 * density || dx > 8 * density) {
                                    isDrag = true
                                    ballParams.y = initialY + deltaY
                                    try {
                                        val wm = (getSystemService(Context.WINDOW_SERVICE) as? WindowManager) ?: windowManager
                                        wm?.updateViewLayout(v, ballParams)
                                    } catch (_: Exception) {}
                                }
                                true
                            }
                            MotionEvent.ACTION_UP -> {
                                v.animate().scaleX(1.0f).scaleY(1.0f).setDuration(150).start()
                                if (!isDrag) {
                                    // Smooth toggle!
                                    val overlayAct = ShadeOverlayActivity.currentInstance
                                    if (overlayAct != null && !overlayAct.isFinishing && !overlayAct.isDestroyed) {
                                        overlayAct.requestSmoothDismiss()
                                    } else {
                                        performGlobalAction(GLOBAL_ACTION_DISMISS_NOTIFICATION_SHADE)
                                        deployCustomShade("quick_settings")
                                    }
                                }
                                true
                            }
                            MotionEvent.ACTION_CANCEL -> {
                                v.animate().scaleX(1.0f).scaleY(1.0f).setDuration(150).start()
                                true
                            }
                            else -> false
                        }
                    }
                }

                triggerBallView = ballView
                val wm = (getSystemService(Context.WINDOW_SERVICE) as? WindowManager) ?: windowManager
                wm?.addView(ballView, ballParams)
                ExpressiveOverlayService.instance?.removeTriggerBall()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    fun removeTriggerBall() {
        mainHandler.post {
            try {
                if (triggerBallView != null) {
                    val wm = (getSystemService(Context.WINDOW_SERVICE) as? WindowManager) ?: windowManager
                    wm?.removeView(triggerBallView)
                    triggerBallView = null
                }
            } catch (_: Exception) {}
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        if (isEnabled) {
            setupTopGestureTrigger()
        }
        if (ServicePrefs.isTriggerBallEnabled(this)) {
            setupTriggerBall()
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // No-op: Status bar pull-down is handled strictly by the status bar touch trigger view.
        // Catching general SystemUI window state changes caused false triggers when scrolling in other apps.
    }

    fun deployCustomShade(target: String) {
        val now = System.currentTimeMillis()
        if (now - lastDeployTime < 600) return
        lastDeployTime = now

        val overlayAct = ShadeOverlayActivity.currentInstance
        if (overlayAct != null && !overlayAct.isFinishing && !overlayAct.isDestroyed) {
            return
        }

        isOverlayShowing = true

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
        removeTriggerBall()
        instance = null
        isOverlayShowing = false
    }
}
