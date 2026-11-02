package com.example.expressive_shade

import android.app.Activity
import android.app.NotificationManager
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.ContentObserver
import android.hardware.camera2.CameraManager
import android.location.LocationManager
import android.media.AudioManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.telephony.TelephonyManager
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object ExpressiveNativeBridge {
    private const val MONET_CHANNEL = "com.expressive_shade/monet"
    private const val PERMISSIONS_CHANNEL = "com.expressive_shade/permissions"
    private const val SERVICE_CHANNEL = "com.expressive_shade/service"
    private const val HARDWARE_CHANNEL = "com.expressive_shade/hardware"
    private const val NOTIFICATIONS_CHANNEL = "com.expressive_shade/notifications"
    private const val MEDIA_CHANNEL = "com.expressive_shade/media"
    private const val SETTINGS_CHANNEL = "com.expressive_shade/settings"
    private const val PREFS_SETTINGS = "expressive_shade_settings"

    private var activeHardwareChannels = mutableListOf<MethodChannel>()
    private var activeNotificationsChannels = mutableListOf<MethodChannel>()
    private var activeMediaChannels = mutableListOf<MethodChannel>()
    private var activeSettingsChannels = mutableListOf<MethodChannel>()

    private var isTorchOn = false
    private var registeredContext: Context? = null
    private val mainHandler = Handler(Looper.getMainLooper())

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
                    isTorchOn = enabled
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
            val state = getSystemHardwareState(context)
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

        // 1. Monet Accent Channel
        MethodChannel(messenger, MONET_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSystemAccentColor") {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    try {
                        val accentColor = context.resources.getColor(android.R.color.system_accent1_500, context.theme)
                        result.success(accentColor)
                    } catch (_: Exception) {
                        result.success(null)
                    }
                } else {
                    result.success(null)
                }
            } else {
                result.notImplemented()
            }
        }

        // 2. System Permissions Channel
        MethodChannel(messenger, PERMISSIONS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermissions" -> {
                    val status = mapOf(
                        "overlay" to isOverlayGranted(context),
                        "accessibility" to isAccessibilityGranted(context),
                        "notification" to isNotificationListenerGranted(context),
                        "writeSettings" to isWriteSettingsGranted(context)
                    )
                    result.success(status)
                }
                "requestOverlayPermission" -> {
                    try {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:${context.packageName}")
                        ).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
                        context.startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            context.startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK })
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("ERROR", e2.message, null)
                        }
                    }
                }
                "requestAccessibilityPermission" -> {
                    try {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        context.startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            context.startActivity(Intent(Settings.ACTION_SETTINGS).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK })
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("ERROR", e2.message, null)
                        }
                    }
                }
                "requestNotificationPermission" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        context.startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            context.startActivity(Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS").apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK })
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("ERROR", e2.message, null)
                        }
                    }
                }
                "requestWriteSettingsPermission" -> {
                    try {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_WRITE_SETTINGS,
                            Uri.parse("package:${context.packageName}")
                        ).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
                        context.startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            context.startActivity(Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK })
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("ERROR", e2.message, null)
                        }
                    }
                }
                "openAppDetailsSettings" -> {
                    try {
                        val intent = Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:${context.packageName}")
                        ).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
                        context.startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 3. Service Control Channel
        MethodChannel(messenger, SERVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startOverlayService" -> {
                    val intent = Intent(context, ExpressiveOverlayService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(intent)
                    } else {
                        context.startService(intent)
                    }
                    ExpressiveAccessibilityService.isEnabled = true
                    ExpressiveAccessibilityService.instance?.setupTopGestureTrigger()
                    result.success(true)
                }
                "stopOverlayService" -> {
                    val intent = Intent(context, ExpressiveOverlayService::class.java)
                    context.stopService(intent)
                    ExpressiveAccessibilityService.isEnabled = false
                    ExpressiveAccessibilityService.instance?.removeTopGestureTrigger()
                    result.success(true)
                }
                "isServiceRunning" -> {
                    result.success(ExpressiveOverlayService.isRunning)
                }
                "deployCustomShade" -> {
                    val target = call.argument<String>("target") ?: "quick_settings"
                    if (ExpressiveAccessibilityService.instance != null) {
                        ExpressiveAccessibilityService.instance?.deployCustomShade(target)
                    } else if (ExpressiveOverlayService.instance != null) {
                        ExpressiveOverlayService.instance?.onTopSwipeTriggered(target)
                    } else {
                        val intent = Intent(context, ShadeOverlayActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                                    Intent.FLAG_ACTIVITY_NO_ANIMATION
                            putExtra("EXTRA_PANEL_TARGET", target)
                        }
                        context.startActivity(intent)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 4. Hardware Controls Channel
        val hwChannel = MethodChannel(messenger, HARDWARE_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialValues", "getSystemHardwareState" -> {
                        val state = getSystemHardwareState(context)
                        result.success(state)
                    }
                    "toggleWifi" -> {
                        try {
                            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                            val newState = !wifiManager.isWifiEnabled
                            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                                @Suppress("DEPRECATION")
                                wifiManager.isWifiEnabled = newState
                                result.success(true)
                            } else {
                                // On Android 10+, open native internet panel sheet
                                val intent = Intent(Settings.Panel.ACTION_INTERNET_CONNECTIVITY).apply {
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                context.startActivity(intent)
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            try {
                                context.startActivity(Intent(Settings.ACTION_WIFI_SETTINGS).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK })
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("ERROR", e2.message, null)
                            }
                        }
                    }
                    "toggleBluetooth" -> {
                        try {
                            val btManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                            val adapter = btManager?.adapter ?: BluetoothAdapter.getDefaultAdapter()
                            if (adapter != null) {
                                if (adapter.isEnabled) {
                                    @Suppress("DEPRECATION")
                                    val disabled = adapter.disable()
                                    result.success(disabled)
                                } else {
                                    @Suppress("DEPRECATION")
                                    val enabled = adapter.enable()
                                    result.success(enabled)
                                }
                            } else {
                                result.success(false)
                            }
                        } catch (_: Exception) {
                            // Fallback to Bluetooth Panel on modern Android
                            try {
                                val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    Intent("android.settings.panel.action.BLUETOOTH")
                                } else {
                                    Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                                }.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
                                context.startActivity(intent)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("ERROR", e2.message, null)
                            }
                        }
                    }
                    "setFlashlight" -> {
                        try {
                            val enabled = call.argument<Boolean>("enabled") ?: !isTorchOn
                            val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
                            val cameraId = cameraManager.cameraIdList.firstOrNull()
                            if (cameraId != null) {
                                cameraManager.setTorchMode(cameraId, enabled)
                                isTorchOn = enabled
                                notifyHardwareStateChanged(context)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "setBrightness" -> {
                        try {
                            val value = call.argument<Double>("value") ?: 0.5
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && Settings.System.canWrite(context)) {
                                val brightnessInt = (value * 255).toInt().coerceIn(0, 255)
                                Settings.System.putInt(context.contentResolver, Settings.System.SCREEN_BRIGHTNESS, brightnessInt)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }
                    "setVolume" -> {
                        try {
                            val value = call.argument<Double>("value") ?: 0.5
                            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                            val maxVol = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                            val targetVol = (value * maxVol).toInt().coerceIn(0, maxVol)
                            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, targetVol, 0)
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }
                    "toggleAutoRotate" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && Settings.System.canWrite(context)) {
                                val current = Settings.System.getInt(context.contentResolver, Settings.System.ACCELEROMETER_ROTATION, 1)
                                val newSetting = if (current == 1) 0 else 1
                                Settings.System.putInt(context.contentResolver, Settings.System.ACCELEROMETER_ROTATION, newSetting)
                                notifyHardwareStateChanged(context)
                                result.success(newSetting == 1)
                            } else {
                                result.success(null)
                            }
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    "toggleDnd" -> {
                        try {
                            val notifManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                            if (notifManager.isNotificationPolicyAccessGranted) {
                                val current = notifManager.currentInterruptionFilter
                                val isDndOn = current != NotificationManager.INTERRUPTION_FILTER_ALL
                                val nextFilter = if (isDndOn) NotificationManager.INTERRUPTION_FILTER_ALL else NotificationManager.INTERRUPTION_FILTER_PRIORITY
                                notifManager.setInterruptionFilter(nextFilter)
                                notifyHardwareStateChanged(context)
                                result.success(!isDndOn)
                            } else {
                                val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).apply {
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                context.startActivity(intent)
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    "openAirplaneSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_AIRPLANE_MODE_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            context.startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    "openLocationSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            context.startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    "openBatterySaverSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            context.startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    "openHotspotSettings" -> {
                        try {
                            val intent = Intent("android.settings.TETHER_SETTINGS").apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            context.startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            try {
                                context.startActivity(Intent(Settings.ACTION_WIRELESS_SETTINGS).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK })
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("ERROR", e2.message, null)
                            }
                        }
                    }
                    "openNightLightSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_DISPLAY_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            context.startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    "openWifiSettings" -> {
                        try {
                            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                Intent(Settings.Panel.ACTION_INTERNET_CONNECTIVITY)
                            } else {
                                Intent(Settings.ACTION_WIFI_SETTINGS)
                            }.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
                            context.startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            try {
                                context.startActivity(Intent(Settings.ACTION_WIFI_SETTINGS).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK })
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("ERROR", e2.message, null)
                            }
                        }
                    }
                    "openMobileDataSettings", "toggleMobileData" -> {
                        try {
                            val intent = Intent(Settings.ACTION_DATA_ROAMING_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            context.startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            try {
                                val intent = Intent(Settings.ACTION_NETWORK_OPERATOR_SETTINGS).apply {
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                context.startActivity(intent)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("ERROR", e2.message, null)
                            }
                        }
                    }
                    "openBluetoothSettings" -> {
                        try {
                            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                try {
                                    Intent("android.settings.panel.action.BLUETOOTH")
                                } catch (_: Exception) {
                                    Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                                }
                            } else {
                                Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                            }.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
                            context.startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            try {
                                context.startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK })
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("ERROR", e2.message, null)
                            }
                        }
                    }
                    "triggerPowerDialog" -> {
                        val handled = ExpressiveAccessibilityService.instance?.performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_POWER_DIALOG) ?: false
                        result.success(handled)
                    }
                    "triggerLockdown" -> {
                        val handled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            ExpressiveAccessibilityService.instance?.performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_LOCK_SCREEN) ?: false
                        } else false
                        result.success(handled)
                    }
                    "triggerScreenshot" -> {
                        val handled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            ExpressiveAccessibilityService.instance?.performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_TAKE_SCREENSHOT) ?: false
                        } else false
                        result.success(handled)
                    }
                    "triggerEmergencyCall" -> {
                        try {
                            val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:112")).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            context.startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
        activeHardwareChannels.add(hwChannel)

        // 5. Notifications Channel
        val notifChannel = MethodChannel(messenger, NOTIFICATIONS_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getNotifications" -> {
                        val list = ExpressiveNotificationListenerService.instance?.getNotificationList() ?: emptyList<Map<String, Any>>()
                        result.success(list)
                    }
                    "cancelNotification" -> {
                        val id = call.argument<String>("id")
                        if (id != null) {
                            ExpressiveNotificationListenerService.instance?.cancelNotification(id)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    "cancelAllNotifications" -> {
                        ExpressiveNotificationListenerService.instance?.cancelAllNotifications()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        activeNotificationsChannels.add(notifChannel)

        // 6. Media Channel
        val medChannel = MethodChannel(messenger, MEDIA_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getMediaState" -> {
                        val state = ExpressiveNotificationListenerService.instance?.getActiveMediaState()
                        result.success(state)
                    }
                    "controlMedia" -> {
                        val action = call.argument<String>("action") ?: "toggle"
                        ExpressiveNotificationListenerService.instance?.controlMedia(action)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        activeMediaChannels.add(medChannel)

        // 7. Settings Channel (Syncs settings across companion app and overlay engine)
        val settingsChannel = MethodChannel(messenger, SETTINGS_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                val prefs = context.getSharedPreferences(PREFS_SETTINGS, Context.MODE_PRIVATE)
                when (call.method) {
                    "getSettings" -> {
                        val all = prefs.all
                        val res = mutableMapOf<String, Any>()
                        for ((k, v) in all) {
                            if (v != null) res[k] = v
                        }
                        result.success(res)
                    }
                    "saveSettings" -> {
                        val map = call.arguments as? Map<*, *>
                        if (map != null) {
                            val editor = prefs.edit()
                            for ((k, v) in map) {
                                val keyStr = k.toString()
                                when (v) {
                                    is Boolean -> editor.putBoolean(keyStr, v)
                                    is Int -> editor.putInt(keyStr, v)
                                    is Long -> editor.putLong(keyStr, v)
                                    is Float -> editor.putFloat(keyStr, v)
                                    is Double -> editor.putFloat(keyStr, v.toFloat())
                                    is String -> editor.putString(keyStr, v)
                                }
                            }
                            editor.commit()

                            // Broadcast settings to all active engines
                            mainHandler.post {
                                for (ch in activeSettingsChannels) {
                                    try {
                                        ch.invokeMethod("onSettingsChanged", map)
                                    } catch (_: Exception) {}
                                }
                            }
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
        activeSettingsChannels.add(settingsChannel)

        // Connect listener callbacks
        ExpressiveNotificationListenerService.onNotificationsChangedListener = {
            mainHandler.post {
                for (ch in activeNotificationsChannels) {
                    try {
                        ch.invokeMethod("onNotificationsChanged", null)
                    } catch (_: Exception) {}
                }
            }
        }

        ExpressiveNotificationListenerService.onMediaChangedListener = {
            mainHandler.post {
                for (ch in activeMediaChannels) {
                    try {
                        ch.invokeMethod("onMediaChanged", null)
                    } catch (_: Exception) {}
                }
            }
        }
    }

    fun getSystemHardwareState(context: Context): Map<String, Any?> {
        val appContext = context.applicationContext

        // 1. Wi-Fi
        var isWifiEnabled = false
        var isWifiConnected = false
        var wifiSsid = "Wi-Fi"
        try {
            val wifiManager = appContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            isWifiEnabled = wifiManager.isWifiEnabled

            val connManager = appContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = connManager.activeNetwork
            val capabilities = connManager.getNetworkCapabilities(network)
            isWifiConnected = capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true

            if (isWifiConnected) {
                val info = wifiManager.connectionInfo
                val rawSsid = info?.ssid?.replace("\"", "") ?: ""
                wifiSsid = if (rawSsid.isNotEmpty() && rawSsid != "<unknown ssid>") rawSsid else "Connected"
            } else {
                wifiSsid = if (isWifiEnabled) "Not connected" else "Off"
            }
        } catch (_: Exception) {}

        // 2. Bluetooth
        var isBtEnabled = false
        var isBtConnected = false
        var btDeviceName = "Bluetooth"
        try {
            val btManager = appContext.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            val adapter = btManager?.adapter ?: BluetoothAdapter.getDefaultAdapter()
            if (adapter != null) {
                isBtEnabled = adapter.isEnabled
                if (isBtEnabled) {
                    val a2dpState = adapter.getProfileConnectionState(BluetoothProfile.A2DP)
                    val headsetState = adapter.getProfileConnectionState(BluetoothProfile.HEADSET)
                    isBtConnected = (a2dpState == BluetoothProfile.STATE_CONNECTED || headsetState == BluetoothProfile.STATE_CONNECTED)

                    if (isBtConnected) {
                        try {
                            val bonded = adapter.bondedDevices
                            val connectedDevice = bonded.firstOrNull()
                            btDeviceName = connectedDevice?.name ?: "Connected"
                        } catch (_: Exception) {
                            btDeviceName = "Connected"
                        }
                    } else {
                        btDeviceName = "On"
                    }
                } else {
                    btDeviceName = "Off"
                }
            }
        } catch (_: Exception) {}

        // 3. Audio & Brightness
        var volumeRatio = 0.5
        var brightnessRatio = 0.5
        var autoRotate = true
        try {
            val audioManager = appContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val maxVol = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).toDouble()
            val curVol = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble()
            volumeRatio = if (maxVol > 0) curVol / maxVol else 0.5

            val brightnessInt = Settings.System.getInt(appContext.contentResolver, Settings.System.SCREEN_BRIGHTNESS, 128)
            brightnessRatio = brightnessInt.toDouble() / 255.0

            val autoRotateInt = Settings.System.getInt(appContext.contentResolver, Settings.System.ACCELEROMETER_ROTATION, 1)
            autoRotate = (autoRotateInt == 1)
        } catch (_: Exception) {}

        // 4. Do Not Disturb
        var isDnd = false
        try {
            val notifManager = appContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            isDnd = notifManager.currentInterruptionFilter != NotificationManager.INTERRUPTION_FILTER_ALL
        } catch (_: Exception) {}

        // 5. Airplane Mode
        var isAirplane = false
        try {
            isAirplane = Settings.Global.getInt(appContext.contentResolver, Settings.Global.AIRPLANE_MODE_ON, 0) == 1
        } catch (_: Exception) {}

        // 6. Location (GPS)
        var isLocation = false
        try {
            val locManager = appContext.getSystemService(Context.LOCATION_SERVICE) as LocationManager
            isLocation = locManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
        } catch (_: Exception) {}

        // 7. Battery Saver
        var isBatterySaver = false
        try {
            val powerManager = appContext.getSystemService(Context.POWER_SERVICE) as PowerManager
            isBatterySaver = powerManager.isPowerSaveMode
        } catch (_: Exception) {}

        // 8. Battery Percentage & Charging
        var batteryLevel = 100
        var isCharging = false
        try {
            val batteryIntent = appContext.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            val rawLevel = batteryIntent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale = batteryIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
            if (rawLevel >= 0 && scale > 0) {
                batteryLevel = (rawLevel * 100) / scale
            }
            val status = batteryIntent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
            isCharging = (status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL)
        } catch (_: Exception) {}

        // 9. Carrier Name
        var carrierName = "No SIM"
        try {
            val telManager = appContext.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            val netName = telManager.networkOperatorName
            val simName = telManager.simOperatorName
            carrierName = when {
                netName.isNotBlank() -> netName
                simName.isNotBlank() -> simName
                else -> "Mobile"
            }
        } catch (_: Exception) {}

        return mapOf(
            "wifi" to mapOf(
                "enabled" to isWifiEnabled,
                "connected" to isWifiConnected,
                "ssid" to wifiSsid
            ),
            "bluetooth" to mapOf(
                "enabled" to isBtEnabled,
                "connected" to isBtConnected,
                "name" to btDeviceName
            ),
            "flashlight" to isTorchOn,
            "brightness" to brightnessRatio,
            "volume" to volumeRatio,
            "autoRotate" to autoRotate,
            "dnd" to isDnd,
            "airplane" to isAirplane,
            "location" to isLocation,
            "batterySaver" to isBatterySaver,
            "battery" to mapOf(
                "level" to batteryLevel,
                "isCharging" to isCharging
            ),
            "carrier" to carrierName
        )
    }

    private fun isOverlayGranted(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            true
        }
    }

    private fun isAccessibilityGranted(context: Context): Boolean {
        val enabledServices = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val expectedService = "${context.packageName}/${ExpressiveAccessibilityService::class.java.canonicalName}"
        val shortService = "${context.packageName}/.ExpressiveAccessibilityService"
        return enabledServices.contains(expectedService) || enabledServices.contains(shortService)
    }

    private fun isNotificationListenerGranted(context: Context): Boolean {
        return NotificationManagerCompat.getEnabledListenerPackages(context).contains(context.packageName)
    }

    private fun isWriteSettingsGranted(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.System.canWrite(context)
        } else {
            true
        }
    }
}
