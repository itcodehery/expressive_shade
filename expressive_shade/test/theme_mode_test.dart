import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expressive_shade/models/shade_theme.dart';
import 'package:expressive_shade/providers/shade_state_provider.dart';
import 'package:expressive_shade/theme/m3_expressive_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Theme Colors and Notification Container Tests', () {
    test('Theme directly follows preset colors and notification area is darker than background', () {
      final state = ShadeStateProvider();

      // 1. Forest Green
      final forestPreset = ThemePreset.presets.firstWhere((p) => p.id == 'forest_green');
      state.selectPreset(forestPreset);
      expect(state.selectedPreset.id, 'forest_green');

      var colors = ExpressiveThemeColors.fromSettings(
        source: state.themeSource,
        preset: state.selectedPreset,
        custom: state.customTheme,
      );
      expect(colors.background, forestPreset.background);
      expect(colors.activePill, forestPreset.activePill);
      expect(
        HSLColor.fromColor(colors.notificationContainerBackground).lightness,
        lessThan(HSLColor.fromColor(colors.background).lightness),
      );

      // 2. Caramel Earth
      final caramelPreset = ThemePreset.presets.firstWhere((p) => p.id == 'caramel_earth');
      state.selectPreset(caramelPreset);
      expect(state.selectedPreset.id, 'caramel_earth');

      colors = ExpressiveThemeColors.fromSettings(
        source: state.themeSource,
        preset: state.selectedPreset,
        custom: state.customTheme,
      );
      expect(colors.background, caramelPreset.background);
      expect(colors.activePill, caramelPreset.activePill);
      expect(
        HSLColor.fromColor(colors.notificationContainerBackground).lightness,
        lessThan(HSLColor.fromColor(colors.background).lightness),
      );

      // 3. Lavender Mist
      final lavenderPreset = ThemePreset.presets.firstWhere((p) => p.id == 'lavender_mist');
      state.selectPreset(lavenderPreset);
      expect(state.selectedPreset.id, 'lavender_mist');

      colors = ExpressiveThemeColors.fromSettings(
        source: state.themeSource,
        preset: state.selectedPreset,
        custom: state.customTheme,
      );
      expect(colors.background, lavenderPreset.background);
      expect(
        HSLColor.fromColor(colors.notificationContainerBackground).lightness,
        lessThan(HSLColor.fromColor(colors.background).lightness),
      );

      // 4. Custom Theme directly follows individual user colors
      state.updateCustomTheme(const CustomThemeData(
        customBackground: Color(0xFF1E1E2E),
        customActivePill: Color(0xFFCBA6F7),
        customInactivePill: Color(0xFF313244),
        customAccent: Color(0xFFF38BA8),
      ));

      colors = ExpressiveThemeColors.fromSettings(
        source: state.themeSource,
        preset: state.selectedPreset,
        custom: state.customTheme,
      );
      expect(colors.background, const Color(0xFF1E1E2E));
      expect(colors.activePill, const Color(0xFFCBA6F7));
      expect(colors.inactivePill, const Color(0xFF313244));
      expect(colors.sliderProgress, const Color(0xFFF38BA8));
      expect(
        HSLColor.fromColor(colors.notificationContainerBackground).lightness,
        lessThan(HSLColor.fromColor(colors.background).lightness),
      );
    });
  });
}
