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
    ThemePreset(
      id: 'sunset_amber',
      name: 'Sunset Amber',
      description: 'Vibrant sunset orange and warm radiant amber glow',
      primarySeed: Color(0xFFEA580C),
      background: Color(0xFF1E130B),
      activePill: Color(0xFFFB923C),
      onActivePill: Color(0xFF431407),
      inactivePill: Color(0xFF332015),
      onInactivePill: Color(0xFFFED7AA),
      sliderTrack: Color(0xFF332015),
      sliderThumb: Color(0xFFFB923C),
      isDark: true,
    ),
    ThemePreset(
      id: 'crimson_ruby',
      name: 'Crimson Ruby',
      description: 'Deep velvet ruby and expressive rose quartz tones',
      primarySeed: Color(0xFFE11D48),
      background: Color(0xFF1C0E13),
      activePill: Color(0xFFFDA4AF),
      onActivePill: Color(0xFF4C0519),
      inactivePill: Color(0xFF341722),
      onInactivePill: Color(0xFFFECDD3),
      sliderTrack: Color(0xFF341722),
      sliderThumb: Color(0xFFFDA4AF),
      isDark: true,
    ),
    ThemePreset(
      id: 'electric_violet',
      name: 'Electric Violet',
      description: 'High-voltage ultraviolet and deep cosmic neon dusk',
      primarySeed: Color(0xFF7C3AED),
      background: Color(0xFF140D24),
      activePill: Color(0xFFC4B5FD),
      onActivePill: Color(0xFF2E1065),
      inactivePill: Color(0xFF281C40),
      onInactivePill: Color(0xFFEDE9FE),
      sliderTrack: Color(0xFF281C40),
      sliderThumb: Color(0xFFC4B5FD),
      isDark: true,
    ),
    ThemePreset(
      id: 'midnight_navy',
      name: 'Midnight Navy',
      description: 'Deep oceanic navy and ice blue high-contrast accents',
      primarySeed: Color(0xFF1D4ED8),
      background: Color(0xFF0B132B),
      activePill: Color(0xFF93C5FD),
      onActivePill: Color(0xFF172554),
      inactivePill: Color(0xFF1E293B),
      onInactivePill: Color(0xFFDBEAFE),
      sliderTrack: Color(0xFF1E293B),
      sliderThumb: Color(0xFF93C5FD),
      isDark: true,
    ),
    ThemePreset(
      id: 'emerald_botanical',
      name: 'Emerald Botanical',
      description: 'Lush vibrant emerald and crisp mint jade highlights',
      primarySeed: Color(0xFF059669),
      background: Color(0xFF061A14),
      activePill: Color(0xFF6EE7B7),
      onActivePill: Color(0xFF022C22),
      inactivePill: Color(0xFF133328),
      onInactivePill: Color(0xFFD1FAE5),
      sliderTrack: Color(0xFF133328),
      sliderThumb: Color(0xFF6EE7B7),
      isDark: true,
    ),
  ];
}

class CustomThemeData {
  final Color primaryColor;
  final bool isAmoled;
  final double cardOpacity;
  final double blurIntensity;
  final Color? customBackground;
  final Color? customActivePill;
  final Color? customInactivePill;
  final Color? customAccent;

  const CustomThemeData({
    this.primaryColor = const Color(0xFF2E7D32),
    this.isAmoled = false,
    this.cardOpacity = 1.0,
    this.blurIntensity = 0.0,
    this.customBackground,
    this.customActivePill,
    this.customInactivePill,
    this.customAccent,
  });

  CustomThemeData copyWith({
    Color? primaryColor,
    bool? isAmoled,
    double? cardOpacity,
    double? blurIntensity,
    Color? customBackground,
    Color? customActivePill,
    Color? customInactivePill,
    Color? customAccent,
  }) {
    return CustomThemeData(
      primaryColor: primaryColor ?? this.primaryColor,
      isAmoled: isAmoled ?? this.isAmoled,
      cardOpacity: cardOpacity ?? this.cardOpacity,
      blurIntensity: blurIntensity ?? this.blurIntensity,
      customBackground: customBackground ?? this.customBackground,
      customActivePill: customActivePill ?? this.customActivePill,
      customInactivePill: customInactivePill ?? this.customInactivePill,
      customAccent: customAccent ?? this.customAccent,
    );
  }
}
