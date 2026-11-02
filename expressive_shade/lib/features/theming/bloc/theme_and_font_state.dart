import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../models/font_config.dart';
import '../../../models/shade_theme.dart';
import '../../../theme/m3_expressive_theme.dart';

class ThemeAndFontState extends Equatable {
  final ThemeMode themeMode;
  final ThemeSource themeSource;
  final ThemePreset selectedPreset;
  final CustomThemeData customTheme;
  final FontConfig selectedFont;
  final Color? systemMonetColor;

  ThemeAndFontState({
    this.themeMode = ThemeMode.dark,
    this.themeSource = ThemeSource.preset,
    required this.selectedPreset,
    this.customTheme = const CustomThemeData(),
    FontConfig? selectedFont,
    this.systemMonetColor,
  }) : selectedFont = selectedFont ?? FontConfig.defaultFont;

  bool get isDarkMode => themeMode == ThemeMode.dark;

  ExpressiveThemeColors getThemeColors(bool isPlatformDark) {
    final isDark = themeMode == ThemeMode.system ? isPlatformDark : isDarkMode;
    return ExpressiveThemeColors.fromSettings(
      source: themeSource,
      preset: selectedPreset,
      custom: customTheme,
      systemMonetColor: systemMonetColor,
      isDark: isDark,
    );
  }

  ThemeAndFontState copyWith({
    ThemeMode? themeMode,
    ThemeSource? themeSource,
    ThemePreset? selectedPreset,
    CustomThemeData? customTheme,
    FontConfig? selectedFont,
    Color? systemMonetColor,
  }) {
    return ThemeAndFontState(
      themeMode: themeMode ?? this.themeMode,
      themeSource: themeSource ?? this.themeSource,
      selectedPreset: selectedPreset ?? this.selectedPreset,
      customTheme: customTheme ?? this.customTheme,
      selectedFont: selectedFont ?? this.selectedFont,
      systemMonetColor: systemMonetColor ?? this.systemMonetColor,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        themeSource,
        selectedPreset,
        customTheme,
        selectedFont,
        systemMonetColor,
      ];
}
