import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';
import '../../providers/shade_state_provider.dart';
import '../../services/system_permissions_service.dart';
import '../../theme/m3_expressive_theme.dart';

/// Service control and permission setup.
class ServiceTab extends StatelessWidget {
  final ExpressiveThemeColors colors;

  const ServiceTab({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShadeStateProvider>();
    return _buildServiceScreen(context, state, colors);
  }

  Widget _buildServiceScreen(
    BuildContext context,
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    final permissions = state.permissions;
    final isOverlay = permissions['overlay'] ?? false;
    final isAccessibility = permissions['accessibility'] ?? false;
    final isNotification = permissions['notification'] ?? false;
    final isWriteSettings = permissions['writeSettings'] ?? false;
    final canEnable = state.areCorePermissionsGranted;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'System Service & Permissions',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ExpressiveShade replaces the stock notification shade by combining an accessibility gesture listener with a hardware-accelerated overlay window.',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Master Service Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: state.isServiceEnabled
                ? colors.activePill.withValues(alpha: 0.18)
                : colors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: state.isServiceEnabled ? colors.activePill : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              if (state.isServiceEnabled)
                BoxShadow(
                  color: colors.activePill.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: state.isServiceEnabled ? colors.activePill : colors.inactivePill,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  state.isServiceEnabled ? Icons.power_settings_new_rounded : Icons.power_off_rounded,
                  color: state.isServiceEnabled ? colors.onActivePill : colors.onInactivePill,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.isServiceEnabled ? 'Shade Service Active' : 'Shade Service Stopped',
                      style: state.selectedFont.textStyleBuilder(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      canEnable
                          ? (state.isServiceEnabled
                              ? 'Pull down from top of screen to open'
                              : 'Ready to start service')
                          : 'Core permissions required to activate',
                      style: state.selectedFont.textStyleBuilder(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              M3ESwitch(
                value: state.isServiceEnabled,
                onChanged: canEnable
                    ? (val) {
                        HapticFeedback.mediumImpact();
                        state.setServiceEnabled(val);
                      }
                    : (_) {
                        HapticFeedback.heavyImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please grant Overlay and Accessibility permissions first',
                              style: state.selectedFont.textStyleBuilder(color: Colors.white),
                            ),
                            backgroundColor: colors.surface,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        );
                      },
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Section Title: Required Permissions
        Text(
          'Required Permissions',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        // 1. Overlay Permission Card
        _buildPermissionItem(
          icon: Icons.layers_rounded,
          title: 'Draw Over Other Apps',
          description: 'Allows displaying the custom Material 3 Expressive shade above all apps and system UI.',
          isGranted: isOverlay,
          onTap: () => SystemPermissionsService.requestOverlayPermission(),
          state: state,
          colors: colors,
        ),
        const SizedBox(height: 12),

        // 2. Accessibility Service Card
        _buildPermissionItem(
          icon: Icons.accessibility_new_rounded,
          title: 'Accessibility Gesture Service',
          description: 'Detects top status bar pull-down gestures to deploy ExpressiveShade smoothly.',
          isGranted: isAccessibility,
          onTap: () => SystemPermissionsService.requestAccessibilityPermission(),
          state: state,
          colors: colors,
        ),
        const SizedBox(height: 24),

        // Section Title: Optional Enhancements
        Text(
          'Enhanced Features (Recommended)',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        // 3. Notification Access
        _buildPermissionItem(
          icon: Icons.notifications_active_rounded,
          title: 'Notification Listener Access',
          description: 'Intercepts incoming alerts to render them inside custom M3 cards with inline quick replies.',
          isGranted: isNotification,
          onTap: () => SystemPermissionsService.requestNotificationPermission(),
          state: state,
          colors: colors,
        ),
        const SizedBox(height: 12),

        // 4. Modify System Settings
        _buildPermissionItem(
          icon: Icons.brightness_medium_rounded,
          title: 'Modify System Settings',
          description: 'Enables the thick pill slider to adjust device hardware screen brightness directly.',
          isGranted: isWriteSettings,
          onTap: () => SystemPermissionsService.requestWriteSettingsPermission(),
          state: state,
          colors: colors,
        ),
        const SizedBox(height: 24),

        // Action Buttons: Refresh & App Info
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: colors.activePill,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                state.refreshPermissions();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Refresh Status',
                style: state.selectedFont.textStyleBuilder(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.activePill,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: colors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                SystemPermissionsService.openAppDetailsSettings();
              },
              icon: const Icon(Icons.info_outline_rounded, size: 18),
              label: Text(
                'App Info',
                style: state.selectedFont.textStyleBuilder(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
    required ShadeStateProvider state,
    required ExpressiveThemeColors colors,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isGranted ? Colors.green.withValues(alpha: 0.4) : colors.textSecondary.withValues(alpha: 0.15),
            width: isGranted ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isGranted
                    ? Colors.green.withValues(alpha: 0.18)
                    : colors.activePill.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: isGranted ? Colors.greenAccent.shade700 : colors.activePill,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: state.selectedFont.textStyleBuilder(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isGranted
                              ? Colors.green.withValues(alpha: 0.18)
                              : Colors.amber.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isGranted ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                              size: 13,
                              color: isGranted ? Colors.greenAccent.shade700 : Colors.amber.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isGranted ? 'Granted' : 'Setup',
                              style: state.selectedFont.textStyleBuilder(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isGranted ? Colors.greenAccent.shade700 : Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: state.selectedFont.textStyleBuilder(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
