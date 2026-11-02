import 'package:flutter/services.dart';

class SystemHardwareService {
  static const MethodChannel _channel = MethodChannel('com.expressive_shade/hardware');

  static void Function(Map<String, dynamic> state)? onHardwareStateChanged;

  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onHardwareStateChanged') {
        final raw = call.arguments;
        if (raw is Map) {
          final typed = Map<String, dynamic>.from(raw);
          onHardwareStateChanged?.call(typed);
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
