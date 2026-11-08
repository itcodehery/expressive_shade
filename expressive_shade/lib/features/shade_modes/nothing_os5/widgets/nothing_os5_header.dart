import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/font_config.dart';
import '../../../../theme/m3_expressive_theme.dart';

/// NothingOS 5 expressive status header:
/// Left: Large industrial-modern Time display + Accent dot & Date row below.
/// Right: Elevated Status & Battery capsule on top + Carrier badge below.
class NothingOs5StatusHeader extends StatefulWidget {
  final FontConfig font;
  final ExpressiveThemeColors colors;
  final int batteryLevel;
  final bool isCharging;
  final String carrierName;

  const NothingOs5StatusHeader({
    super.key,
    required this.font,
    required this.colors,
    required this.batteryLevel,
    required this.isCharging,
    required this.carrierName,
  });

  @override
  State<NothingOs5StatusHeader> createState() => _NothingOs5StatusHeaderState();
}

class _NothingOs5StatusHeaderState extends State<NothingOs5StatusHeader> {
  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _scheduleNextTick();
  }

  void _scheduleNextTick() {
    final now = DateTime.now();
    final untilNextMinute = Duration(
      seconds: 60 - now.second,
      milliseconds: -now.millisecond,
    );
    _timer = Timer(untilNextMinute, () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _scheduleNextTick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final font = widget.font;
    final colors = widget.colors;
    final hourStr = _now.hour.toString().padLeft(2, '0');
    final minStr = _now.minute.toString().padLeft(2, '0');
    final weekdayStr = _weekdays[_now.weekday - 1];
    final dateStr = '${_months[_now.month - 1]} ${_now.day}';
    final carrier = widget.carrierName.trim().isNotEmpty
        ? widget.carrierName.trim()
        : '5G • Online';

    final statusPillBg = colors.isDark
        ? colors.surface.withValues(alpha: 0.85)
        : colors.surface;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: Large Time + Accent Dot & Date Subtitle
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  hourStr,
                  style: font
                      .textStyleBuilder(
                        fontSize: 32.0,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      )
                      .copyWith(letterSpacing: -1.0, height: 1.0),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Text(
                    ':',
                    style: font
                        .textStyleBuilder(
                          fontSize: 28.0,
                          fontWeight: FontWeight.w800,
                          color: colors.activePill,
                        )
                        .copyWith(height: 1.0),
                  ),
                ),
                Text(
                  minStr,
                  style: font
                      .textStyleBuilder(
                        fontSize: 32.0,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      )
                      .copyWith(letterSpacing: -1.0, height: 1.0),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.activePill,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '$weekdayStr, $dateStr'.toUpperCase(),
                  style: font
                      .textStyleBuilder(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                      )
                      .copyWith(letterSpacing: 0.9),
                ),
              ],
            ),
          ],
        ),

        // Right: Status Capsule (Wi-Fi + Battery) + Carrier Row
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusPillBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_rounded, size: 15, color: colors.textPrimary),
                  const SizedBox(width: 8),
                  // Battery icon with terminal cap
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 11.5,
                        padding: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3.5),
                          border: Border.all(
                            color: colors.textPrimary.withValues(alpha: 0.85),
                            width: 1.2,
                          ),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (widget.batteryLevel / 100.0).clamp(
                            0.1,
                            1.0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: widget.isCharging
                                  ? Colors.greenAccent.shade400
                                  : (widget.batteryLevel <= 20
                                        ? Colors.redAccent
                                        : colors.textPrimary),
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 4.5,
                        margin: const EdgeInsets.only(left: 1),
                        decoration: BoxDecoration(
                          color: colors.textPrimary.withValues(alpha: 0.7),
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.isCharging) ...[
                    const SizedBox(width: 3),
                    Icon(Icons.bolt_rounded, size: 14),
                  ],
                  const SizedBox(width: 6),
                  Text(
                    '${widget.batteryLevel}%',
                    style: font.textStyleBuilder(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.signal_cellular_alt_rounded,
                    size: 12,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    carrier,
                    style: font
                        .textStyleBuilder(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        )
                        .copyWith(letterSpacing: 0.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// NothingOS 5 Control Center Toolbar:
/// Outlined Edit pill on the left, Settings gear and Power button on the right.
class NothingOs5ControlToolbar extends StatelessWidget {
  final FontConfig font;
  final ExpressiveThemeColors colors;
  final VoidCallback onEditTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onPowerTap;

  const NothingOs5ControlToolbar({
    super.key,
    required this.font,
    required this.colors,
    required this.onEditTap,
    required this.onSettingsTap,
    required this.onPowerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Outlined Edit Pill
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onEditTap();
          },
          child: Container(
            width: 56,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colors.textPrimary.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.edit_outlined,
                size: 18,
                color: colors.textPrimary,
              ),
            ),
          ),
        ),

        const Spacer(),

        // Settings gear icon
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () {
            HapticFeedback.lightImpact();
            onSettingsTap();
          },
          icon: Icon(
            Icons.settings_outlined,
            size: 22,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(width: 2),

        // Power icon
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () {
            HapticFeedback.lightImpact();
            onPowerTap();
          },
          icon: Icon(
            Icons.power_settings_new_rounded,
            size: 22,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
