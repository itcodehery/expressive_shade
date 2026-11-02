package com.example.expressive_shade

import android.app.NotificationManager
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.ContentObserver
import android.hardware.camera2.CameraManager
import android.location.LocationManager
import android.net.ConnectivityManager
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Entry point that wires the native Flutter channels. Each channel's logic lives in its own
 * handler class; this object only owns registration, system listeners and engine fan-out.
 */
object ExpressiveNativeBridge {
    private const val MONET_CHANNEL = "com.expressive_shade/monet"
    private const val PERMISSIONS_CHANNEL = "com.expressive_shade/permissions"
    private const val SERVICE_CHANNEL = "com.expressive_shade/service"
    private const val HARDWARE_CHANNEL = "com.expressive_shade/hardware"
    private const val NOTIFICATIONS_CHANNEL = "com.expressive_shade/notifications"
    private const val MEDIA_CHANNEL = "com.expressive_shade/media"
    private const val SETTINGS_CHANNEL = "com.expressive_shade/settings"

    // Coalesce bursts of notification events into a single refresh.
    private const val NOTIFICATION_REFRESH_DEBOUNCE_MS = 150L

    private val activeHardwareChannels = mutableListOf<MethodChannel>()
    private val activeNotificationsChannels = mutableListOf<MethodChannel>()
    private val activeMediaChannels = mutableListOf<MethodChannel>()
    private val activeSettingsChannels = mutableListOf<MethodChannel>()

    private var registeredContext: Context? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val notifyNotificationsRunnable = Runnable {
        for (ch in activeNotificationsChannels) {
            try { ch.invokeMethod("onNotificationsChanged", null) } catch (_: Exception) {}
        }
    }

    fun init(context: Context) {
        if (registeredContext != null) return
        val appContext = context.applicationContext
        registeredContext = appContext

        // 1. Camera Torch Callback to track hardware flashlight
        try {
            val cameraManager = appContext.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            cameraManager.registerTorchCallback(object : CameraManager.TorchCallback() {
                override fun onTorchModeChanged(cameraId: String, enabled: Boolean) {
                    super.onTorchModeChanged(cameraId, enabled)
                    HardwareState.isTorchOn = enabled
                    notifyHardwareStateChanged(appContext)
                }
            }, mainHandler)
        } catch (_: Exception) {}

        // 2. Hardware Broadcast Receivers
        val filter = IntentFilter().apply {
            addAction(WifiManager.WIFI_STATE_CHANGED_ACTION)
            addAction(WifiManager.NETWORK_STATE_CHANGED_ACTION)
            addAction(ConnectivityManager.CONNECTIVITY_ACTION)
            addAction(BluetoothAdapter.ACTION_STATE_CHANGED)
            addAction(BluetoothDevice.ACTION_ACL_CONNECTED)
            addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
            addAction(Intent.ACTION_BATTERY_CHANGED)
            addAction(Intent.ACTION_AIRPLANE_MODE_CHANGED)
            addAction(NotificationManager.ACTION_INTERRUPTION_FILTER_CHANGED)
            addAction(LocationManager.PROVIDERS_CHANGED_ACTION)
            addAction(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED)
        }

        try {
            appContext.registerReceiver(object : BroadcastReceiver() {
                override fun onReceive(ctx: Context?, intent: Intent?) {
                    notifyHardwareStateChanged(appContext)
                }
            }, filter)
        } catch (_: Exception) {}

        // 3. Settings Content Observer for Auto-Rotate
        try {
            appContext.contentResolver.registerContentObserver(
                Settings.System.getUriFor(Settings.System.ACCELEROMETER_ROTATION),
                true,
                object : ContentObserver(mainHandler) {
                    override fun onChange(selfChange: Boolean) {
                        super.onChange(selfChange)
                        notifyHardwareStateChanged(appContext)
                    }
                }
            )
        } catch (_: Exception) {}
    }

    fun notifyHardwareStateChanged(context: Context) {
        mainHandler.post {
            val state = HardwareState.read(context)
            for (channel in activeHardwareChannels) {
                try {
                    channel.invokeMethod("onHardwareStateChanged", state)
                } catch (_: Exception) {}
            }
        }
    }

    fun registerChannels(context: Context, flutterEngine: FlutterEngine) {
        init(context)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, MONET_CHANNEL).setMethodCallHandler(MonetChannelHandler(context))
        MethodChannel(messenger, PERMISSIONS_CHANNEL).setMethodCallHandler(PermissionsChannelHandler(context))
        MethodChannel(messenger, SERVICE_CHANNEL).setMethodCallHandler(ServiceChannelHandler(context))

        activeHardwareChannels.add(
            MethodChannel(messenger, HARDWARE_CHANNEL).apply {
                setMethodCallHandler(HardwareChannelHandler(context) { notifyHardwareStateChanged(context) })
            }
        )
        activeNotificationsChannels.add(
            MethodChannel(messenger, NOTIFICATIONS_CHANNEL).apply {
                setMethodCallHandler(NotificationsChannelHandler())
            }
        )
        activeMediaChannels.add(
            MethodChannel(messenger, MEDIA_CHANNEL).apply { setMethodCallHandler(MediaChannelHandler()) }
        )
        activeSettingsChannels.add(
            MethodChannel(messenger, SETTINGS_CHANNEL).apply {
                setMethodCallHandler(SettingsChannelHandler(context) { changed -> broadcastSettings(changed) })
            }
        )

        // Connect listener callbacks
        ExpressiveNotificationListenerService.onNotificationsChangedListener = {
            mainHandler.removeCallbacks(notifyNotificationsRunnable)
            mainHandler.postDelayed(notifyNotificationsRunnable, NOTIFICATION_REFRESH_DEBOUNCE_MS)
        }
        ExpressiveNotificationListenerService.onMediaChangedListener = {
            mainHandler.post {
                for (ch in activeMediaChannels) {
                    try { ch.invokeMethod("onMediaChanged", null) } catch (_: Exception) {}
                }
            }
        }
    }

    private fun broadcastSettings(changed: Map<*, *>) {
        for (ch in activeSettingsChannels) {
            try { ch.invokeMethod("onSettingsChanged", changed) } catch (_: Exception) {}
        }
    }
}
