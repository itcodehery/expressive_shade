import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expressive_shade/models/shade_theme.dart';
import 'package:expressive_shade/providers/shade_state_provider.dart';
import 'package:expressive_shade/theme/m3_expressive_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Independent Dark/Light Mode Dynamic Theming Tests', () {
    test('Light/Dark mode is an independent option for any selected palette', () {
      final state = ShadeStateProvider();
      expect(state.isDarkMode, isTrue);

      // 1. Forest Green in Dark Mode (matches refs/03_qs_dark_green_leak_alt.png)
      final forestPreset = ThemePreset.presets.firstWhere((p) => p.id == 'forest_green');
      state.selectPreset(forestPreset);
      expect(state.selectedPreset.id, 'forest_green');

      var colors = ExpressiveThemeColors.fromSettings(
        source: state.themeSource,
        preset: state.selectedPreset,
        custom: state.customTheme,
        isDark: state.isDarkMode,
      );
      expect(colors.isDark, isTrue);
      expect(colors.background, const Color(0xFF101712));
      expect(colors.activePill, const Color(0xFFB2DEC3));
      expect(colors.surface, const Color(0xFF1F2E23));

      // 2. Toggle to Light Mode - Preset remains Forest Green!
      state.setThemeMode(ThemeMode.light);
      expect(state.isDarkMode, isFalse);
      expect(state.selectedPreset.id, 'forest_green');

      colors = ExpressiveThemeColors.fromSettings(
        source: state.themeSource,
        preset: state.selectedPreset,
        custom: state.customTheme,
        isDark: state.isDarkMode,
      );
      expect(colors.isDark, isFalse);
      expect(colors.background, const Color(0xFFE2EDE5));
      expect(colors.activePill, const Color(0xFF2B5F44));
      expect(colors.surface, const Color(0xFFF2F7F4));

      // 3. Switch to Caramel Earth in Light Mode (matches refs/04_notifications_tray_caramel.png)
      final caramelPreset = ThemePreset.presets.firstWhere((p) => p.id == 'caramel_earth');
      state.selectPreset(caramelPreset);
      expect(state.selectedPreset.id, 'caramel_earth');

      colors = ExpressiveThemeColors.fromSettings(
        source: state.themeSource,
        preset: state.selectedPreset,
        custom: state.customTheme,
        isDark: state.isDarkMode,
      );
      expect(colors.isDark, isFalse);
      expect(colors.background, const Color(0xFFE8D4C1));
      expect(colors.activePill, const Color(0xFFA65C23));
      expect(colors.surface, const Color(0xFFF7EFE7));

      // 4. Switch to Dark Mode with Caramel Earth - Preset remains Caramel Earth!
      state.setThemeMode(ThemeMode.dark);
      expect(state.isDarkMode, isTrue);
      expect(state.selectedPreset.id, 'caramel_earth');

      colors = ExpressiveThemeColors.fromSettings(
        source: state.themeSource,
        preset: state.selectedPreset,
        custom: state.customTheme,
        isDark: state.isDarkMode,
      );
      expect(colors.isDark, isTrue);
      expect(colors.background, const Color(0xFF201712));
      expect(colors.activePill, const Color(0xFFF7CBA0));
    });

    test('toggleDarkLightMode alternates without changing active palette', () {
      final state = ShadeStateProvider();
      final skyPreset = ThemePreset.presets.firstWhere((p) => p.id == 'sky_cyan');
      state.selectPreset(skyPreset);
      expect(state.selectedPreset.id, 'sky_cyan');

      state.toggleDarkLightMode();
      expect(state.isDarkMode, isFalse);
      expect(state.selectedPreset.id, 'sky_cyan');

      state.toggleDarkLightMode();
      expect(state.isDarkMode, isTrue);
      expect(state.selectedPreset.id, 'sky_cyan');
    });
  });
}
