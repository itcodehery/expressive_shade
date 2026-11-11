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
    final isDndPolicy = permissions['dndPolicy'] ?? false;
    final isWriteSecure = permissions['writeSecureSettings'] ?? false;
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
        const SizedBox(height: 12),

        // 4b. Do Not Disturb Policy Access
        _buildPermissionItem(
          icon: Icons.do_not_disturb_on_rounded,
          title: 'Do Not Disturb Policy Access',
          description: 'Required to toggle DnD and switch Zen Modes (Focus, Normal, Bedtime) directly from the shade.',
          isGranted: isDndPolicy,
          onTap: () => SystemPermissionsService.requestDndPolicyPermission(),
          state: state,
          colors: colors,
        ),
        const SizedBox(height: 24),

        // Section Title: Advanced Privileges (Shizuku & ADB)
        Text(
          'Advanced Tile Privileges (Shizuku / ADB)',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Modern Android strictly locks Airplane Mode, Battery Saver, Mobile Hotspot, and Night Light behind system-level permissions. You can unlock 100% silent 1-tap toggling using Shizuku or a one-time ADB command.',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 13,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),

        // Shizuku / Secure Settings Card
        _buildShizukuStatusCard(
          context: context,
          isGranted: isWriteSecure,
          state: state,
          colors: colors,
        ),
        const SizedBox(height: 24),

        // Section Title: Features & Automations
        Text(
          'Features & Automations',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        // 5. Smart Notification Classifier Toggle
        _buildClassifierToggleItem(
          title: 'Smart Notification Classifier',
          description: 'Offline ML & heuristic categorization into Realtime, Security, Conversations, Updates, and Promotions with 1-tap OTP actions.',
          isEnabled: state.isSmartClassifierEnabled,
          onChanged: (val) {
            HapticFeedback.mediumImpact();
            state.setSmartClassifierEnabled(val);
          },
          state: state,
          colors: colors,
        ),
        const SizedBox(height: 12),

        // 6. Accessibility Trigger Ball Toggle
        _buildSettingToggleItem(
          icon: Icons.touch_app_rounded,
          title: 'Accessibility Floating Edge Ball',
          description: 'Adds a small draggable ball to the edge of the screen that directly and smoothly expands the shade when tapped.',
          badge: 'Accessibility',
          isEnabled: state.isTriggerBallEnabled,
          onChanged: (val) {
            HapticFeedback.mediumImpact();
            state.setTriggerBallEnabled(val);
          },
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

  Widget _buildClassifierToggleItem({
    required String title,
    required String description,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
    required ShadeStateProvider state,
    required ExpressiveThemeColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isEnabled
                  ? colors.activePill.withValues(alpha: 0.18)
                  : colors.inactivePill.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 22,
              color: isEnabled ? colors.activePill : colors.textSecondary,
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
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? colors.activePill.withValues(alpha: 0.18)
                            : colors.inactivePill.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isEnabled ? 'Active' : 'Off',
                        style: state.selectedFont.textStyleBuilder(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isEnabled ? colors.activePill : colors.textSecondary,
                        ),
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.offline_bolt_rounded,
                      size: 13,
                      color: isEnabled ? Colors.greenAccent.shade700 : colors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'On-Device • 7 Categories • Offline',
                      style: state.selectedFont.textStyleBuilder(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isEnabled ? Colors.greenAccent.shade700 : colors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    M3ESwitch(
                      value: isEnabled,
                      onChanged: onChanged,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingToggleItem({
    required IconData icon,
    required String title,
    required String description,
    required String badge,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
    required ShadeStateProvider state,
    required ExpressiveThemeColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isEnabled
                  ? colors.activePill.withValues(alpha: 0.18)
                  : colors.inactivePill.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 22,
              color: isEnabled ? colors.activePill : colors.textSecondary,
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
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? colors.activePill.withValues(alpha: 0.18)
                            : colors.inactivePill.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isEnabled ? 'Enabled' : 'Disabled',
                        style: state.selectedFont.textStyleBuilder(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isEnabled ? colors.activePill : colors.textSecondary,
                        ),
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.accessibility_new_rounded,
                      size: 13,
                      color: isEnabled ? colors.activePill : colors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      badge,
                      style: state.selectedFont.textStyleBuilder(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isEnabled ? colors.activePill : colors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    M3ESwitch(
                      value: isEnabled,
                      onChanged: onChanged,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShizukuStatusCard({
    required BuildContext context,
    required bool isGranted,
    required ShadeStateProvider state,
    required ExpressiveThemeColors colors,
  }) {
    const adbCommand = 'adb shell pm grant com.example.expressive_shade android.permission.WRITE_SECURE_SETTINGS';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isGranted
              ? Colors.green.withValues(alpha: 0.3)
              : colors.activePill.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isGranted
                      ? Colors.green.withValues(alpha: 0.18)
                      : colors.activePill.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGranted ? Icons.verified_user_rounded : Icons.terminal_rounded,
                  size: 24,
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
                            isGranted ? 'Shizuku / ADB Privileges Active' : 'Shizuku / ADB Required',
                            style: state.selectedFont.textStyleBuilder(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
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
                          child: Text(
                            isGranted ? 'Unlocked' : 'Optional',
                            style: state.selectedFont.textStyleBuilder(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isGranted ? Colors.greenAccent.shade700 : Colors.amber.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isGranted
                          ? 'All Quick Settings tiles (Hotspot, Airplane, Battery Saver, Night Light) can now toggle silently.'
                          : 'Without this, tapping Airplane Mode, Hotspot, or Battery Saver opens their respective system setting panels instead of direct silent toggling.',
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
          if (!isGranted) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.code_rounded, size: 14, color: colors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Run once via Computer or Shizuku runner:',
                        style: state.selectedFont.textStyleBuilder(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    adbCommand,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF80CBC4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.activePill,
                    side: BorderSide(color: colors.activePill.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(const ClipboardData(text: adbCommand));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ADB command copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(
                    'Copy Command',
                    style: state.selectedFont.textStyleBuilder(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.activePill,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
