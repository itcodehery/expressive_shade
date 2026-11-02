package com.example.expressive_shade

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class ShadeOverlayActivity : FlutterActivity() {
    private var overlayChannel: MethodChannel? = null

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return FlutterEngineCache.getInstance().get(ExpressiveApplication.CACHED_ENGINE_ID)
    }

    override fun getBackgroundMode(): FlutterActivityLaunchConfigs.BackgroundMode {
        return FlutterActivityLaunchConfigs.BackgroundMode.transparent
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        overridePendingTransition(0, 0)
        ExpressiveAccessibilityService.isOverlayShowing = true

        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val lp = window.attributes
            lp.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            window.attributes = lp
        }

        window.addFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN or
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
            WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            window.addFlags(WindowManager.LayoutParams.FLAG_BLUR_BEHIND)
            window.attributes.blurBehindRadius = 50
        }

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

    override fun finish() {
        super.finish()
        overridePendingTransition(0, 0)
        ExpressiveAccessibilityService.isOverlayShowing = false
    }

    override fun onPause() {
        super.onPause()
        if (isFinishing) {
            ExpressiveAccessibilityService.isOverlayShowing = false
        }
    }

    override fun onStop() {
        super.onStop()
        ExpressiveAccessibilityService.isOverlayShowing = false
    }

    override fun onDestroy() {
        super.onDestroy()
        ExpressiveAccessibilityService.isOverlayShowing = false
    }
}
