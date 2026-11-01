package com.example.expressive_shade

import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.View
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class ShadeOverlayActivity : FlutterActivity() {
    private var overlayChannel: MethodChannel? = null

    override fun getInitialRoute(): String {
        val target = intent?.getStringExtra("EXTRA_PANEL_TARGET") ?: "quick_settings"
        return "/overlay?target=$target"
    }

    override fun getBackgroundMode(): FlutterActivityLaunchConfigs.BackgroundMode {
        return FlutterActivityLaunchConfigs.BackgroundMode.transparent
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            )
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

        // Register all shared native channels (Monet, Hardware, Notifications, Media, Permissions)
        ExpressiveNativeBridge.registerChannels(this, flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val target = intent.getStringExtra("EXTRA_PANEL_TARGET") ?: "quick_settings"
        overlayChannel?.invokeMethod("onPanelTargetChanged", target)
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
