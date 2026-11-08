package com.example.expressive_shade

import android.app.NotificationManager
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.location.LocationManager
import android.media.AudioManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.telephony.TelephonyManager

/** Reads the current hardware/system state exposed to the Quick Settings tiles. */
object HardwareState {
    /** Tracked via CameraManager.TorchCallback (there is no synchronous getter). */
    @Volatile
    var isTorchOn = false

    fun read(context: Context): Map<String, Any?> {
        val appContext = context.applicationContext

        // 1. Wi-Fi
        var isWifiEnabled = false
        var isWifiConnected = false
        var wifiSsid = ""
        try {
            val wifiManager = appContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            isWifiEnabled = wifiManager.isWifiEnabled

            val connManager = appContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = connManager.activeNetwork
            val capabilities = connManager.getNetworkCapabilities(network)
            isWifiConnected = capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true

            if (isWifiConnected) {
                val wifiInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    capabilities?.transportInfo as? WifiInfo ?: wifiManager.connectionInfo
                } else {
                    wifiManager.connectionInfo
                }
                val rawSsid = wifiInfo?.ssid?.replace("\"", "") ?: ""
                wifiSsid = if (rawSsid.isNotEmpty() && rawSsid != "<unknown ssid>") rawSsid else ""
            }
        } catch (_: Exception) {}

        // 1b. Mobile Data
        var isMobileDataEnabled = false
        var isMobileDataConnected = false
        try {
            val telManager = appContext.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            isMobileDataEnabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                telManager.isDataEnabled
            } else {
                Settings.Global.getInt(appContext.contentResolver, "mobile_data", 0) == 1
            }
            val connManager = appContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = connManager.activeNetwork
            val capabilities = connManager.getNetworkCapabilities(network)
            isMobileDataConnected = capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true
        } catch (_: Exception) {}

        // 1c. Hotspot
        var isHotspot = false
        try {
            val wifiManager = appContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val method = wifiManager.javaClass.getDeclaredMethod("isWifiApEnabled")
            isHotspot = method.invoke(wifiManager) as? Boolean ?: false
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
        var ringerMode = AudioManager.RINGER_MODE_NORMAL
        var brightnessRatio = 0.5
        var autoRotate = true
        try {
            val audioManager = appContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val maxVol = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).toDouble()
            val curVol = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble()
            volumeRatio = if (maxVol > 0) curVol / maxVol else 0.5
            ringerMode = audioManager.ringerMode.coerceIn(0, 2)

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

        // 10. Night Light, NFC, Extra Dim, Data Saver
        var isNightLight = false
        var isNfc = false
        var isExtraDim = false
        var isDataSaver = false
        try {
            isNightLight = Settings.Secure.getInt(appContext.contentResolver, "night_display_activated", 0) == 1
            isExtraDim = Settings.Secure.getInt(appContext.contentResolver, "reduce_bright_colors_activated", 0) == 1
            isDataSaver = Settings.Global.getInt(appContext.contentResolver, "data_saver_mode", 0) == 1
            val nfcManager = appContext.getSystemService(Context.NFC_SERVICE) as? android.nfc.NfcManager
            isNfc = nfcManager?.defaultAdapter?.isEnabled == true
        } catch (_: Exception) {}

        return mapOf(
            "wifi" to mapOf(
                "enabled" to isWifiEnabled,
                "connected" to isWifiConnected,
                "ssid" to wifiSsid
            ),
            "mobileData" to mapOf(
                "enabled" to isMobileDataEnabled,
                "connected" to isMobileDataConnected
            ),
            "hotspot" to isHotspot,
            "bluetooth" to mapOf(
                "enabled" to isBtEnabled,
                "connected" to isBtConnected,
                "name" to btDeviceName
            ),
            "flashlight" to isTorchOn,
            "brightness" to brightnessRatio,
            "volume" to volumeRatio,
            "ringerMode" to ringerMode,
            "autoRotate" to autoRotate,
            "dnd" to isDnd,
            "airplane" to isAirplane,
            "location" to isLocation,
            "batterySaver" to isBatterySaver,
            "nightLight" to isNightLight,
            "extraDim" to isExtraDim,
            "dataSaver" to isDataSaver,
            "nfc" to isNfc,
            "battery" to mapOf(
                "level" to batteryLevel,
                "isCharging" to isCharging
            ),
            "carrier" to carrierName
        )
    }
}
