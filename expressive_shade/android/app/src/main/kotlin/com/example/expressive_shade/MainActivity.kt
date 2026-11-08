package com.example.expressive_shade

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val overlayEventsChannel = "com.expressive_shade/overlay_events"
    private var overlayMethodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        SettingsLauncher.setCurrentActivity(this)
        handlePanelIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        SettingsLauncher.setCurrentActivity(this)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handlePanelIntent(intent)
    }

    private fun handlePanelIntent(intent: Intent?) {
        val target = intent?.getStringExtra("EXTRA_PANEL_TARGET") ?: return
        overlayMethodChannel?.invokeMethod("onPanelTriggered", target)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Overlay Trigger Events Channel
        overlayMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, overlayEventsChannel)

        // Register all shared method channels (Monet, Permissions, Service, Hardware, Notifications, Media)
        ExpressiveNativeBridge.registerChannels(this, flutterEngine)
    }
}
