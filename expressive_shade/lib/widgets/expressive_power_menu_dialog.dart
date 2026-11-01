import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/font_config.dart';
import '../services/system_hardware_service.dart';
import '../theme/m3_expressive_theme.dart';

class ExpressivePowerMenuDialog extends StatelessWidget {
  final ExpressiveThemeColors colors;
  final FontConfig font;

  const ExpressivePowerMenuDialog({
    super.key,
    required this.colors,
    required this.font,
  });

  static Future<void> show(
    BuildContext context,
    ExpressiveThemeColors colors,
    FontConfig font,
  ) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => ExpressivePowerMenuDialog(colors: colors, font: font),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      elevation: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 290),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Emergency & Lockdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPowerActionItem(
                    icon: Icons.emergency_rounded,
                    label: 'Emergency',
                    isEmergency: true,
                    colors: colors,
                    font: font,
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      Navigator.of(context).pop();
                      SystemHardwareService.triggerEmergencyCall();
                    },
                  ),
                  _buildPowerActionItem(
                    icon: Icons.lock_rounded,
                    label: 'Lockdown',
                    colors: colors,
                    font: font,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).pop();
                      SystemHardwareService.triggerLockdown();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Row 2: Power off & Restart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPowerActionItem(
                    icon: Icons.power_settings_new_rounded,
                    label: 'Power off',
                    colors: colors,
                    font: font,
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      Navigator.of(context).pop();
                      SystemHardwareService.triggerPowerDialog();
                    },
                  ),
                  _buildPowerActionItem(
                    icon: Icons.restart_alt_rounded,
                    label: 'Restart',
                    colors: colors,
                    font: font,
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      Navigator.of(context).pop();
                      SystemHardwareService.triggerPowerDialog();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Row 3: Screenshot (Centered)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPowerActionItem(
                    icon: Icons.smartphone_rounded,
                    label: 'Screenshot',
                    colors: colors,
                    font: font,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).pop();
                      SystemHardwareService.triggerScreenshot();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPowerActionItem({
    required IconData icon,
    required String label,
    required ExpressiveThemeColors colors,
    required FontConfig font,
    required VoidCallback onTap,
    bool isEmergency = false,
  }) {
    final buttonColor = isEmergency ? const Color(0xFFE53935) : colors.inactivePill;
    final iconColor = isEmergency ? Colors.white : colors.onInactivePill;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(34),
          onTap: onTap,
          child: Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: buttonColor,
              shape: BoxShape.circle,
              boxShadow: [
                if (isEmergency)
                  BoxShadow(
                    color: const Color(0xFFE53935).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: isEmergency ? 32 : 26,
                color: iconColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: font.textStyleBuilder(
            fontSize: 13.0,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
