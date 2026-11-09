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

  /// Notification area container background: follows the theme and is distinctly darker than [background].
  Color get notificationContainerBackground {
    final hsl = HSLColor.fromColor(background);
    if (isDark) {
      // Deeper, richer tone of the theme background
      final darkerLightness = (hsl.lightness * 0.65).clamp(0.02, 0.35);
      return hsl.withLightness(darkerLightness).toColor();
    } else {
      // In a light theme, darker than the background
      final darkerLightness = (hsl.lightness * 0.88).clamp(0.15, 0.88);
      return hsl.withLightness(darkerLightness).toColor();
    }
  }

  /// Individual notification card background: follows the theme surface with contrast against container.
  Color get notificationCardBackground {
    final hsl = HSLColor.fromColor(notificationContainerBackground);
    if (isDark) {
      final cardLightness = (hsl.lightness + 0.09).clamp(0.08, 0.45);
      return hsl.withLightness(cardLightness).toColor();
    } else {
      return Colors.white;
    }
  }

  static ExpressiveThemeColors fromSettings({
    required ThemeSource source,
    required ThemePreset preset,
    required CustomThemeData custom,
    Color? systemMonetColor,
    bool isDark = true,
    bool? isSystemDark,
  }) {
    if (source == ThemeSource.system) {
      final seed = systemMonetColor ?? const Color(0xFF2E5E43);
      final scheme = ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
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
        isDark: true,
      );
    }

    if (source == ThemeSource.custom) {
      final defaultBg = custom.isAmoled ? Colors.black : const Color(0xFF141416);
      final bg = custom.customBackground ?? defaultBg;
      final active = custom.customActivePill ?? custom.primaryColor;
      final defaultInactive = const Color(0xFF272930);
      final inactive = custom.customInactivePill ?? defaultInactive;
      final accent = custom.customAccent ?? custom.primaryColor;

      final isBgDark = ThemeData.estimateBrightnessForColor(bg) == Brightness.dark;

      return ExpressiveThemeColors(
        background: bg,
        surface: isBgDark ? const Color(0xFF222328) : Colors.white,
        activePill: active,
        onActivePill: ThemeData.estimateBrightnessForColor(active) == Brightness.dark
            ? Colors.white
            : const Color(0xFF111827),
        inactivePill: inactive,
        onInactivePill: ThemeData.estimateBrightnessForColor(inactive) == Brightness.dark
            ? const Color(0xFFE2E8F0)
            : const Color(0xFF334155),
        sliderTrack: inactive,
        sliderProgress: accent,
        textPrimary: isBgDark ? Colors.white : const Color(0xFF0F172A),
        textSecondary: isBgDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        isDark: isBgDark,
      );
    }

    // Curated Presets: Follow the exact colors of the selected theme
    final isBgDark = preset.isDark;
    final isMonochrome = preset.id.startsWith('monochrome_');
    return ExpressiveThemeColors(
      background: preset.background,
      surface: preset.inactivePill,
      activePill: preset.activePill,
      onActivePill: preset.onActivePill,
      inactivePill: preset.inactivePill,
      onInactivePill: preset.onInactivePill,
      sliderTrack: preset.sliderTrack,
      sliderProgress: preset.sliderThumb,
      textPrimary: isBgDark
          ? Colors.white
          : (isMonochrome ? const Color(0xFF27272A) : const Color(0xFF0F172A)),
      textSecondary: isBgDark
          ? (isMonochrome ? const Color(0xFFA3A3A3) : const Color(0xFF94A3B8))
          : (isMonochrome ? const Color(0xFF71717A) : const Color(0xFF64748B)),
      isDark: isBgDark,
    );
  }

  // Predefined Fallback / Default Palette
  static const ExpressiveThemeColors defaultTheme = ExpressiveThemeColors(
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

/// Material 3 Motion tokens and easing curves per m3.material.io specifications.
class M3Motion {
  M3Motion._();

  // Material 3 Emphasized Easing Curves
  /// Easing used when elements enter or containers expand.
  static const Cubic emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Easing used when elements exit or containers collapse.
  static const Cubic emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

  /// Complete emphasized transition curve (bidirectional / standard emphasized).
  static const Cubic emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Material 3 Standard Decelerate.
  static const Cubic standardDecelerate = Cubic(0.0, 0.0, 0.2, 1.0);

  /// Material 3 Standard Accelerate.
  static const Cubic standardAccelerate = Cubic(0.4, 0.0, 1.0, 1.0);

  // Material 3 Motion Durations
  /// Duration for container expansion (~380ms).
  static const Duration expandDuration = Duration(milliseconds: 380);

  /// Duration for container collapse (~260ms).
  static const Duration collapseDuration = Duration(milliseconds: 260);

  /// Duration for group transition or cross-fades (~320ms).
  static const Duration groupDuration = Duration(milliseconds: 320);

  /// Quick icon or micro-interaction rotation duration (~260ms).
  static const Duration microDuration = Duration(milliseconds: 260);
}

