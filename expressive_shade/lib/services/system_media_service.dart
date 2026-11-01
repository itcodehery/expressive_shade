import 'package:flutter/services.dart';

class SystemMediaInfo {
  final String title;
  final String artist;
  final String appName;
  final bool isPlaying;
  final double progress;

  const SystemMediaInfo({
    required this.title,
    required this.artist,
    required this.appName,
    required this.isPlaying,
    required this.progress,
  });
}

class SystemMediaService {
  static const MethodChannel _channel = MethodChannel('com.expressive_shade/media');
  static VoidCallback? _onMediaChanged;

  static void initialize(VoidCallback onUpdate) {
    _onMediaChanged = onUpdate;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onMediaChanged') {
        _onMediaChanged?.call();
      }
    });
  }

  static Future<SystemMediaInfo?> getMediaState() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>('getMediaState');
      if (raw == null) return null;

      return SystemMediaInfo(
        title: raw['title']?.toString() ?? 'Unknown Title',
        artist: raw['artist']?.toString() ?? 'Unknown Artist',
        appName: raw['appName']?.toString() ?? 'Music',
        isPlaying: raw['isPlaying'] == true,
        progress: (raw['progress'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> controlMedia(String action) async {
    try {
      await _channel.invokeMethod('controlMedia', {'action': action});
    } catch (_) {}
  }
}
