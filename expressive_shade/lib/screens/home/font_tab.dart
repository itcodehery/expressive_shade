import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/font_config.dart';
import '../../providers/shade_state_provider.dart';
import '../../theme/m3_expressive_theme.dart';

/// Font selection for the shade.
class FontTab extends StatelessWidget {
  final ExpressiveThemeColors colors;

  const FontTab({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShadeStateProvider>();
    return _buildFontScreen(context, state, colors);
  }

  Widget _buildFontScreen(
    BuildContext context,
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Typography & Font Selector',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose font family to be applied across the entire notification shade and control center.',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        ...FontConfig.availableFonts.map((font) {
          final isSelected = state.selectedFont.id == font.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => state.setFont(font),
              child: Container(
                padding: const EdgeInsets.all(18),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            font.name,
                            style: font.textStyleBuilder(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            font.sampleText,
                            style: font.textStyleBuilder(
                              fontSize: 13,
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
}
