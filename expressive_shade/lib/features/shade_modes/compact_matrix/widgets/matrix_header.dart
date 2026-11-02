import 'package:flutter/material.dart';
import '../../../../models/font_config.dart';
import '../../../../theme/m3_expressive_theme.dart';

class MatrixHeader extends StatelessWidget {
  final int batteryLevel;
  final bool isCharging;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final VoidCallback onEditTap;

  const MatrixHeader({
    super.key,
    required this.batteryLevel,
    required this.isCharging,
    required this.colors,
    required this.font,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final amPm = now.hour >= 12 ? 'pm' : 'am';

    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final dateFormatted = '$month / $day';

    final topPadding = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.only(top: topPadding > 0 ? topPadding + 6 : 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Time & Date Chip on the left
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.inactivePill.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded, size: 15, color: colors.activePill),
                const SizedBox(width: 6),
                Text(
                  '$hour:$minute $amPm',
                  style: font.textStyleBuilder(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 3.5,
                  height: 3.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateFormatted,
                  style: font.textStyleBuilder(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Battery & Edit Controls Chip on the right
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.inactivePill.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCharging
                          ? Icons.battery_charging_full_rounded
                          : Icons.battery_full_rounded,
                      size: 15,
                      color: colors.activePill,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCharging ? 'Charging $batteryLevel%' : '$batteryLevel%',
                      style: font.textStyleBuilder(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Edit Tile Positions Button
              GestureDetector(
                onTap: onEditTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.70),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.inactivePill.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
