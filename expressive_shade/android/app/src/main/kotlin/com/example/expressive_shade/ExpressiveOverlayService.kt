package com.example.expressive_shade

import android.app.ActivityOptions
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import androidx.core.app.NotificationCompat

class ExpressiveOverlayService : Service() {
    companion object {
        var isRunning = false
            private set
        var instance: ExpressiveOverlayService? = null
            private set
        private const val CHANNEL_ID = "expressive_shade_service"
        private const val NOTIFICATION_ID = 1001
    }

    private var windowManager: WindowManager? = null
    private var topTriggerView: View? = null
    private var triggerBallView: View? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        isRunning = true
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!ServicePrefs.isEnabled(this)) {
            // Restarted by the system (START_STICKY) while the user has the service switched off.
            stopSelf()
            return START_NOT_STICKY
        }
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ExpressiveShade Active")
            .setContentText("Swipe down from top edge to open custom shade")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        startForeground(NOTIFICATION_ID, notification)

        // Ensure accessibility service trigger is also connected if running
        ExpressiveAccessibilityService.instance?.setupTopGestureTrigger()
        ExpressiveAccessibilityService.instance?.setupTriggerBall()

        // Also setup fallback overlay trigger if overlay permission is granted
        setupFallbackOverlayTrigger()
        setupTriggerBall()

        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "ExpressiveShade Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps ExpressiveShade active in memory to intercept status bar pull-down gestures"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    fun removeFallbackOverlayTrigger() {
        try {
            if (topTriggerView != null && windowManager != null) {
                windowManager?.removeView(topTriggerView)
                topTriggerView = null
            }
        } catch (_: Exception) {}
    }

    private fun setupFallbackOverlayTrigger() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            return
        }

        // If the accessibility service trigger is active, do not create a duplicate overlay trigger
        if (ExpressiveAccessibilityService.instance != null && ExpressiveAccessibilityService.isEnabled) {
            removeFallbackOverlayTrigger()
            return
        }

        if (topTriggerView != null) return

        // Strictly match the status bar height
        val resId = resources.getIdentifier("status_bar_height", "dimen", "android")
        val heightPx = if (resId > 0) resources.getDimensionPixelSize(resId) else (28 * resources.displayMetrics.density).toInt()
        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            heightPx,
            layoutType,
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
        var isSwipeHandled = false

        topTriggerView = View(this).apply {
            setOnTouchListener { _, event ->
                if (ExpressiveAccessibilityService.isOverlayShowing) {
                    return@setOnTouchListener false
                }

                when (event.actionMasked) {
                    MotionEvent.ACTION_DOWN -> {
                        startX = event.rawX
                        startY = event.rawY
                        isSwipeHandled = false
                        // Only consume touches originating strictly inside the status bar
                        if (startY <= heightPx) true else false
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dy = event.rawY - startY
                        val dx = Math.abs(event.rawX - startX)
                        val minSwipeDistance = (32 * resources.displayMetrics.density).toInt().coerceAtLeast(60)
                        if (dy > minSwipeDistance && dy > dx * 1.5 && !isSwipeHandled) {
                            isSwipeHandled = true
                            val screenWidth = resources.displayMetrics.widthPixels
                            val isLeftSwipe = startX < screenWidth / 2
                            val target = if (isLeftSwipe) "notifications" else "quick_settings"
                            onTopSwipeTriggered(target)
                            true
                        } else {
                            true
                        }
                    }
                    MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                        isSwipeHandled = false
                        true
                    }
                    else -> false
                }
            }
        }

        try {
            windowManager?.addView(topTriggerView, params)
        } catch (_: Exception) {}
    }

    fun onTopSwipeTriggered(target: String) {
        // If accessibility service is available, dismiss stock shade and deploy
        ExpressiveAccessibilityService.instance?.let { acc ->
            acc.performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_DISMISS_NOTIFICATION_SHADE)
            acc.deployCustomShade(target)
            return
        }

        // Direct launch with Android 14+ BAL bypass
        val intent = Intent(this, ShadeOverlayActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_NO_ANIMATION
            putExtra("EXTRA_PANEL_TARGET", target)
        }

        try {
            val options = ActivityOptions.makeBasic()
            if (Build.VERSION.SDK_INT >= 34) {
                try {
                    val method = ActivityOptions::class.java.getMethod(
                        "setPendingIntentBackgroundActivityStartMode",
                        Int::class.javaPrimitiveType
                    )
                    method.invoke(options, 1)
                } catch (_: Exception) {}
            }

            val pendingIntent = PendingIntent.getActivity(
                this,
                1002,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )
            pendingIntent.send(this, 0, null, null, null, null, options.toBundle())
        } catch (_: Exception) {
            try {
                startActivity(intent)
            } catch (e2: Exception) {
                e2.printStackTrace()
            }
        }
    }

    fun setupTriggerBall() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) return
        if (ExpressiveAccessibilityService.instance != null && ExpressiveAccessibilityService.isEnabled) {
            removeTriggerBall()
            return
        }
        if (!ServicePrefs.isTriggerBallEnabled(this)) {
            removeTriggerBall()
            return
        }
        if (triggerBallView != null) return

        try {
            val density = resources.displayMetrics.density
            val ballSize = (44 * density).toInt()

            val ballParams = WindowManager.LayoutParams(
                ballSize,
                ballSize,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                else
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.END or Gravity.CENTER_VERTICAL
                x = 0
                y = 0
            }

            val ballView = android.widget.FrameLayout(this).apply {
                val circleDrawable = android.graphics.drawable.GradientDrawable().apply {
                    shape = android.graphics.drawable.GradientDrawable.OVAL
                    setColor(0xCC2B2D30.toInt())
                    setStroke((1.5f * density).toInt(), 0x66FFFFFF.toInt())
                }
                background = circleDrawable
                elevation = 8f * density

                val icon = android.widget.ImageView(context).apply {
                    val chevron = android.graphics.drawable.GradientDrawable().apply {
                        shape = android.graphics.drawable.GradientDrawable.OVAL
                        setColor(0xFFE2E2E9.toInt())
                    }
                    setImageDrawable(chevron)
                    val iconSize = (16 * density).toInt()
                    val lp = android.widget.FrameLayout.LayoutParams(iconSize, iconSize, Gravity.CENTER)
                    layoutParams = lp
                }
                addView(icon)

                var initialY = 0
                var initialTouchY = 0f
                var isDrag = false

                setOnTouchListener { v, event ->
                    when (event.action) {
                        MotionEvent.ACTION_DOWN -> {
                            initialY = ballParams.y
                            initialTouchY = event.rawY
                            isDrag = false
                            v.animate().scaleX(0.9f).scaleY(0.9f).setDuration(100).start()
                            true
                        }
                        MotionEvent.ACTION_MOVE -> {
                            val deltaY = (event.rawY - initialTouchY).toInt()
                            if (Math.abs(deltaY) > 8 * density) {
                                isDrag = true
                                ballParams.y = initialY + deltaY
                                try {
                                    windowManager?.updateViewLayout(v, ballParams)
                                } catch (_: Exception) {}
                            }
                            true
                        }
                        MotionEvent.ACTION_UP -> {
                            v.animate().scaleX(1.0f).scaleY(1.0f).setDuration(150).start()
                            if (!isDrag) {
                                val overlayAct = ShadeOverlayActivity.currentInstance
                                if (ExpressiveAccessibilityService.isOverlayShowing && overlayAct != null) {
                                    overlayAct.requestSmoothDismiss()
                                } else {
                                    onTopSwipeTriggered("quick_settings")
                                }
                            }
                            true
                        }
                        else -> false
                    }
                }
            }

            triggerBallView = ballView
            windowManager?.addView(ballView, ballParams)
        } catch (_: Exception) {}
    }

    fun removeTriggerBall() {
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            try {
                if (triggerBallView != null && windowManager != null) {
                    windowManager?.removeView(triggerBallView)
                    triggerBallView = null
                }
            } catch (_: Exception) {}
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        removeFallbackOverlayTrigger()
        removeTriggerBall()
        isRunning = false
        instance = null
    }
}
