import 'package:flutter/material.dart';

enum ThemeSource { system, preset, custom }

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
      description:
          'Tactile sage & deep botanical forest tone from the M3 Expressive leak',
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
      id: 'monochrome_black',
      name: 'Monochrome Black',
      description:
          'Pure AMOLED black dark mode with stark white active pills and graphite surfaces',
      primarySeed: Color(0xFFFFFFFF),
      background: Color(0xFF000000),
      activePill: Color(0xFFFFFFFF),
      onActivePill: Color(0xFF000000),
      inactivePill: Color(0xFF1A1A1A),
      onInactivePill: Color(0xFFE5E5E5),
      sliderTrack: Color(0xFF262626),
      sliderThumb: Color(0xFFFFFFFF),
      isDark: true,
    ),
    ThemePreset(
      id: 'monochrome_white',
      name: 'Monochrome White',
      description:
          'Pure white light mode with soft silver-grey active pills and alabaster surfaces',
      primarySeed: Color(0xFFD4D4D8),
      background: Color(0xFFFFFFFF),
      activePill: Color(0xFFD4D4D8),
      onActivePill: Color(0xFF27272A),
      inactivePill: Color(0xFFF2F2F5),
      onInactivePill: Color(0xFF52525B),
      sliderTrack: Color(0xFFF2F2F5),
      sliderThumb: Color(0xFFD4D4D8),
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
      description:
          'Pure black dark mode with electric indigo and crisp modern slate light mode',
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
      id: 'cyber_acid',
      name: 'Cyber Acid',
      description:
          'Deep midnight synthwave plum contrasted with electric acid lime & hot coral',
      primarySeed: Color(0xFFA3E635),
      background: Color(0xFF120B1E),
      activePill: Color(0xFFD9F970),
      onActivePill: Color(0xFF1D2800),
      inactivePill: Color(0xFF25183B),
      onInactivePill: Color(0xFFF3E8FF),
      sliderTrack: Color(0xFF31204D),
      sliderThumb: Color(0xFFFF6B9D),
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
      id: 'terracotta_teal',
      name: 'Lagoon & Terracotta',
      description:
          'Abyssal petrol teal balanced with warm sun-baked terracotta coral',
      primarySeed: Color(0xFFF97316),
      background: Color(0xFF0A1B1F),
      activePill: Color(0xFFFF9B73),
      onActivePill: Color(0xFF3B1104),
      inactivePill: Color(0xFF163138),
      onInactivePill: Color(0xFFD9F2F7),
      sliderTrack: Color(0xFF1E4049),
      sliderThumb: Color(0xFFFF9B73),
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
