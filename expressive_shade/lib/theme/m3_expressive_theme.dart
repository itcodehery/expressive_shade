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
    bool isDark = true,
    bool? isSystemDark,
  }) {
    final effectiveIsDark = isSystemDark ?? isDark;

    if (source == ThemeSource.system) {
      final seed = systemMonetColor ?? const Color(0xFF2E5E43);
      final scheme = ColorScheme.fromSeed(
        seedColor: seed,
        brightness: effectiveIsDark ? Brightness.dark : Brightness.light,
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
        isDark: effectiveIsDark,
      );
    }

    if (source == ThemeSource.custom) {
      final primary = custom.primaryColor;
      final dark = custom.isAmoled || effectiveIsDark;
      final bg = custom.isAmoled ? Colors.black : (dark ? const Color(0xFF141416) : const Color(0xFFF6F8FA));
      
      return ExpressiveThemeColors(
        background: bg,
        surface: dark ? const Color(0xFF222328) : Colors.white,
        activePill: primary,
        onActivePill: ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
            ? Colors.white
            : const Color(0xFF111827),
        inactivePill: dark ? const Color(0xFF272930) : const Color(0xFFE5E7EB),
        onInactivePill: dark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
        sliderTrack: dark ? const Color(0xFF272930) : const Color(0xFFE5E7EB),
        sliderProgress: primary,
        textPrimary: dark ? Colors.white : const Color(0xFF0F172A),
        textSecondary: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        isDark: dark,
      );
    }

    // Curated Presets: Each palette provides dedicated Light and Dark mode options
    if (!effectiveIsDark) {
      if (preset.id == 'caramel_earth') {
        // Android 17 Caramel Light (refs/04_notifications_tray_caramel.png)
        return const ExpressiveThemeColors(
          background: Color(0xFFE8D4C1),
          surface: Color(0xFFF7EFE7),
          activePill: Color(0xFFA65C23),
          onActivePill: Colors.white,
          inactivePill: Color(0xFFFBF6F0),
          onInactivePill: Color(0xFF2D1E14),
          sliderTrack: Color(0xFFDECABA),
          sliderProgress: Color(0xFFA65C23),
          textPrimary: Color(0xFF26190F),
          textSecondary: Color(0xFF7A6758),
          isDark: false,
        );
      }
      if (preset.id == 'forest_green') {
        // Forest Green Light Mode variant
        return const ExpressiveThemeColors(
          background: Color(0xFFE2EDE5),
          surface: Color(0xFFF2F7F4),
          activePill: Color(0xFF2B5F44),
          onActivePill: Colors.white,
          inactivePill: Color(0xFFEAF1ED),
          onInactivePill: Color(0xFF172D20),
          sliderTrack: Color(0xFFCDE0D4),
          sliderProgress: Color(0xFF2B5F44),
          textPrimary: Color(0xFF122319),
          textSecondary: Color(0xFF566F60),
          isDark: false,
        );
      }
      if (preset.id == 'sky_cyan') {
        return const ExpressiveThemeColors(
          background: Color(0xFFE0F2FE),
          surface: Color(0xFFF0F9FF),
          activePill: Color(0xFF0284C7),
          onActivePill: Colors.white,
          inactivePill: Color(0xFFE0F2FE),
          onInactivePill: Color(0xFF034A6E),
          sliderTrack: Color(0xFFBAE6FD),
          sliderProgress: Color(0xFF0284C7),
          textPrimary: Color(0xFF082F49),
          textSecondary: Color(0xFF0284C7),
          isDark: false,
        );
      }
      if (preset.id == 'lavender_mist') {
        return const ExpressiveThemeColors(
          background: Color(0xFFF3E8FF),
          surface: Color(0xFFFAF5FF),
          activePill: Color(0xFF7E22CE),
          onActivePill: Colors.white,
          inactivePill: Color(0xFFF3E8FF),
          onInactivePill: Color(0xFF3B0764),
          sliderTrack: Color(0xFFE9D5FF),
          sliderProgress: Color(0xFF7E22CE),
          textPrimary: Color(0xFF3B0764),
          textSecondary: Color(0xFF6B21A8),
          isDark: false,
        );
      }
      if (preset.id == 'amoled_stealth') {
        return const ExpressiveThemeColors(
          background: Color(0xFFF8FAFC),
          surface: Colors.white,
          activePill: Color(0xFF4F46E5),
          onActivePill: Colors.white,
          inactivePill: Color(0xFFF1F5F9),
          onInactivePill: Color(0xFF0F172A),
          sliderTrack: Color(0xFFE2E8F0),
          sliderProgress: Color(0xFF4F46E5),
          textPrimary: Color(0xFF0F172A),
          textSecondary: Color(0xFF64748B),
          isDark: false,
        );
      }
    } else {
      if (preset.id == 'forest_green') {
        // Android 17 Forest Green Dark (refs/03_qs_dark_green_leak_alt.png)
        return const ExpressiveThemeColors(
          background: Color(0xFF101712),
          surface: Color(0xFF1F2E23),
          activePill: Color(0xFFB2DEC3),
          onActivePill: Color(0xFF0F3621),
          inactivePill: Color(0xFF23362A),
          onInactivePill: Color(0xFFE0ECE4),
          sliderTrack: Color(0xFF23362A),
          sliderProgress: Color(0xFFB2DEC3),
          textPrimary: Color(0xFFE0ECE4),
          textSecondary: Color(0xFF91AD8D),
          isDark: true,
        );
      }
      if (preset.id == 'caramel_earth') {
        // Caramel Earth Dark Mode variant
        return const ExpressiveThemeColors(
          background: Color(0xFF201712),
          surface: Color(0xFF382A22),
          activePill: Color(0xFFF7CBA0),
          onActivePill: Color(0xFF452102),
          inactivePill: Color(0xFF382A22),
          onInactivePill: Color(0xFFF6ECE4),
          sliderTrack: Color(0xFF382A22),
          sliderProgress: Color(0xFFF7CBA0),
          textPrimary: Color(0xFFF6ECE4),
          textSecondary: Color(0xFFD1B7A4),
          isDark: true,
        );
      }
      if (preset.id == 'sky_cyan') {
        return const ExpressiveThemeColors(
          background: Color(0xFF0E1A22),
          surface: Color(0xFF20323C),
          activePill: Color(0xFF90DCF8),
          onActivePill: Color(0xFF003549),
          inactivePill: Color(0xFF20323C),
          onInactivePill: Color(0xFFDEECF4),
          sliderTrack: Color(0xFF20323C),
          sliderProgress: Color(0xFF90DCF8),
          textPrimary: Color(0xFFDEECF4),
          textSecondary: Color(0xFF7897A8),
          isDark: true,
        );
      }
      if (preset.id == 'lavender_mist') {
        return const ExpressiveThemeColors(
          background: Color(0xFF1A1326),
          surface: Color(0xFF2C223D),
          activePill: Color(0xFFDDD6FE),
          onActivePill: Color(0xFF30106B),
          inactivePill: Color(0xFF2C223D),
          onInactivePill: Color(0xFFEDE8FD),
          sliderTrack: Color(0xFF2C223D),
          sliderProgress: Color(0xFFDDD6FE),
          textPrimary: Color(0xFFEDE8FD),
          textSecondary: Color(0xFFA78BFA),
          isDark: true,
        );
      }
      if (preset.id == 'amoled_stealth') {
        return const ExpressiveThemeColors(
          background: Color(0xFF000000),
          surface: Color(0xFF18181D),
          activePill: Color(0xFFC7D2FE),
          onActivePill: Color(0xFF1E1B4B),
          inactivePill: Color(0xFF18181D),
          onInactivePill: Color(0xFFE2E8F0),
          sliderTrack: Color(0xFF23362A),
          sliderProgress: Color(0xFFC7D2FE),
          textPrimary: Colors.white,
          textSecondary: Color(0xFF94A3B8),
          isDark: true,
        );
      }
    }

    // Default to preset definition
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
