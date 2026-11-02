import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/shade_theme.dart';
import '../../providers/shade_state_provider.dart';
import '../../theme/m3_expressive_theme.dart';
import '../../widgets/custom_theme_builder_sheet.dart';

/// Theming: dark/light mode, presets, system Monet and custom theme builder.
class ThemeTab extends StatelessWidget {
  final ExpressiveThemeColors colors;

  const ThemeTab({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShadeStateProvider>();
    return _buildThemeScreen(context, state, colors);
  }

  Widget _buildThemeScreen(
    BuildContext context,
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Dynamic Theming Engine',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Adapts automatically to system wallpaper dynamic colors, curated Material 3 Expressive palettes, or custom user creations.',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // Dark / Light Mode Toggle (Android 17 Caramel Light vs Forest Green Dark)
        _buildDarkLightModeSelector(context, state, colors),
        const SizedBox(height: 20),

        // Active Palette Swatch Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colors.activePill.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CURRENT PALETTE',
                    style: state.selectedFont.textStyleBuilder(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.activePill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      state.themeSource == ThemeSource.system
                          ? 'Monet Dynamic'
                          : (state.themeSource == ThemeSource.custom
                              ? 'Custom Theme'
                              : state.selectedPreset.name),
                      style: state.selectedFont.textStyleBuilder(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.onActivePill,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildColorSample(colors.background, 'Background', colors.textSecondary, state),
                  const SizedBox(width: 10),
                  _buildColorSample(colors.activePill, 'Active Pill', colors.textSecondary, state),
                  const SizedBox(width: 10),
                  _buildColorSample(colors.inactivePill, 'Inactive Pill', colors.textSecondary, state),
                  const SizedBox(width: 10),
                  _buildColorSample(colors.sliderProgress, 'Accent', colors.textSecondary, state),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // System Theme Tile
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => state.setThemeSource(ThemeSource.system),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: state.themeSource == ThemeSource.system ? colors.activePill.withValues(alpha: 0.15) : colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: state.themeSource == ThemeSource.system ? colors.activePill : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 28,
                  color: state.themeSource == ThemeSource.system ? colors.activePill : colors.textSecondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Dynamic (Monet)',
                        style: state.selectedFont.textStyleBuilder(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pulls dynamic accent and tonal palettes directly from Android wallpaper',
                        style: state.selectedFont.textStyleBuilder(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.themeSource == ThemeSource.system)
                  Icon(Icons.check_circle_rounded, color: colors.activePill, size: 24),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Custom Theme Creator Tile
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            state.setThemeSource(ThemeSource.custom);
            CustomThemeBuilderSheet.show(context);
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: state.themeSource == ThemeSource.custom ? colors.activePill.withValues(alpha: 0.15) : colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: state.themeSource == ThemeSource.custom ? colors.activePill : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: state.customTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Custom Theme Studio',
                        style: state.selectedFont.textStyleBuilder(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.customTheme.isAmoled
                            ? 'AMOLED Black • Custom Accent Color'
                            : 'Personalized Accent & Blur Settings',
                        style: state.selectedFont.textStyleBuilder(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    CustomThemeBuilderSheet.show(context);
                  },
                  child: Text(
                    'Customize',
                    style: state.selectedFont.textStyleBuilder(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.activePill,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        Text(
          'Expressive Presets',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...ThemePreset.presets.map((preset) {
          final isSelected = state.themeSource == ThemeSource.preset && state.selectedPreset.id == preset.id;
          final pColors = ExpressiveThemeColors.fromSettings(
            source: ThemeSource.preset,
            preset: preset,
            custom: state.customTheme,
            isDark: state.isDarkMode,
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => state.selectPreset(preset),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? colors.activePill.withValues(alpha: 0.15) : colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? colors.activePill : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: pColors.activePill,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24, width: 1.5),
                      ),
                      child: Center(
                        child: Icon(Icons.circle, size: 14, color: pColors.onActivePill),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preset.name,
                            style: state.selectedFont.textStyleBuilder(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            preset.description,
                            style: state.selectedFont.textStyleBuilder(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: colors.activePill, size: 24),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDarkLightModeSelector(
    BuildContext context,
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    final font = state.selectedFont;
    final isDark = state.isDarkMode;

    final currentPaletteLight = ExpressiveThemeColors.fromSettings(
      source: state.themeSource,
      preset: state.selectedPreset,
      custom: state.customTheme,
      systemMonetColor: state.systemMonetColor,
      isDark: false,
    );
    final currentPaletteDark = ExpressiveThemeColors.fromSettings(
      source: state.themeSource,
      preset: state.selectedPreset,
      custom: state.customTheme,
      systemMonetColor: state.systemMonetColor,
      isDark: true,
    );

    final paletteName = state.themeSource == ThemeSource.system
        ? 'System Monet'
        : (state.themeSource == ThemeSource.custom
            ? 'Custom Theme'
            : state.selectedPreset.name);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.activePill.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.activePill.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    size: 22,
                    color: colors.activePill,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance Mode',
                      style: font.textStyleBuilder(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Light and Dark mode options for $paletteName',
                      style: font.textStyleBuilder(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Current Mode Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.activePill.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isDark ? 'DARK MODE' : 'LIGHT MODE',
                  style: font.textStyleBuilder(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colors.activePill,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Dual segmented cards for Light and Dark
          Row(
            children: [
              // Light Mode Option
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    state.setThemeMode(ThemeMode.light);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: !isDark
                          ? colors.activePill
                          : (colors.isDark ? Colors.black.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.45)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: !isDark
                            ? colors.activePill
                            : colors.textSecondary.withValues(alpha: 0.25),
                        width: !isDark ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.light_mode_rounded,
                              size: 19,
                              color: !isDark ? colors.onActivePill : colors.textPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Light Mode',
                              style: font.textStyleBuilder(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: !isDark ? colors.onActivePill : colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Light Palette',
                          style: font.textStyleBuilder(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: !isDark
                                ? colors.onActivePill.withValues(alpha: 0.85)
                                : colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Swatch indicators previewing active palette in Light mode
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: currentPaletteLight.background,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black12, width: 1),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: currentPaletteLight.activePill,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: currentPaletteLight.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black12, width: 1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Dark Mode Option
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    state.setThemeMode(ThemeMode.dark);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colors.activePill
                          : (colors.isDark ? Colors.black.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.45)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? colors.activePill
                            : colors.textSecondary.withValues(alpha: 0.25),
                        width: isDark ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.dark_mode_rounded,
                              size: 19,
                              color: isDark ? colors.onActivePill : colors.textPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Dark Mode',
                              style: font.textStyleBuilder(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? colors.onActivePill : colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Dark Palette',
                          style: font.textStyleBuilder(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? colors.onActivePill.withValues(alpha: 0.85)
                                : colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Swatch indicators previewing active palette in Dark mode
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: currentPaletteDark.background,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: currentPaletteDark.activePill,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: currentPaletteDark.surface,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorSample(Color color, String label, Color textColor, ShadeStateProvider state) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24, width: 1),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: state.selectedFont.textStyleBuilder(
              fontSize: 10,
              color: textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
