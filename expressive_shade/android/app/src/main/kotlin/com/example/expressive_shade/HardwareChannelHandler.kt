package com.example.expressive_shade

import android.accessibilityservice.AccessibilityService
import android.app.NotificationManager
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.hardware.camera2.CameraManager
import android.location.LocationManager
import android.media.AudioManager
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.telephony.TelephonyManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Handles `com.expressive_shade/hardware`: Quick Settings toggles, sliders,
 * settings shortcuts and accessibility global actions.
 *
 * [onStateChanged] is invoked after a call mutates hardware state so listeners can refresh.
 */
class HardwareChannelHandler(
    private val context: Context,
    private val onStateChanged: () -> Unit
) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInitialValues", "getSystemHardwareState" -> result.success(HardwareState.read(context))
            "toggleWifi" -> toggleWifi(result)
            "toggleBluetooth" -> toggleBluetooth(result)
            "setFlashlight" -> setFlashlight(call, result)
            "setBrightness" -> setBrightness(call, result)
            "setVolume" -> setVolume(call, result)
            "setRingerMode" -> setRingerMode(call, result)
            "toggleAutoRotate" -> toggleAutoRotate(result)
            "toggleDnd" -> toggleDnd(result)
            "toggleBatterySaver" -> toggleBatterySaver(result)
            "toggleAirplane" -> toggleAirplane(result)
            "toggleHotspot" -> toggleHotspot(result)
            "toggleLocation" -> toggleLocation(result)
            "toggleNightLight" -> toggleNightLight(result)
            "toggleNfc" -> toggleNfc(result)
            "toggleMobileData" -> toggleMobileData(result)
            "toggleDataSaver" -> toggleDataSaver(result)
            "setZenMode" -> setZenMode(call, result)
            "openModesSettings" -> open(
                result,
                { Intent("android.settings.ZEN_MODE_SETTINGS") },
                { Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS) },
                { Intent(Settings.ACTION_SOUND_SETTINGS) }
            )
            "triggerCast", "openCastSettings" -> open(
                result,
                { Intent("android.settings.CAST_SETTINGS") },
                { Intent("com.android.settings.action.MEDIA_OUTPUT") },
                { Intent(Settings.ACTION_DISPLAY_SETTINGS) }
            )
            "openDataSaverSettings" -> open(
                result,
                { Intent("android.settings.DATA_SAVER_SETTINGS") },
                { Intent(Settings.ACTION_WIRELESS_SETTINGS) }
            )
            "toggleExtraDim" -> toggleExtraDim(result)
            "openExtraDimSettings" -> open(
                result,
                { Intent("android.settings.REDUCE_BRIGHT_COLORS_SETTINGS") },
                { Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS) }
            )
            "openQrScanner" -> openQrScanner(result)
            "openNfcSettings" -> open(result, { Intent(Settings.ACTION_NFC_SETTINGS) })
            "openCalculator" -> openCalculator(result)
            "openAlarm" -> open(result, { Intent(android.provider.AlarmClock.ACTION_SHOW_ALARMS) })
            "openAirplaneSettings" -> open(result, { Intent(Settings.ACTION_AIRPLANE_MODE_SETTINGS) })
            "openLocationSettings" -> open(result, { Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS) })
            "openBatterySaverSettings" -> open(result, { Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS) })
            "openHotspotSettings" -> open(
                result,
                { Intent("android.settings.TETHER_SETTINGS") },
                { Intent(Settings.ACTION_WIRELESS_SETTINGS) }
            )
            "openNightLightSettings" -> open(result, { Intent(Settings.ACTION_DISPLAY_SETTINGS) })
            "openWifiSettings" -> open(
                result,
                {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) Intent(Settings.Panel.ACTION_INTERNET_CONNECTIVITY)
                    else Intent(Settings.ACTION_WIFI_SETTINGS)
                },
                { Intent(Settings.ACTION_WIFI_SETTINGS) }
            )
            "openMobileDataSettings" -> open(
                result,
                { Intent(Settings.ACTION_DATA_ROAMING_SETTINGS) },
                { Intent(Settings.ACTION_NETWORK_OPERATOR_SETTINGS) }
            )
            "openBluetoothSettings" -> open(
                result,
                { bluetoothIntent() },
                { Intent(Settings.ACTION_BLUETOOTH_SETTINGS) }
            )
            "openSettings" -> open(result, { Intent(Settings.ACTION_SETTINGS) })
            "openShadeApp" -> open(
                result,
                {
                    Intent(context, MainActivity::class.java).apply {
                        addFlags(
                            Intent.FLAG_ACTIVITY_NEW_TASK or
                                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                                Intent.FLAG_ACTIVITY_CLEAR_TOP
                        )
                    }
                }
            )
            "openNotificationHistory" -> open(
                result,
                { Intent("android.settings.NOTIFICATION_HISTORY") },
                { Intent("android.settings.ALL_APPS_NOTIFICATION_SETTINGS") },
                { Intent(Settings.ACTION_SETTINGS) }
            )
            "openAppNotificationSettings" -> {
                val pkg = call.argument<String>("packageName")
                if (!pkg.isNullOrEmpty()) {
                    open(
                        result,
                        {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, pkg)
                            }
                        },
                        { Intent("android.settings.ALL_APPS_NOTIFICATION_SETTINGS") },
                        { Intent(Settings.ACTION_SETTINGS) }
                    )
                } else {
                    open(
                        result,
                        { Intent("android.settings.ALL_APPS_NOTIFICATION_SETTINGS") },
                        { Intent(Settings.ACTION_SETTINGS) }
                    )
                }
            }
            "triggerPowerDialog" -> result.success(globalAction(AccessibilityService.GLOBAL_ACTION_POWER_DIALOG, 0))
            "triggerLockdown" -> result.success(
                globalAction(AccessibilityService.GLOBAL_ACTION_LOCK_SCREEN, Build.VERSION_CODES.P)
            )
            "triggerScreenshot" -> result.success(
                globalAction(AccessibilityService.GLOBAL_ACTION_TAKE_SCREENSHOT, Build.VERSION_CODES.P)
            )
            "triggerEmergencyCall" -> result.success(
                SettingsLauncher.startQuietly(context, Intent(Intent.ACTION_DIAL, Uri.parse("tel:112")))
            )
            else -> result.notImplemented()
        }
    }

    private fun open(result: MethodChannel.Result, vararg candidates: () -> Intent) =
        SettingsLauncher.startFirst(context, result, *candidates)

    private fun bluetoothIntent(): Intent =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) Intent("android.settings.panel.action.BLUETOOTH")
        else Intent(Settings.ACTION_BLUETOOTH_SETTINGS)

    private fun globalAction(action: Int, minSdk: Int): Boolean {
        if (Build.VERSION.SDK_INT < minSdk) return false
        return ExpressiveAccessibilityService.instance?.performGlobalAction(action) ?: false
    }

    private fun toggleWifi(result: MethodChannel.Result) {
        try {
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                @Suppress("DEPRECATION")
                wifiManager.isWifiEnabled = !wifiManager.isWifiEnabled
                result.success(true)
            } else {
                // On Android 10+, apps can't toggle Wi-Fi; open the native internet panel instead.
                open(result, { Intent(Settings.Panel.ACTION_INTERNET_CONNECTIVITY) })
            }
        } catch (e: Exception) {
            open(result, { Intent(Settings.ACTION_WIFI_SETTINGS) })
        }
    }

    private fun toggleBluetooth(result: MethodChannel.Result) {
        try {
            val btManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            val adapter = btManager?.adapter ?: BluetoothAdapter.getDefaultAdapter()
            if (adapter != null) {
                if (adapter.isEnabled) {
                    // Modern Android prohibits disabling Bluetooth directly for 3rd-party apps.
                    // Attempt Global write if WRITE_SECURE_SETTINGS is present.
                    var disabled = false
                    try {
                        Settings.Global.putInt(context.contentResolver, "bluetooth_on", 0)
                        disabled = true
                    } catch (_: Exception) {}

                    if (!disabled) {
                        try {
                            @Suppress("DEPRECATION")
                            disabled = adapter.disable()
                        } catch (_: Exception) {}
                    }

                    if (!disabled) {
                        // Open bluetooth settings or quick panel if programmatic disable is blocked
                        SettingsLauncher.startQuietly(context, Intent(Settings.ACTION_BLUETOOTH_SETTINGS))
                    }
                    onStateChanged()
                    result.success(disabled)
                } else {
                    // To turn ON: try programmatic first, then launch system prompt
                    var enabled = false
                    try {
                        Settings.Global.putInt(context.contentResolver, "bluetooth_on", 1)
                        enabled = true
                    } catch (_: Exception) {}

                    if (!enabled) {
                        try {
                            @Suppress("DEPRECATION")
                            enabled = adapter.enable()
                        } catch (_: Exception) {}
                    }

                    if (!enabled) {
                        // Launch the system permission consent request dialog (doesn't kick user out to settings)
                        val enableIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        SettingsLauncher.startQuietly(context, enableIntent)
                    }
                    onStateChanged()
                    result.success(true)
                }
            } else {
                result.success(false)
            }
        } catch (_: Exception) {
            result.success(false)
        }
    }

    private fun setFlashlight(call: MethodCall, result: MethodChannel.Result) {
        try {
            val enabled = call.argument<Boolean>("enabled") ?: !HardwareState.isTorchOn
            val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val cameraId = cameraManager.cameraIdList.firstOrNull()
            if (cameraId != null) {
                cameraManager.setTorchMode(cameraId, enabled)
                HardwareState.isTorchOn = enabled
                onStateChanged()
                result.success(true)
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun setBrightness(call: MethodCall, result: MethodChannel.Result) {
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

    private fun setVolume(call: MethodCall, result: MethodChannel.Result) {
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

    private fun setRingerMode(call: MethodCall, result: MethodChannel.Result) {
        try {
            val mode = (call.argument<Int>("mode") ?: AudioManager.RINGER_MODE_NORMAL).coerceIn(0, 2)
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val notifManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val targetRingerMode = when (mode) {
                0 -> AudioManager.RINGER_MODE_SILENT
                1 -> AudioManager.RINGER_MODE_VIBRATE
                else -> AudioManager.RINGER_MODE_NORMAL
            }

            if ((targetRingerMode == AudioManager.RINGER_MODE_SILENT ||
                    audioManager.ringerMode == AudioManager.RINGER_MODE_SILENT) &&
                !notifManager.isNotificationPolicyAccessGranted
            ) {
                try {
                    audioManager.ringerMode = targetRingerMode
                    onStateChanged()
                    result.success(true)
                    return
                } catch (_: SecurityException) {
                    SettingsLauncher.startQuietly(
                        context,
                        Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                    )
                    result.success(false)
                    return
                }
            }

            if (targetRingerMode != AudioManager.RINGER_MODE_SILENT &&
                notifManager.isNotificationPolicyAccessGranted &&
                notifManager.currentInterruptionFilter != NotificationManager.INTERRUPTION_FILTER_ALL
            ) {
                try {
                    notifManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                } catch (_: Exception) {}
            }

            audioManager.ringerMode = targetRingerMode
            onStateChanged()
            result.success(true)
        } catch (_: SecurityException) {
            SettingsLauncher.startQuietly(
                context,
                Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            )
            result.success(false)
        } catch (_: Exception) {
            result.success(false)
        }
    }

    private fun toggleAutoRotate(result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && Settings.System.canWrite(context)) {
                val current = Settings.System.getInt(context.contentResolver, Settings.System.ACCELEROMETER_ROTATION, 1)
                val newSetting = if (current == 1) 0 else 1
                Settings.System.putInt(context.contentResolver, Settings.System.ACCELEROMETER_ROTATION, newSetting)
                result.success(newSetting == 1)
            } else {
                result.success(null)
            }
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }

    private fun toggleDnd(result: MethodChannel.Result) {
        try {
            val notifManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (notifManager.isNotificationPolicyAccessGranted) {
                val isDndOn = notifManager.currentInterruptionFilter != NotificationManager.INTERRUPTION_FILTER_ALL
                notifManager.setInterruptionFilter(
                    if (isDndOn) NotificationManager.INTERRUPTION_FILTER_ALL
                    else NotificationManager.INTERRUPTION_FILTER_PRIORITY
                )
                onStateChanged()
                result.success(!isDndOn)
            } else {
                SettingsLauncher.startQuietly(context, Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                result.success(null) // Return null so client knows permission is required
            }
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }

    private fun setZenMode(call: MethodCall, result: MethodChannel.Result) {
        try {
            val mode = call.argument<String>("mode") ?: "normal"
            val notifManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (!notifManager.isNotificationPolicyAccessGranted) {
                SettingsLauncher.startQuietly(context, Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                result.success(false)
                return
            }

            when (mode.lowercase()) {
                "dnd", "priority" -> {
                    notifManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                }
                "alarms", "sleep", "bedtime" -> {
                    notifManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALARMS)
                }
                "silent", "none" -> {
                    notifManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
                }
                "work", "focus" -> {
                    notifManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                }
                else -> {
                    notifManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                }
            }
            onStateChanged()
            result.success(true)
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }

    private fun toggleBatterySaver(result: MethodChannel.Result) {
        try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            val isCurrentlyOn = powerManager?.isPowerSaveMode == true
            val target = if (isCurrentlyOn) 0 else 1
            
            var success = false
            try {
                // Try writing global low_power setting (works if WRITE_SECURE_SETTINGS granted)
                success = Settings.Global.putInt(context.contentResolver, "low_power", target)
            } catch (_: Exception) {}

            if (!success) {
                // Open Battery Saver settings directly so user can toggle in 1 tap
                SettingsLauncher.startQuietly(context, Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS))
                result.success(null)
            } else {
                onStateChanged()
                result.success(target == 1)
            }
        } catch (_: Exception) {
            SettingsLauncher.startQuietly(context, Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS))
            result.success(null)
        }
    }

    private fun toggleAirplane(result: MethodChannel.Result) {
        try {
            val current = Settings.Global.getInt(context.contentResolver, Settings.Global.AIRPLANE_MODE_ON, 0)
            val newState = if (current == 1) 0 else 1
            
            var success = false
            try {
                success = Settings.Global.putInt(context.contentResolver, Settings.Global.AIRPLANE_MODE_ON, newState)
                if (success) {
                    val intent = Intent(Intent.ACTION_AIRPLANE_MODE_CHANGED).apply { putExtra("state", newState == 1) }
                    context.sendBroadcast(intent)
                }
            } catch (_: Exception) {}

            if (!success) {
                // Open Airplane mode settings/panel cleanly
                SettingsLauncher.startQuietly(context, Intent(Settings.ACTION_AIRPLANE_MODE_SETTINGS))
                result.success(null)
            } else {
                onStateChanged()
                result.success(newState == 1)
            }
        } catch (_: Exception) {
            SettingsLauncher.startQuietly(context, Intent(Settings.ACTION_AIRPLANE_MODE_SETTINGS))
            result.success(null)
        }
    }

    private fun toggleHotspot(result: MethodChannel.Result) {
        try {
            var toggled = false
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            try {
                val method = wifiManager.javaClass.getDeclaredMethod("isWifiApEnabled")
                val isEnabled = method.invoke(wifiManager) as? Boolean ?: false
                val setMethod = wifiManager.javaClass.getDeclaredMethod("setWifiApEnabled", null, Boolean::class.javaPrimitiveType)
                setMethod.invoke(wifiManager, null, !isEnabled)
                toggled = true
                onStateChanged()
                result.success(!isEnabled)
                return
            } catch (_: Exception) {}

            // In Android 11+, apps without TETHER_PRIVILEGED cannot silently toggle Wi-Fi Hotspot.
            // Launch Tethering Settings or Wireless settings cleanly.
            SettingsLauncher.startQuietly(
                context,
                Intent("android.settings.TETHER_SETTINGS").apply {
                    addCategory(Intent.CATEGORY_DEFAULT)
                }
            )
            result.success(null)
        } catch (_: Exception) {
            SettingsLauncher.startQuietly(context, Intent(Settings.ACTION_WIRELESS_SETTINGS))
            result.success(null)
        }
    }

    private fun toggleNightLight(result: MethodChannel.Result) {
        try {
            val current = Settings.Secure.getInt(context.contentResolver, "night_display_activated", 0)
            val target = if (current == 1) 0 else 1
            var success = false
            try {
                success = Settings.Secure.putInt(context.contentResolver, "night_display_activated", target)
            } catch (_: Exception) {}

            if (!success) {
                // Open display settings / night light settings
                SettingsLauncher.startQuietly(
                    context,
                    Intent("android.settings.NIGHT_DISPLAY_SETTINGS"),
                    Intent(Settings.ACTION_DISPLAY_SETTINGS)
                )
                result.success(null)
            } else {
                onStateChanged()
                result.success(target == 1)
            }
        } catch (_: Exception) {
            SettingsLauncher.startQuietly(context, Intent(Settings.ACTION_DISPLAY_SETTINGS))
            result.success(null)
        }
    }

    private fun toggleExtraDim(result: MethodChannel.Result) {
        try {
            val current = Settings.Secure.getInt(context.contentResolver, "reduce_bright_colors_activated", 0)
            val newState = if (current == 1) 0 else 1
            var success = false
            try {
                success = Settings.Secure.putInt(context.contentResolver, "reduce_bright_colors_activated", newState)
            } catch (_: Exception) {}

            if (!success) {
                SettingsLauncher.startQuietly(
                    context,
                    Intent("android.settings.REDUCE_BRIGHT_COLORS_SETTINGS"),
                    Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                )
                result.success(null)
            } else {
                onStateChanged()
                result.success(newState == 1)
            }
        } catch (_: Exception) {
            result.success(null)
        }
    }

    private fun toggleLocation(result: MethodChannel.Result) {
        try {
            val locManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
            val isEnabled = locManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
            val newMode = if (isEnabled) Settings.Secure.LOCATION_MODE_OFF else Settings.Secure.LOCATION_MODE_HIGH_ACCURACY
            var success = false
            try {
                success = Settings.Secure.putInt(context.contentResolver, Settings.Secure.LOCATION_MODE, newMode)
            } catch (_: Exception) {}

            if (!success) {
                SettingsLauncher.startQuietly(context, Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
                result.success(null)
            } else {
                onStateChanged()
                result.success(!isEnabled)
            }
        } catch (_: Exception) {
            SettingsLauncher.startQuietly(context, Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
            result.success(null)
        }
    }

    private fun toggleNfc(result: MethodChannel.Result) {
        try {
            val nfcManager = context.getSystemService(Context.NFC_SERVICE) as? android.nfc.NfcManager
            val adapter = nfcManager?.defaultAdapter
            val isEnabled = adapter?.isEnabled == true
            val target = if (isEnabled) 0 else 1
            Settings.Global.putInt(context.contentResolver, "nfc_on", target)
            onStateChanged()
            result.success(target == 1)
        } catch (_: Exception) {
            result.success(null)
        }
    }

    private fun toggleMobileData(result: MethodChannel.Result) {
        try {
            val telManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            val isEnabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) telManager.isDataEnabled else false
            val target = if (isEnabled) 0 else 1
            Settings.Global.putInt(context.contentResolver, "mobile_data", target)
            onStateChanged()
            result.success(target == 1)
        } catch (_: Exception) {
            result.success(null)
        }
    }

    private fun toggleDataSaver(result: MethodChannel.Result) {
        try {
            val current = Settings.Global.getInt(context.contentResolver, "data_saver_mode", 0)
            val target = if (current == 1) 0 else 1
            Settings.Global.putInt(context.contentResolver, "data_saver_mode", target)
            onStateChanged()
            result.success(target == 1)
        } catch (_: Exception) {
            result.success(null)
        }
    }

    private fun openQrScanner(result: MethodChannel.Result) {
        open(
            result,
            { Intent("android.media.action.STILL_IMAGE_CAMERA").apply { putExtra("android.intent.extra.CAMERA_OPEN_ONLY", true) } },
            { Intent("com.google.android.gms.vision.barcodedetection") },
            { Intent(android.provider.MediaStore.ACTION_IMAGE_CAPTURE) }
        )
    }

    private fun openCalculator(result: MethodChannel.Result) {
        open(
            result,
            { Intent().setAction(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_APP_CALCULATOR) },
            { Intent(Settings.ACTION_SETTINGS) }
        )
    }
}
