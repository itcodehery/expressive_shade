package com.example.expressive_shade

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class ShadeOverlayActivity : FlutterActivity() {
    companion object {
        var currentInstance: ShadeOverlayActivity? = null
            private set
        fun isOverlayActive(): Boolean = currentInstance != null && !currentInstance!!.isFinishing && !currentInstance!!.isDestroyed
    }
    private var overlayChannel: MethodChannel? = null

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return FlutterEngineCache.getInstance().get(ExpressiveApplication.CACHED_ENGINE_ID)
    }

    override fun getBackgroundMode(): FlutterActivityLaunchConfigs.BackgroundMode {
        return FlutterActivityLaunchConfigs.BackgroundMode.transparent
    }

    override fun getRenderMode(): RenderMode {
        return RenderMode.texture
    }

    override fun getTransparencyMode(): TransparencyMode {
        return TransparencyMode.transparent
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        currentInstance = this
        overridePendingTransition(0, 0)
        ExpressiveAccessibilityService.isOverlayShowing = true

        window.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val lp = window.attributes
            lp.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            window.attributes = lp
        }

        // Enable high refresh rate (90Hz / 120Hz / 144Hz) to avoid Android 60Hz lock on transparent windows
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val d = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    display
                } else {
                    @Suppress("DEPRECATION")
                    windowManager.defaultDisplay
                }
                d?.let { disp ->
                    val modes = disp.supportedModes
                    var maxMode = disp.mode
                    var maxRate = maxMode.refreshRate
                    for (m in modes) {
                        if (m.refreshRate > maxRate) {
                            maxRate = m.refreshRate
                            maxMode = m
                        }
                    }
                    val lp = window.attributes
                    lp.preferredRefreshRate = maxRate
                    if (maxRate > 60f) {
                        lp.preferredDisplayModeId = maxMode.modeId
                    }
                    window.attributes = lp
                }
            } catch (_: Exception) {}
        }

        window.addFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN or
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
            WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS
        )

        hideSystemStatusBar()
    }

    private fun hideSystemStatusBar() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val lp = window.attributes
            lp.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            window.attributes = lp
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
            window.insetsController?.let { controller ->
                controller.hide(WindowInsets.Type.statusBars())
                controller.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            )
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            hideSystemStatusBar()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Overlay Dismissal Channel
        overlayChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.expressive_shade/overlay_activity").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "dismissOverlay" -> {
                        finish()
                        overridePendingTransition(0, 0)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        ExpressiveNativeBridge.registerChannels(this, flutterEngine)
        dispatchPanelTarget(intent)
    }

    override fun onResume() {
        super.onResume()
        SettingsLauncher.setCurrentActivity(this)
        ExpressiveAccessibilityService.isOverlayShowing = true
        hideSystemStatusBar()
        flutterEngine?.let { engine ->
            val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.expressive_shade/overlay_activity")
            channel.invokeMethod("reloadSettings", null)
        }
        dispatchPanelTarget(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        hideSystemStatusBar()
        flutterEngine?.let { engine ->
            val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.expressive_shade/overlay_activity")
            channel.invokeMethod("reloadSettings", null)
        }
        dispatchPanelTarget(intent)
    }

    private fun dispatchPanelTarget(intent: Intent?) {
        val target = intent?.getStringExtra("EXTRA_PANEL_TARGET") ?: "quick_settings"
        flutterEngine?.let { engine ->
            val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.expressive_shade/overlay_activity")
            channel.invokeMethod("onPanelTargetChanged", target)
        }
    }

    fun requestSmoothDismiss() {
        runOnUiThread {
            val engine = flutterEngine ?: FlutterEngineCache.getInstance().get(ExpressiveApplication.CACHED_ENGINE_ID)
            if (engine != null) {
                val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.expressive_shade/overlay_activity")
                channel.invokeMethod("requestDismiss", null)
            } else {
                finish()
            }
        }
    }

    override fun finish() {
        super.finish()
        overridePendingTransition(0, 0)
        ExpressiveAccessibilityService.isOverlayShowing = false
        if (currentInstance == this) {
            currentInstance = null
        }
    }

    override fun onPause() {
        super.onPause()
        if (isFinishing) {
            ExpressiveAccessibilityService.isOverlayShowing = false
            if (currentInstance == this) {
                currentInstance = null
            }
        }
    }

    override fun onStop() {
        super.onStop()
        ExpressiveAccessibilityService.isOverlayShowing = false
        if (currentInstance == this) {
            currentInstance = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        ExpressiveAccessibilityService.isOverlayShowing = false
        if (currentInstance == this) {
            currentInstance = null
        }
    }
}
