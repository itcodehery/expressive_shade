import 'package:flutter/material.dart';

enum NetworkTileStyle {
  unified,
  separate,
}

class QsTileModel {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isWide;
  final bool isActive;
  final bool hasDetails;

  const QsTileModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
    this.isWide = false,
    this.isActive = false,
    this.hasDetails = false,
  });

  QsTileModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    IconData? icon,
    bool? isWide,
    bool? isActive,
    bool? hasDetails,
  }) {
    return QsTileModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      isWide: isWide ?? this.isWide,
      isActive: isActive ?? this.isActive,
      hasDetails: hasDetails ?? this.hasDetails,
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
    ),
    const QsTileModel(
      id: 'bluetooth',
      title: 'Bluetooth',
      subtitle: 'Off',
      icon: Icons.bluetooth,
      isWide: true,
      isActive: false,
      hasDetails: true,
    ),
    const QsTileModel(
      id: 'dnd',
      title: 'Do Not Disturb',
      subtitle: 'Off',
      icon: Icons.do_not_disturb_on_rounded,
      isWide: true,
      isActive: false,
      hasDetails: false,
    ),
    const QsTileModel(
      id: 'flashlight',
      title: 'Flashlight',
      subtitle: 'Off',
      icon: Icons.flashlight_on_rounded,
      isWide: true,
      isActive: false,
      hasDetails: false,
    ),
    const QsTileModel(
      id: 'autorotate',
      title: 'Auto-rotate',
      subtitle: 'On',
      icon: Icons.screen_rotation_rounded,
      isWide: false,
      isActive: true,
    ),
    const QsTileModel(
      id: 'airplane',
      title: 'Airplane mode',
      subtitle: 'Off',
      icon: Icons.airplanemode_active_rounded,
      isWide: false,
      isActive: false,
    ),
    const QsTileModel(
      id: 'location',
      title: 'Location',
      subtitle: 'Off',
      icon: Icons.location_on_rounded,
      isWide: false,
      isActive: false,
    ),
    const QsTileModel(
      id: 'battery_saver',
      title: 'Battery Saver',
      subtitle: 'Off',
      icon: Icons.battery_saver_rounded,
      isWide: false,
      isActive: false,
    ),
    const QsTileModel(
      id: 'hotspot',
      title: 'Hotspot',
      subtitle: 'Off',
      icon: Icons.wifi_tethering_rounded,
      isWide: false,
      isActive: false,
    ),
    const QsTileModel(
      id: 'night_light',
      title: 'Night Light',
      subtitle: 'Off',
      icon: Icons.nightlight_round,
      isWide: false,
      isActive: false,
    ),
    const QsTileModel(
      id: 'cast',
      title: 'Screen Cast',
      subtitle: 'Off',
      icon: Icons.cast_rounded,
      isWide: false,
      isActive: false,
    ),
    const QsTileModel(
      id: 'alarm',
      title: 'Alarm',
      subtitle: 'Off',
      icon: Icons.alarm_rounded,
      isWide: false,
      isActive: false,
    ),
  ];
}
