import 'package:flutter/material.dart';

enum NetworkTileStyle {
  unified,
  separate,
}

enum TileCategory {
  connectivity,
  display,
  sound,
  utilities,
  privacy,
  accessibility;

  String get label {
    switch (this) {
      case TileCategory.connectivity:
        return 'Connectivity';
      case TileCategory.display:
        return 'Display';
      case TileCategory.sound:
        return 'Sound & Vibration';
      case TileCategory.utilities:
        return 'Controls & Utilities';
      case TileCategory.privacy:
        return 'Privacy & Security';
      case TileCategory.accessibility:
        return 'Accessibility';
    }
  }

  IconData get icon {
    switch (this) {
      case TileCategory.connectivity:
        return Icons.wifi_rounded;
      case TileCategory.display:
        return Icons.brightness_medium_rounded;
      case TileCategory.sound:
        return Icons.volume_up_rounded;
      case TileCategory.utilities:
        return Icons.tune_rounded;
      case TileCategory.privacy:
        return Icons.shield_rounded;
      case TileCategory.accessibility:
        return Icons.accessibility_new_rounded;
    }
  }
}

class QsTileModel {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isWide;
  final bool isActive;
  final bool hasDetails;
  final TileCategory category;

  const QsTileModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
    this.isWide = false,
    this.isActive = false,
    this.hasDetails = false,
    this.category = TileCategory.utilities,
  });

  QsTileModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    IconData? icon,
    bool? isWide,
    bool? isActive,
    bool? hasDetails,
    TileCategory? category,
  }) {
    return QsTileModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      isWide: isWide ?? this.isWide,
      isActive: isActive ?? this.isActive,
      hasDetails: hasDetails ?? this.hasDetails,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'isWide': isWide,
    'isActive': isActive,
    'hasDetails': hasDetails,
    'category': category.name,
  };

  factory QsTileModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final catalogTile = allAvailableTiles.firstWhere(
      (t) => t.id == id,
      orElse: () => defaultTiles.first,
    );
    return catalogTile.copyWith(
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      isWide: json['isWide'] as bool? ?? catalogTile.isWide,
      isActive: json['isActive'] as bool? ?? catalogTile.isActive,
      hasDetails: json['hasDetails'] as bool? ?? catalogTile.hasDetails,
    );
  }

  static List<QsTileModel> get defaultTiles => [
    const QsTileModel(
      id: 'wifi',
      title: 'Internet',
      subtitle: 'Wi-Fi',
      icon: Icons.wifi,
      isWide: true,
      isActive: false,
      hasDetails: true,
      category: TileCategory.connectivity,
    ),
    const QsTileModel(
      id: 'bluetooth',
      title: 'Bluetooth',
      subtitle: 'Off',
      icon: Icons.bluetooth,
      isWide: true,
      isActive: false,
      hasDetails: true,
      category: TileCategory.connectivity,
    ),
    const QsTileModel(
      id: 'dnd',
      title: 'Do Not Disturb',
      subtitle: 'Off',
      icon: Icons.do_not_disturb_on_rounded,
      isWide: true,
      isActive: false,
      hasDetails: false,
      category: TileCategory.sound,
    ),
    const QsTileModel(
      id: 'flashlight',
      title: 'Flashlight',
      subtitle: 'Off',
      icon: Icons.flashlight_on_rounded,
      isWide: true,
      isActive: false,
      hasDetails: false,
      category: TileCategory.utilities,
    ),
    const QsTileModel(
      id: 'autorotate',
      title: 'Auto-rotate',
      subtitle: 'On',
      icon: Icons.screen_rotation_rounded,
      isWide: false,
      isActive: true,
      category: TileCategory.display,
    ),
    const QsTileModel(
      id: 'airplane',
      title: 'Airplane mode',
      subtitle: 'Off',
      icon: Icons.airplanemode_active_rounded,
      isWide: false,
      isActive: false,
      category: TileCategory.connectivity,
    ),
    const QsTileModel(
      id: 'location',
      title: 'Location',
      subtitle: 'Off',
      icon: Icons.location_on_rounded,
      isWide: false,
      isActive: false,
      category: TileCategory.privacy,
    ),
    const QsTileModel(
      id: 'battery_saver',
      title: 'Battery Saver',
      subtitle: 'Off',
      icon: Icons.battery_saver_rounded,
      isWide: false,
      isActive: false,
      category: TileCategory.utilities,
    ),
    const QsTileModel(
      id: 'hotspot',
      title: 'Hotspot',
      subtitle: 'Off',
      icon: Icons.wifi_tethering_rounded,
      isWide: false,
      isActive: false,
      category: TileCategory.connectivity,
    ),
    const QsTileModel(
      id: 'night_light',
      title: 'Night Light',
      subtitle: 'Off',
      icon: Icons.nightlight_round,
      isWide: false,
      isActive: false,
      category: TileCategory.display,
    ),
    const QsTileModel(
      id: 'cast',
      title: 'Cast',
      subtitle: 'Off',
      icon: Icons.cast_rounded,
      isWide: false,
      isActive: false,
      category: TileCategory.connectivity,
    ),
    const QsTileModel(
      id: 'modes',
      title: 'Modes',
      subtitle: 'Normal',
      icon: Icons.remove_circle_outline_rounded,
      isWide: false,
      isActive: false,
      category: TileCategory.utilities,
    ),
  ];

  static List<QsTileModel> get allAvailableTiles => [
    // 1. Connectivity
    const QsTileModel(
      id: 'wifi',
      title: 'Internet',
      subtitle: 'Wi-Fi',
      icon: Icons.wifi,
      isWide: true,
      hasDetails: true,
      category: TileCategory.connectivity,
    ),
    const QsTileModel(
      id: 'mobile_data',
      title: 'Mobile Data',
      subtitle: 'Mobile',
      icon: Icons.signal_cellular_alt_rounded,
      isWide: true,
      category: TileCategory.connectivity,
    ),
    const QsTileModel(
      id: 'bluetooth',
      title: 'Bluetooth',
      subtitle: 'Off',
      icon: Icons.bluetooth,
      isWide: true,
      hasDetails: true,
      category: TileCategory.connectivity,
    ),
    const QsTileModel(
      id: 'airplane',
      title: 'Airplane mode',
      subtitle: 'Off',
      icon: Icons.airplanemode_active_rounded,
      category: TileCategory.connectivity,
    ),
    const QsTileModel(
      id: 'hotspot',
      title: 'Hotspot',
      subtitle: 'Off',
      icon: Icons.wifi_tethering_rounded,
      category: TileCategory.connectivity,
    ),
    const QsTileModel(
      id: 'cast',
      title: 'Cast',
      subtitle: 'Off',
      icon: Icons.cast_rounded,
      category: TileCategory.connectivity,
    ),
    const QsTileModel(
      id: 'data_saver',
      title: 'Data Saver',
      subtitle: 'Off',
      icon: Icons.data_saver_on_rounded,
      category: TileCategory.connectivity,
    ),
    const QsTileModel(
      id: 'vpn',
      title: 'VPN',
      subtitle: 'Disconnected',
      icon: Icons.vpn_key_rounded,
      category: TileCategory.connectivity,
    ),
    const QsTileModel(
      id: 'nearby_share',
      title: 'Quick Share',
      subtitle: 'Off',
      icon: Icons.share_rounded,
      category: TileCategory.connectivity,
    ),
    const QsTileModel(
      id: 'nfc',
      title: 'NFC',
      subtitle: 'Off',
      icon: Icons.nfc_rounded,
      category: TileCategory.connectivity,
    ),

    // 2. Display
    const QsTileModel(
      id: 'autorotate',
      title: 'Auto-rotate',
      subtitle: 'On',
      icon: Icons.screen_rotation_rounded,
      isActive: true,
      category: TileCategory.display,
    ),
    const QsTileModel(
      id: 'night_light',
      title: 'Night Light',
      subtitle: 'Off',
      icon: Icons.nightlight_round,
      category: TileCategory.display,
    ),
    const QsTileModel(
      id: 'dark_theme',
      title: 'Dark theme',
      subtitle: 'On',
      icon: Icons.dark_mode_rounded,
      isActive: true,
      category: TileCategory.display,
    ),
    const QsTileModel(
      id: 'extra_dim',
      title: 'Extra Dim',
      subtitle: 'Off',
      icon: Icons.wb_twilight_rounded,
      category: TileCategory.display,
    ),
    const QsTileModel(
      id: 'screen_timeout',
      title: 'Screen Timeout',
      subtitle: '30s',
      icon: Icons.hourglass_top_rounded,
      category: TileCategory.display,
    ),
    const QsTileModel(
      id: 'live_caption',
      title: 'Live Caption',
      subtitle: 'Off',
      icon: Icons.closed_caption_rounded,
      category: TileCategory.display,
    ),
    const QsTileModel(
      id: 'color_inversion',
      title: 'Invert colors',
      subtitle: 'Off',
      icon: Icons.invert_colors_rounded,
      category: TileCategory.display,
    ),

    // 3. Sound & Vibration
    const QsTileModel(
      id: 'dnd',
      title: 'Do Not Disturb',
      subtitle: 'Off',
      icon: Icons.do_not_disturb_on_rounded,
      isWide: true,
      category: TileCategory.sound,
    ),
    const QsTileModel(
      id: 'sound_mode',
      title: 'Sound Profile',
      subtitle: 'Ring',
      icon: Icons.volume_up_rounded,
      category: TileCategory.sound,
    ),
    const QsTileModel(
      id: 'spatial_audio',
      title: 'Spatial Audio',
      subtitle: 'Off',
      icon: Icons.surround_sound_rounded,
      category: TileCategory.sound,
    ),
    const QsTileModel(
      id: 'live_transcribe',
      title: 'Live Transcribe',
      subtitle: 'Off',
      icon: Icons.hearing_rounded,
      category: TileCategory.sound,
    ),
    const QsTileModel(
      id: 'mic_access',
      title: 'Mic Access',
      subtitle: 'Available',
      icon: Icons.mic_rounded,
      isActive: true,
      category: TileCategory.sound,
    ),

    // 4. Controls & Utilities
    const QsTileModel(
      id: 'flashlight',
      title: 'Flashlight',
      subtitle: 'Off',
      icon: Icons.flashlight_on_rounded,
      isWide: true,
      category: TileCategory.utilities,
    ),
    const QsTileModel(
      id: 'battery_saver',
      title: 'Battery Saver',
      subtitle: 'Off',
      icon: Icons.battery_saver_rounded,
      category: TileCategory.utilities,
    ),
    const QsTileModel(
      id: 'modes',
      title: 'Modes',
      subtitle: 'Normal',
      icon: Icons.remove_circle_outline_rounded,
      category: TileCategory.utilities,
    ),
    const QsTileModel(
      id: 'screen_record',
      title: 'Screen Record',
      subtitle: 'Record',
      icon: Icons.videocam_rounded,
      category: TileCategory.utilities,
    ),
    const QsTileModel(
      id: 'qr_scanner',
      title: 'QR Scanner',
      subtitle: 'Scan',
      icon: Icons.qr_code_scanner_rounded,
      category: TileCategory.utilities,
    ),
    const QsTileModel(
      id: 'calculator',
      title: 'Calculator',
      subtitle: 'Calc',
      icon: Icons.calculate_rounded,
      category: TileCategory.utilities,
    ),
    const QsTileModel(
      id: 'camera_access',
      title: 'Camera Access',
      subtitle: 'Available',
      icon: Icons.camera_alt_rounded,
      isActive: true,
      category: TileCategory.utilities,
    ),
    const QsTileModel(
      id: 'alarm',
      title: 'Alarm',
      subtitle: 'Off',
      icon: Icons.alarm_rounded,
      category: TileCategory.utilities,
    ),
    const QsTileModel(
      id: 'timer',
      title: 'Timer',
      subtitle: 'Off',
      icon: Icons.timer_rounded,
      category: TileCategory.utilities,
    ),
    const QsTileModel(
      id: 'stopwatch',
      title: 'Stopwatch',
      subtitle: 'Off',
      icon: Icons.timer_outlined,
      category: TileCategory.utilities,
    ),

    // 5. Privacy & Security
    const QsTileModel(
      id: 'location',
      title: 'Location',
      subtitle: 'Off',
      icon: Icons.location_on_rounded,
      category: TileCategory.privacy,
    ),
    const QsTileModel(
      id: 'camera_privacy',
      title: 'Camera Block',
      subtitle: 'Unblocked',
      icon: Icons.no_photography_rounded,
      category: TileCategory.privacy,
    ),
    const QsTileModel(
      id: 'mic_privacy',
      title: 'Mic Block',
      subtitle: 'Unblocked',
      icon: Icons.mic_off_rounded,
      category: TileCategory.privacy,
    ),
    const QsTileModel(
      id: 'sensitive_notifs',
      title: 'Sensitive Notifs',
      subtitle: 'Hidden',
      icon: Icons.visibility_off_rounded,
      category: TileCategory.privacy,
    ),
    const QsTileModel(
      id: 'device_controls',
      title: 'Device Controls',
      subtitle: 'Home',
      icon: Icons.home_rounded,
      category: TileCategory.privacy,
    ),

    // 6. Accessibility
    const QsTileModel(
      id: 'one_handed',
      title: 'One-Handed',
      subtitle: 'Off',
      icon: Icons.pan_tool_alt_rounded,
      category: TileCategory.accessibility,
    ),
    const QsTileModel(
      id: 'talkback',
      title: 'TalkBack',
      subtitle: 'Off',
      icon: Icons.record_voice_over_rounded,
      category: TileCategory.accessibility,
    ),
    const QsTileModel(
      id: 'high_contrast',
      title: 'High Contrast',
      subtitle: 'Off',
      icon: Icons.contrast_rounded,
      category: TileCategory.accessibility,
    ),
    const QsTileModel(
      id: 'magnification',
      title: 'Magnification',
      subtitle: 'Off',
      icon: Icons.zoom_in_rounded,
      category: TileCategory.accessibility,
    ),
  ];
}
