import 'package:flutter/material.dart';

enum ThemeSource {
  system,
  preset,
  custom,
}

class ThemePreset {
  final String id;
  final String name;
  final String description;
  final Color primarySeed;
  final Color background;
  final Color activePill;
  final Color onActivePill;
  final Color inactivePill;
  final Color onInactivePill;
  final Color sliderTrack;
  final Color sliderThumb;
  final bool isDark;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.primarySeed,
    required this.background,
    required this.activePill,
    required this.onActivePill,
    required this.inactivePill,
    required this.onInactivePill,
    required this.sliderTrack,
    required this.sliderThumb,
    required this.isDark,
  });

  static const List<ThemePreset> presets = [
    ThemePreset(
      id: 'forest_green',
      name: 'Forest Green',
      description: 'Tactile sage & deep botanical forest tone from the M3 Expressive leak',
      primarySeed: Color(0xFF2E5E43),
      background: Color(0xFF101712),
      activePill: Color(0xFFB2DEC3),
      onActivePill: Color(0xFF0F3621),
      inactivePill: Color(0xFF23362A),
      onInactivePill: Color(0xFFE0ECE4),
      sliderTrack: Color(0xFF23362A),
      sliderThumb: Color(0xFFB2DEC3),
      isDark: true,
    ),
    ThemePreset(
      id: 'caramel_earth',
      name: 'Caramel Earth',
      description: 'Warm organic toasted caramel, terracotta & amber from Android 17 leak',
      primarySeed: Color(0xFFB45309),
      background: Color(0xFFE8D4C1),
      activePill: Color(0xFFA65C23),
      onActivePill: Color(0xFFFFFFFF),
      inactivePill: Color(0xFFFBF6F0),
      onInactivePill: Color(0xFF2D1E14),
      sliderTrack: Color(0xFFDECABA),
      sliderThumb: Color(0xFFA65C23),
      isDark: false,
    ),
    ThemePreset(
      id: 'sky_cyan',
      name: 'Glacial Sky',
      description: 'Cool arctic cyan and soft glacier tones with high contrast',
      primarySeed: Color(0xFF0284C7),
      background: Color(0xFF0E1A22),
      activePill: Color(0xFF90DCF8),
      onActivePill: Color(0xFF003549),
      inactivePill: Color(0xFF20323C),
      onInactivePill: Color(0xFFDEECF4),
      sliderTrack: Color(0xFF20323C),
      sliderThumb: Color(0xFF90DCF8),
      isDark: true,
    ),
    ThemePreset(
      id: 'amoled_stealth',
      name: 'Stealth Indigo',
      description: 'Pure black dark mode with electric indigo and crisp modern slate light mode',
      primarySeed: Color(0xFF6366F1),
      background: Color(0xFF000000),
      activePill: Color(0xFFC7D2FE),
      onActivePill: Color(0xFF1E1B4B),
      inactivePill: Color(0xFF18181D),
      onInactivePill: Color(0xFFE2E8F0),
      sliderTrack: Color(0xFF23232C),
      sliderThumb: Color(0xFFC7D2FE),
      isDark: true,
    ),
    ThemePreset(
      id: 'lavender_mist',
      name: 'Lavender Mist',
      description: 'Delicate pastel violet and expressive twilight dusk tones',
      primarySeed: Color(0xFF8B5CF6),
      background: Color(0xFF1A1326),
      activePill: Color(0xFFDDD6FE),
      onActivePill: Color(0xFF30106B),
      inactivePill: Color(0xFF2C223D),
      onInactivePill: Color(0xFFEDE8FD),
      sliderTrack: Color(0xFF2C223D),
      sliderThumb: Color(0xFFDDD6FE),
      isDark: true,
    ),
  ];
}

class CustomThemeData {
  final Color primaryColor;
  final bool isAmoled;
  final double cardOpacity;
  final double blurIntensity;

  const CustomThemeData({
    this.primaryColor = const Color(0xFF2E7D32),
    this.isAmoled = false,
    this.cardOpacity = 0.95,
    this.blurIntensity = 20.0,
  });

  CustomThemeData copyWith({
    Color? primaryColor,
    bool? isAmoled,
    double? cardOpacity,
    double? blurIntensity,
  }) {
    return CustomThemeData(
      primaryColor: primaryColor ?? this.primaryColor,
      isAmoled: isAmoled ?? this.isAmoled,
      cardOpacity: cardOpacity ?? this.cardOpacity,
      blurIntensity: blurIntensity ?? this.blurIntensity,
    );
  }
}
