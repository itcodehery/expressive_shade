import 'package:flutter/services.dart';

class InstalledAppInfo {
  final String packageName;
  final String appName;

  const InstalledAppInfo({
    required this.packageName,
    required this.appName,
  });

  factory InstalledAppInfo.fromMap(Map<String, dynamic> map) {
    return InstalledAppInfo(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
    );
  }
}

class SystemAppsService {
  static const MethodChannel _appsChannel = MethodChannel('com.expressive_shade/apps');
  static const MethodChannel _notifChannel = MethodChannel('com.expressive_shade/notifications');
  static const MethodChannel _serviceChannel = MethodChannel('com.expressive_shade/service');

  static final Map<String, Uint8List> _iconCache = {};

  /// Fallback installed apps list for widget tests or non-Android runtimes.
  static const List<InstalledAppInfo> fallbackApps = [
    InstalledAppInfo(packageName: 'com.google.android.dialer', appName: 'Phone'),
    InstalledAppInfo(packageName: 'com.google.android.apps.messaging', appName: 'Messages'),
    InstalledAppInfo(packageName: 'com.android.chrome', appName: 'Chrome'),
    InstalledAppInfo(packageName: 'com.google.android.GoogleCamera', appName: 'Camera'),
    InstalledAppInfo(packageName: 'com.google.android.apps.photos', appName: 'Photos'),
    InstalledAppInfo(packageName: 'com.spotify.music', appName: 'Spotify'),
    InstalledAppInfo(packageName: 'com.google.android.deskclock', appName: 'Clock'),
    InstalledAppInfo(packageName: 'com.android.settings', appName: 'Settings'),
  ];

  static Uint8List? _convertBytes(dynamic raw) {
    if (raw == null) return null;
    if (raw is Uint8List) return raw;
    if (raw is List) {
      try {
        return Uint8List.fromList(raw.cast<int>());
      } catch (_) {}
    }
    return null;
  }

  /// Queries all launchable installed user applications.
  static Future<List<InstalledAppInfo>> getInstalledApps() async {
    // 1. Try apps channel
    try {
      final List<dynamic>? res = await _appsChannel.invokeListMethod('getInstalledApps');
      if (res != null && res.isNotEmpty) {
        return res
            .whereType<Map>()
            .map((m) => InstalledAppInfo.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}

    // 2. Try service channel
    try {
      final List<dynamic>? res = await _serviceChannel.invokeListMethod('getInstalledApps');
      if (res != null && res.isNotEmpty) {
        return res
            .whereType<Map>()
            .map((m) => InstalledAppInfo.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}

    return fallbackApps;
  }

  /// Retrieves the PNG icon byte array for an installed package.
  static Future<Uint8List?> getAppIcon(String packageName) async {
    if (_iconCache.containsKey(packageName)) {
      return _iconCache[packageName];
    }

    // 1. Try apps channel
    try {
      final dynamic raw = await _appsChannel.invokeMethod<dynamic>(
        'getAppIcon',
        {'packageName': packageName},
      );
      final bytes = _convertBytes(raw);
      if (bytes != null && bytes.isNotEmpty) {
        _iconCache[packageName] = bytes;
        return bytes;
      }
    } catch (_) {}

    // 2. Try notifications channel (has existing app icon cache in listener service)
    try {
      final dynamic raw = await _notifChannel.invokeMethod<dynamic>(
        'getAppIcon',
        {'packageName': packageName},
      );
      final bytes = _convertBytes(raw);
      if (bytes != null && bytes.isNotEmpty) {
        _iconCache[packageName] = bytes;
        return bytes;
      }
    } catch (_) {}

    // 3. Try service channel
    try {
      final dynamic raw = await _serviceChannel.invokeMethod<dynamic>(
        'getAppIcon',
        {'packageName': packageName},
      );
      final bytes = _convertBytes(raw);
      if (bytes != null && bytes.isNotEmpty) {
        _iconCache[packageName] = bytes;
        return bytes;
      }
    } catch (_) {}

    return null;
  }

  /// Launches an application by package name.
  static Future<bool> launchApp(String packageName) async {
    try {
      final bool? res = await _appsChannel.invokeMethod<bool>(
        'launchApp',
        {'packageName': packageName},
      );
      if (res == true) return true;
    } catch (_) {}

    try {
      final bool? res = await _serviceChannel.invokeMethod<bool>(
        'launchApp',
        {'packageName': packageName},
      );
      if (res == true) return true;
    } catch (_) {}

    return false;
  }
}
