import 'package:flutter/services.dart';

class SystemHardwareService {
  static const MethodChannel _channel = MethodChannel('com.expressive_shade/hardware');

  static final Set<void Function(Map<String, dynamic> state)> _listeners = {};

  static set onHardwareStateChanged(void Function(Map<String, dynamic> state)? callback) {
    if (callback != null) {
      _listeners.add(callback);
    }
  }

  static void addListener(void Function(Map<String, dynamic> state) callback) {
    _listeners.add(callback);
  }

  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onHardwareStateChanged') {
        final raw = call.arguments;
        if (raw is Map) {
          final typed = Map<String, dynamic>.from(raw);
          for (final l in Set<void Function(Map<String, dynamic> state)>.from(_listeners)) {
            try {
              l(typed);
            } catch (_) {}
          }
        }
      }
    });
  }

  static Future<Map<String, dynamic>?> getSystemHardwareState() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('getSystemHardwareState');
      return res;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> toggleWifi() async {
    try {
      final res = await _channel.invokeMethod<bool>('toggleWifi');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> toggleBluetooth() async {
    try {
      final res = await _channel.invokeMethod<bool>('toggleBluetooth');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setFlashlight(bool enabled) async {
    try {
      final res = await _channel.invokeMethod<bool>('setFlashlight', {'enabled': enabled});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setBrightness(double value) async {
    try {
      final res = await _channel.invokeMethod<bool>('setBrightness', {'value': value});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setVolume(double value) async {
    try {
      final res = await _channel.invokeMethod<bool>('setVolume', {'value': value});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setRingerMode(int mode) async {
    try {
      final res = await _channel.invokeMethod<bool>('setRingerMode', {'mode': mode});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool?> toggleAutoRotate() async {
    try {
      final res = await _channel.invokeMethod<bool>('toggleAutoRotate');
      return res;
    } catch (_) {
      return null;
    }
  }

  static Future<bool?> toggleDnd() async {
    try {
      final res = await _channel.invokeMethod<bool>('toggleDnd');
      return res;
    } catch (_) {
      return null;
    }
  }

  static Future<bool?> setZenMode(String mode) async {
    try {
      final res = await _channel.invokeMethod<bool>('setZenMode', {'mode': mode});
      return res;
    } catch (_) {
      return null;
    }
  }

  static Future<void> openModesSettings() async {
    try {
      await _channel.invokeMethod('openModesSettings');
    } catch (_) {}
  }

  static Future<bool?> toggleBatterySaver() async {
    try {
      return await _channel.invokeMethod<bool>('toggleBatterySaver');
    } catch (_) {
      return null;
    }
  }

  static Future<bool?> toggleAirplane() async {
    try {
      return await _channel.invokeMethod<bool>('toggleAirplane');
    } catch (_) {
      return null;
    }
  }

  static Future<bool?> toggleHotspot() async {
    try {
      return await _channel.invokeMethod<bool>('toggleHotspot');
    } catch (_) {
      return null;
    }
  }

  static Future<void> triggerCast() async {
    try {
      await _channel.invokeMethod('triggerCast');
    } catch (_) {}
  }

  static Future<bool?> toggleDataSaver() async {
    try {
      return await _channel.invokeMethod<bool>('toggleDataSaver');
    } catch (_) {
      return null;
    }
  }

  static Future<bool?> toggleExtraDim() async {
    try {
      return await _channel.invokeMethod<bool>('toggleExtraDim');
    } catch (_) {
      return null;
    }
  }

  static Future<bool?> toggleLocation() async {
    try {
      return await _channel.invokeMethod<bool>('toggleLocation');
    } catch (_) {
      return null;
    }
  }

  static Future<bool?> toggleNightLight() async {
    try {
      return await _channel.invokeMethod<bool>('toggleNightLight');
    } catch (_) {
      return null;
    }
  }

  static Future<bool?> toggleNfc() async {
    try {
      return await _channel.invokeMethod<bool>('toggleNfc');
    } catch (_) {
      return null;
    }
  }

  static Future<bool?> toggleMobileData() async {
    try {
      return await _channel.invokeMethod<bool>('toggleMobileData');
    } catch (_) {
      return null;
    }
  }

  static Future<void> openQrScanner() async {
    try {
      await _channel.invokeMethod('openQrScanner');
    } catch (_) {}
  }

  static Future<void> openNfcSettings() async {
    try {
      await _channel.invokeMethod('openNfcSettings');
    } catch (_) {}
  }

  static Future<void> openCalculator() async {
    try {
      await _channel.invokeMethod('openCalculator');
    } catch (_) {}
  }

  static Future<void> openAlarm() async {
    try {
      await _channel.invokeMethod('openAlarm');
    } catch (_) {}
  }

  static Future<void> openAirplaneSettings() async {
    try {
      await _channel.invokeMethod('openAirplaneSettings');
    } catch (_) {}
  }

  static Future<void> openLocationSettings() async {
    try {
      await _channel.invokeMethod('openLocationSettings');
    } catch (_) {}
  }

  static Future<void> openBatterySaverSettings() async {
    try {
      await _channel.invokeMethod('openBatterySaverSettings');
    } catch (_) {}
  }

  static Future<void> openHotspotSettings() async {
    try {
      await _channel.invokeMethod('openHotspotSettings');
    } catch (_) {}
  }

  static Future<void> openNightLightSettings() async {
    try {
      await _channel.invokeMethod('openNightLightSettings');
    } catch (_) {}
  }

  static Future<void> openWifiSettings() async {
    try {
      await _channel.invokeMethod('openWifiSettings');
    } catch (_) {}
  }

  static Future<void> openMobileDataSettings() async {
    try {
      await _channel.invokeMethod('openMobileDataSettings');
    } catch (_) {}
  }

  static Future<void> openBluetoothSettings() async {
    try {
      await _channel.invokeMethod('openBluetoothSettings');
    } catch (_) {}
  }

  static Future<void> openSettings() async {
    try {
      await _channel.invokeMethod('openSettings');
    } catch (_) {}
  }

  static Future<void> openShadeApp() async {
    try {
      await _channel.invokeMethod('openShadeApp');
    } catch (_) {}
  }

  static Future<void> openNotificationHistory() async {
    try {
      await _channel.invokeMethod('openNotificationHistory');
    } catch (_) {}
  }

  static Future<void> openAppNotificationSettings([String? packageName]) async {
    try {
      await _channel.invokeMethod('openAppNotificationSettings', {
        if (packageName != null && packageName.isNotEmpty) 'packageName': packageName,
      });
    } catch (_) {}
  }

  static Future<bool> triggerPowerDialog() async {
    try {
      final res = await _channel.invokeMethod<bool>('triggerPowerDialog');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> triggerLockdown() async {
    try {
      final res = await _channel.invokeMethod<bool>('triggerLockdown');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> triggerScreenshot() async {
    try {
      final res = await _channel.invokeMethod<bool>('triggerScreenshot');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> triggerEmergencyCall() async {
    try {
      final res = await _channel.invokeMethod<bool>('triggerEmergencyCall');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
