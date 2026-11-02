import 'package:flutter/services.dart';

class SystemSettingsService {
  static const MethodChannel _channel = MethodChannel('com.expressive_shade/settings');

  static void initialize(void Function(Map<String, dynamic> settings) onSettingsChanged) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSettingsChanged') {
        final args = call.arguments;
        if (args is Map) {
          onSettingsChanged(Map<String, dynamic>.from(args));
        }
      }
    });
  }

  static Future<Map<String, dynamic>?> getSettings() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('getSettings');
      return res;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> saveSettings(Map<String, dynamic> settings) async {
    try {
      final res = await _channel.invokeMethod<bool>('saveSettings', settings);
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
