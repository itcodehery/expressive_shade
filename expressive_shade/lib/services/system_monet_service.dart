import 'package:flutter/services.dart';

class SystemMonetService {
  static const MethodChannel _channel = MethodChannel('com.expressive_shade/monet');

  static Future<Color?> getSystemAccentColor() async {
    try {
      final int? colorInt = await _channel.invokeMethod<int>('getSystemAccentColor');
      if (colorInt != null) {
        return Color(colorInt);
      }
    } catch (_) {
      // Platform channel not available or not on Android 12+
    }
    return null;
  }
}
