package com.example.expressive_shade

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Handles `com.expressive_shade/permissions`. */
class PermissionsChannelHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val pkgUri = { Uri.parse("package:${context.packageName}") }
        when (call.method) {
            "checkPermissions" -> result.success(
                mapOf(
                    "overlay" to isOverlayGranted(),
                    "accessibility" to isAccessibilityGranted(),
                    "notification" to isNotificationListenerGranted(),
                    "writeSettings" to isWriteSettingsGranted()
                )
            )
            "requestOverlayPermission" -> SettingsLauncher.startFirst(
                context, result,
                { Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, pkgUri()) },
                { Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION) }
            )
            "requestAccessibilityPermission" -> SettingsLauncher.startFirst(
                context, result,
                { Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS) },
                { Intent(Settings.ACTION_SETTINGS) }
            )
            "requestNotificationPermission" -> SettingsLauncher.startFirst(
                context, result,
                { Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS) },
                { Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS") }
            )
            "requestWriteSettingsPermission" -> SettingsLauncher.startFirst(
                context, result,
                { Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS, pkgUri()) },
                { Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS) }
            )
            "openAppDetailsSettings" -> SettingsLauncher.startFirst(
                context, result,
                { Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, pkgUri()) }
            )
            else -> result.notImplemented()
        }
    }

    private fun isOverlayGranted(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) Settings.canDrawOverlays(context) else true

    private fun isAccessibilityGranted(): Boolean {
        val enabledServices = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val expectedService = "${context.packageName}/${ExpressiveAccessibilityService::class.java.canonicalName}"
        val shortService = "${context.packageName}/.ExpressiveAccessibilityService"
        return enabledServices.contains(expectedService) || enabledServices.contains(shortService)
    }

    private fun isNotificationListenerGranted(): Boolean =
        NotificationManagerCompat.getEnabledListenerPackages(context).contains(context.packageName)

    private fun isWriteSettingsGranted(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) Settings.System.canWrite(context) else true
}
