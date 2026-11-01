package com.example.expressive_shade

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
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

    private var activeNotificationsChannel: MethodChannel? = null
    private var activeMediaChannel: MethodChannel? = null

    fun registerChannels(activity: Activity, flutterEngine: FlutterEngine) {
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // 1. Monet Accent Channel
        MethodChannel(messenger, MONET_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSystemAccentColor") {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    try {
                        val accentColor = activity.resources.getColor(android.R.color.system_accent1_500, activity.theme)
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
                        "overlay" to isOverlayGranted(activity),
                        "accessibility" to isAccessibilityGranted(activity),
                        "notification" to isNotificationListenerGranted(activity),
                        "writeSettings" to isWriteSettingsGranted(activity)
                    )
                    result.success(status)
                }
                "requestOverlayPermission" -> {
                    try {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:${activity.packageName}")
                        ).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
                        activity.startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            activity.startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK })
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
                        activity.startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            activity.startActivity(Intent(Settings.ACTION_SETTINGS).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK })
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
                        activity.startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            activity.startActivity(Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS").apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK })
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
                            Uri.parse("package:${activity.packageName}")
                        ).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
                        activity.startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            activity.startActivity(Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK })
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
                            Uri.parse("package:${activity.packageName}")
                        ).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
                        activity.startActivity(intent)
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
                    val intent = Intent(activity, ExpressiveOverlayService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        activity.startForegroundService(intent)
                    } else {
                        activity.startService(intent)
                    }
                    ExpressiveAccessibilityService.isEnabled = true
                    ExpressiveAccessibilityService.instance?.setupTopGestureTrigger()
                    result.success(true)
                }
                "stopOverlayService" -> {
                    val intent = Intent(activity, ExpressiveOverlayService::class.java)
                    activity.stopService(intent)
                    ExpressiveAccessibilityService.isEnabled = false
                    ExpressiveAccessibilityService.instance?.removeTopGestureTrigger()
                    result.success(true)
                }
                "isServiceRunning" -> {
                    result.success(ExpressiveOverlayService.isRunning)
                }
                else -> result.notImplemented()
            }
        }

        // 4. Hardware Controls Channel
        MethodChannel(messenger, HARDWARE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialValues" -> {
                    try {
                        val audioManager = activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        val maxVol = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).toDouble()
                        val curVol = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble()
                        val volumeRatio = if (maxVol > 0) curVol / maxVol else 0.5

                        val brightnessInt = Settings.System.getInt(activity.contentResolver, Settings.System.SCREEN_BRIGHTNESS, 128)
                        val brightnessRatio = brightnessInt.toDouble() / 255.0

                        val autoRotateInt = Settings.System.getInt(activity.contentResolver, Settings.System.ACCELEROMETER_ROTATION, 1)

                        result.success(
                            mapOf(
                                "brightness" to brightnessRatio,
                                "volume" to volumeRatio,
                                "autoRotate" to (autoRotateInt == 1)
                            )
                        )
                    } catch (_: Exception) {
                        result.success(
                            mapOf(
                                "brightness" to 0.5,
                                "volume" to 0.5,
                                "autoRotate" to true
                            )
                        )
                    }
                }
                "setFlashlight" -> {
                    try {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        val cameraManager = activity.getSystemService(Context.CAMERA_SERVICE) as CameraManager
                        val cameraId = cameraManager.cameraIdList.firstOrNull()
                        if (cameraId != null) {
                            cameraManager.setTorchMode(cameraId, enabled)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
                "setBrightness" -> {
                    try {
                        val value = call.argument<Double>("value") ?: 0.5
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && Settings.System.canWrite(activity)) {
                            val brightnessInt = (value * 255).toInt().coerceIn(0, 255)
                            Settings.System.putInt(activity.contentResolver, Settings.System.SCREEN_BRIGHTNESS, brightnessInt)
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
                        val audioManager = activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        val maxVol = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                        val targetVol = (value * maxVol).toInt().coerceIn(0, maxVol)
                        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, targetVol, 0)
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
                "openWifiSettings" -> {
                    try {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            Intent(Settings.Panel.ACTION_INTERNET_CONNECTIVITY)
                        } else {
                            Intent(Settings.ACTION_WIFI_SETTINGS)
                        }.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
                        activity.startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            activity.startActivity(Intent(Settings.ACTION_WIFI_SETTINGS).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK })
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
                        activity.startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            activity.startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK })
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("ERROR", e2.message, null)
                        }
                    }
                }
                "toggleAutoRotate" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && Settings.System.canWrite(activity)) {
                            val current = Settings.System.getInt(activity.contentResolver, Settings.System.ACCELEROMETER_ROTATION, 1)
                            val newSetting = if (current == 1) 0 else 1
                            Settings.System.putInt(activity.contentResolver, Settings.System.ACCELEROMETER_ROTATION, newSetting)
                            result.success(newSetting == 1)
                        } else {
                            result.success(null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
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
                        activity.startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 5. Notifications Channel
        activeNotificationsChannel = MethodChannel(messenger, NOTIFICATIONS_CHANNEL).apply {
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

        // 6. Media Channel
        activeMediaChannel = MethodChannel(messenger, MEDIA_CHANNEL).apply {
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

        // Connect listener callbacks
        ExpressiveNotificationListenerService.onNotificationsChangedListener = {
            activity.runOnUiThread {
                activeNotificationsChannel?.invokeMethod("onNotificationsChanged", null)
            }
        }

        ExpressiveNotificationListenerService.onMediaChangedListener = {
            activity.runOnUiThread {
                activeMediaChannel?.invokeMethod("onMediaChanged", null)
            }
        }
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
