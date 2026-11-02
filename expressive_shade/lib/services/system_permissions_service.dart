import 'package:flutter/services.dart';

class SystemPermissionsService {
  static const MethodChannel _channel = MethodChannel('com.expressive_shade/permissions');
  static const MethodChannel _serviceChannel = MethodChannel('com.expressive_shade/service');

  static Future<Map<String, bool>> checkPermissions() async {
    try {
      final res = await _channel.invokeMapMethod<String, bool>('checkPermissions');
      if (res != null) {
        return res;
      }
    } catch (_) {}
    return {
      'overlay': false,
      'accessibility': false,
      'notification': false,
      'writeSettings': false,
    };
  }

  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (_) {}
  }

  static Future<void> requestAccessibilityPermission() async {
    try {
      await _channel.invokeMethod('requestAccessibilityPermission');
    } catch (_) {}
  }

  static Future<void> requestNotificationPermission() async {
    try {
      await _channel.invokeMethod('requestNotificationPermission');
    } catch (_) {}
  }

  static Future<void> requestWriteSettingsPermission() async {
    try {
      await _channel.invokeMethod('requestWriteSettingsPermission');
    } catch (_) {}
  }

  static Future<void> openAppDetailsSettings() async {
    try {
      await _channel.invokeMethod('openAppDetailsSettings');
    } catch (_) {}
  }

  static Future<bool> startOverlayService() async {
    try {
      final res = await _serviceChannel.invokeMethod<bool>('startOverlayService');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> stopOverlayService() async {
    try {
      final res = await _serviceChannel.invokeMethod<bool>('stopOverlayService');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isServiceRunning() async {
    try {
      final res = await _serviceChannel.invokeMethod<bool>('isServiceRunning');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> deployCustomShade([String target = 'quick_settings']) async {
    try {
      await _serviceChannel.invokeMethod('deployCustomShade', {'target': target});
    } catch (_) {}
  }
}
