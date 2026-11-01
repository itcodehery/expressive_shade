import 'package:flutter/material.dart';

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
      subtitle: 'Google Fi 5G',
      icon: Icons.wifi,
      isWide: true,
      isActive: true,
      hasDetails: true,
    ),
    const QsTileModel(
      id: 'bluetooth',
      title: 'Bluetooth',
      subtitle: 'Pixel Buds Pro',
      icon: Icons.bluetooth,
      isWide: true,
      isActive: true,
      hasDetails: true,
    ),
    const QsTileModel(
      id: 'modes',
      title: 'Modes',
      subtitle: 'Focus Mode',
      icon: Icons.do_not_disturb_on_total_silence,
      isWide: true,
      isActive: false,
      hasDetails: true,
    ),
    const QsTileModel(
      id: 'quick_share',
      title: 'Quick Share',
      subtitle: 'Contacts Only',
      icon: Icons.share_rounded,
      isWide: true,
      isActive: true,
      hasDetails: false,
    ),
    const QsTileModel(
      id: 'flashlight',
      title: 'Flashlight',
      icon: Icons.flashlight_on_rounded,
      isWide: false,
      isActive: false,
    ),
    const QsTileModel(
      id: 'airplane',
      title: 'Airplane mode',
      icon: Icons.airplanemode_active_rounded,
      isWide: false,
      isActive: false,
    ),
    const QsTileModel(
      id: 'rotate',
      title: 'Auto-rotate',
      icon: Icons.screen_rotation_rounded,
      isWide: false,
      isActive: true,
    ),
    const QsTileModel(
      id: 'wallet',
      title: 'Wallet',
      icon: Icons.wallet_rounded,
      isWide: false,
      isActive: false,
    ),
    const QsTileModel(
      id: 'home',
      title: 'Device control',
      icon: Icons.home_rounded,
      isWide: false,
      isActive: true,
    ),
    const QsTileModel(
      id: 'alarm',
      title: 'Alarm',
      icon: Icons.alarm_rounded,
      isWide: false,
      isActive: false,
    ),
    const QsTileModel(
      id: 'battery_saver',
      title: 'Battery Saver',
      icon: Icons.battery_saver_rounded,
      isWide: false,
      isActive: false,
    ),
    const QsTileModel(
      id: 'cast',
      title: 'Screen Cast',
      icon: Icons.cast_rounded,
      isWide: false,
      isActive: false,
    ),
  ];
}
