import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/font_config.dart';
import '../../models/qs_tile_model.dart';
import '../../models/shade_mode.dart';
import '../../models/slider_style.dart';
import '../../providers/shade_state_provider.dart';
import '../../theme/m3_expressive_theme.dart';
import '../../widgets/expressive_slider.dart';

/// Shade layout: split vs unified mode, slider style and network tile style.
class LayoutTab extends StatelessWidget {
  final ExpressiveThemeColors colors;

  const LayoutTab({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShadeStateProvider>();
    return _buildLayoutScreen(context, state, colors);
  }

  Widget _buildLayoutScreen(
    BuildContext context,
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Shade Mode Architecture',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose between Android 17\'s separate notifications / control center, or the classic single pull-down shade.',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        ...ShadeMode.values.map((mode) {
          final isSelected = state.shadeMode == mode;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => state.setShadeMode(mode),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected ? colors.activePill.withValues(alpha: 0.15) : colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? colors.activePill : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      mode == ShadeMode.split ? Icons.splitscreen_rounded : Icons.view_stream_rounded,
                      size: 32,
                      color: isSelected ? colors.activePill : colors.textSecondary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode.displayName,
                            style: state.selectedFont.textStyleBuilder(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mode.description,
                            style: state.selectedFont.textStyleBuilder(
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? colors.activePill : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? colors.activePill : colors.textSecondary.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors.onActivePill,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 28),
        Text(
          'Slider Style',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Customize the visual ergonomic appearance of brightness and volume thick sliders.',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        ...SliderStyle.values.map((style) {
          final isSelected = state.sliderStyle == style;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                HapticFeedback.lightImpact();
                state.setSliderStyle(style);
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected ? colors.activePill.withValues(alpha: 0.15) : colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? colors.activePill : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                style.displayName,
                                style: state.selectedFont.textStyleBuilder(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                style.description,
                                style: state.selectedFont.textStyleBuilder(
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? colors.activePill : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? colors.activePill : colors.textSecondary.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colors.onActivePill,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    IgnorePointer(
                      child: ExpressiveSlider(
                        value: 0.72,
                        onChanged: (_) {},
                        leadingIcon: Icons.wb_sunny_rounded,
                        colors: colors,
                        height: 48,
                        style: style,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 28),

        Text(
          'Network Tile Configuration',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Toggle between the unified Internet pill or separate dedicated Wi-Fi and Mobile Data tiles.',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // Option 1: Unified Internet Tile
        _buildNetworkTileOption(
          title: 'Unified Internet Tile',
          subtitle: 'Combined Wi-Fi & Mobile Data in a single expandable 1x2 pill.',
          icon: Icons.wifi_find_rounded,
          isSelected: state.networkTileStyle == NetworkTileStyle.unified,
          colors: colors,
          font: state.selectedFont,
          onTap: () {
            HapticFeedback.lightImpact();
            state.setNetworkTileStyle(NetworkTileStyle.unified);
          },
        ),
        const SizedBox(height: 12),

        // Option 2: Separate Wi-Fi & Mobile Data Tiles
        _buildNetworkTileOption(
          title: 'Separate Wi-Fi & Mobile Data',
          subtitle: 'Individual tiles for Wi-Fi and Mobile Data with direct one-tap toggles.',
          icon: Icons.signal_cellular_alt_rounded,
          isSelected: state.networkTileStyle == NetworkTileStyle.separate,
          colors: colors,
          font: state.selectedFont,
          onTap: () {
            HapticFeedback.lightImpact();
            state.setNetworkTileStyle(NetworkTileStyle.separate);
          },
        ),
      ],
    );
  }

  Widget _buildNetworkTileOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required ExpressiveThemeColors colors,
    required FontConfig font,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? colors.activePill.withValues(alpha: 0.15) : colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? colors.activePill : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? colors.activePill : colors.inactivePill,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? colors.onActivePill : colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: font.textStyleBuilder(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: font.textStyleBuilder(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? colors.activePill : Colors.transparent,
                border: Border.all(
                  color: isSelected ? colors.activePill : colors.textSecondary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.onActivePill,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
