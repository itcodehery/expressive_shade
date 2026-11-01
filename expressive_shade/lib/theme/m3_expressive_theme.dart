import 'package:flutter/material.dart';
import '../models/font_config.dart';
import '../models/shade_theme.dart';

class ExpressiveThemeColors {
  final Color background;
  final Color surface;
  final Color activePill;
  final Color onActivePill;
  final Color inactivePill;
  final Color onInactivePill;
  final Color sliderTrack;
  final Color sliderProgress;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const ExpressiveThemeColors({
    required this.background,
    required this.surface,
    required this.activePill,
    required this.onActivePill,
    required this.inactivePill,
    required this.onInactivePill,
    required this.sliderTrack,
    required this.sliderProgress,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  static ExpressiveThemeColors fromSettings({
    required ThemeSource source,
    required ThemePreset preset,
    required CustomThemeData custom,
    Color? systemMonetColor,
    bool isSystemDark = true,
  }) {
    if (source == ThemeSource.system) {
      final seed = systemMonetColor ?? const Color(0xFF2E5E43);
      final scheme = ColorScheme.fromSeed(
        seedColor: seed,
        brightness: isSystemDark ? Brightness.dark : Brightness.light,
      );
      return ExpressiveThemeColors(
        background: scheme.surface,
        surface: scheme.surfaceContainerHigh,
        activePill: scheme.primaryContainer,
        onActivePill: scheme.onPrimaryContainer,
        inactivePill: scheme.surfaceContainer,
        onInactivePill: scheme.onSurfaceVariant,
        sliderTrack: scheme.surfaceContainer,
        sliderProgress: scheme.primaryContainer,
        textPrimary: scheme.onSurface,
        textSecondary: scheme.onSurfaceVariant,
        isDark: isSystemDark,
      );
    }

    if (source == ThemeSource.custom) {
      final primary = custom.primaryColor;
      final isDark = custom.isAmoled || isSystemDark;
      final bg = custom.isAmoled ? Colors.black : (isDark ? const Color(0xFF141416) : const Color(0xFFF6F8FA));
      
      return ExpressiveThemeColors(
        background: bg,
        surface: isDark ? const Color(0xFF222328) : Colors.white,
        activePill: primary,
        onActivePill: ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
            ? Colors.white
            : const Color(0xFF111827),
        inactivePill: isDark ? const Color(0xFF272930) : const Color(0xFFE5E7EB),
        onInactivePill: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
        sliderTrack: isDark ? const Color(0xFF272930) : const Color(0xFFE5E7EB),
        sliderProgress: primary,
        textPrimary: isDark ? Colors.white : const Color(0xFF0F172A),
        textSecondary: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        isDark: isDark,
      );
    }

    // Default to preset
    return ExpressiveThemeColors(
      background: preset.background,
      surface: preset.inactivePill,
      activePill: preset.activePill,
      onActivePill: preset.onActivePill,
      inactivePill: preset.inactivePill,
      onInactivePill: preset.onInactivePill,
      sliderTrack: preset.sliderTrack,
      sliderProgress: preset.sliderThumb,
      textPrimary: preset.isDark ? Colors.white : const Color(0xFF111827),
      textSecondary: preset.isDark ? const Color(0xFFA1A1AA) : const Color(0xFF4B5563),
      isDark: preset.isDark,
    );
  }

  ThemeData toThemeData(FontConfig fontConfig) {
    final baseTextStyle = fontConfig.textStyleBuilder();
    final brightness = isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: activePill,
        brightness: brightness,
      ),
      textTheme: TextTheme(
        headlineLarge: fontConfig.textStyleBuilder(fontSize: 32, fontWeight: FontWeight.w700),
        headlineMedium: fontConfig.textStyleBuilder(fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: fontConfig.textStyleBuilder(fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: fontConfig.textStyleBuilder(fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: fontConfig.textStyleBuilder(fontSize: 14, fontWeight: FontWeight.w500),
        bodyLarge: fontConfig.textStyleBuilder(fontSize: 15, fontWeight: FontWeight.w400),
        bodyMedium: fontConfig.textStyleBuilder(fontSize: 13, fontWeight: FontWeight.w400),
        bodySmall: fontConfig.textStyleBuilder(fontSize: 11, fontWeight: FontWeight.w400),
        labelLarge: fontConfig.textStyleBuilder(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      fontFamily: baseTextStyle.fontFamily,
    );
  }
}
