import 'package:flutter/material.dart';

/// Represents an application pinned to the Quick Settings Split Shade App Dock.
class AppDockItem {
  final String packageName;
  final String appName;
  final int colorValue;

  const AppDockItem({
    required this.packageName,
    required this.appName,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  AppDockItem copyWith({
    String? packageName,
    String? appName,
    int? colorValue,
  }) {
    return AppDockItem(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'appName': appName,
        'colorValue': colorValue,
      };

  factory AppDockItem.fromJson(Map<String, dynamic> json) => AppDockItem(
        packageName: json['packageName'] as String? ?? '',
        appName: json['appName'] as String? ?? '',
        colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF2563EB,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppDockItem &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName &&
          appName == other.appName &&
          colorValue == other.colorValue;

  @override
  int get hashCode =>
      packageName.hashCode ^ appName.hashCode ^ colorValue.hashCode;
}
