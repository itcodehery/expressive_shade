import 'package:flutter/services.dart';

class SystemHardwareService {
  static const MethodChannel _channel = MethodChannel('com.expressive_shade/hardware');

  static Future<Map<String, dynamic>?> getInitialValues() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('getInitialValues');
      return res;
    } catch (_) {
      return null;
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

  static Future<void> openWifiSettings() async {
    try {
      await _channel.invokeMethod('openWifiSettings');
    } catch (_) {}
  }

  static Future<void> openBluetoothSettings() async {
    try {
      await _channel.invokeMethod('openBluetoothSettings');
    } catch (_) {}
  }

  static Future<bool?> toggleAutoRotate() async {
    try {
      final res = await _channel.invokeMethod<bool>('toggleAutoRotate');
      return res;
    } catch (_) {
      return null;
    }
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
