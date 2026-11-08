import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/font_config.dart';
import '../models/qs_tile_model.dart';
import '../providers/shade_state_provider.dart';
import '../services/system_hardware_service.dart';
import '../theme/m3_expressive_theme.dart';

class ExpressiveConnectivityDialog extends StatelessWidget {
  final String tileId;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final void Function(VoidCallback action)? onDismissAndExecute;

  const ExpressiveConnectivityDialog({
    super.key,
    required this.tileId,
    required this.colors,
    required this.font,
    this.onDismissAndExecute,
  });

  static bool isConnectivityDialogTile(String id) =>
      id == 'wifi' || id == 'mobile_data' || id == 'bluetooth';

  static Future<void> show(
    BuildContext context, {
    required String tileId,
    required ExpressiveThemeColors colors,
    required FontConfig font,
    void Function(VoidCallback action)? onDismissAndExecute,
  }) {
    HapticFeedback.lightImpact();
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => ExpressiveConnectivityDialog(
        tileId: tileId,
        colors: colors,
        font: font,
        onDismissAndExecute: onDismissAndExecute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShadeStateProvider>();
    final isBluetooth = tileId == 'bluetooth';

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      elevation: 16,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: isBluetooth
              ? _buildBluetoothContent(context, state)
              : _buildInternetContent(context, state),
        ),
      ),
    );
  }

  Widget _buildInternetContent(BuildContext context, ShadeStateProvider state) {
    final wifiTile = state.tiles.firstWhere(
      (t) => t.id == 'wifi',
      orElse: () => QsTileModel.defaultStandardTiles.first,
    );
    final mobileTile = state.tiles.where((t) => t.id == 'mobile_data').firstOrNull;
    final isMobileActive = mobileTile?.isActive ?? true;
    final carrier = state.carrierName.isNotEmpty ? state.carrierName : 'Mobile Data';
    final wifiSub = (wifiTile.subtitle != null && wifiTile.subtitle!.isNotEmpty)
        ? wifiTile.subtitle!
        : (wifiTile.isActive ? 'Connected' : 'Off');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dialog Header
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (wifiTile.isActive || isMobileActive)
                    ? colors.activePill
                    : colors.inactivePill,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.language_rounded,
                size: 22,
                color: (wifiTile.isActive || isMobileActive)
                    ? colors.onActivePill
                    : colors.onInactivePill,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Internet',
                    style: font.textStyleBuilder(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Wi-Fi & Mobile Networks',
                    style: font.textStyleBuilder(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 1. Mobile Data Row Card
        _buildToggleRowCard(
          icon: Icons.signal_cellular_alt_rounded,
          title: carrier,
          subtitle: isMobileActive ? 'Mobile data active' : 'Mobile data off',
          isActive: isMobileActive,
          onToggle: () {
            HapticFeedback.mediumImpact();
            if (mobileTile != null) {
              state.toggleTile('mobile_data');
            } else {
              SystemHardwareService.toggleMobileData();
            }
          },
          onRowTap: () {
            Navigator.of(context).pop();
            if (onDismissAndExecute != null) {
              onDismissAndExecute!(
                  () => SystemHardwareService.openMobileDataSettings());
            } else {
              SystemHardwareService.openMobileDataSettings();
            }
          },
        ),
        const SizedBox(height: 10),

        // 2. Wi-Fi Row Card
        _buildToggleRowCard(
          icon: wifiTile.isActive ? Icons.wifi_rounded : Icons.wifi_off_rounded,
          title: 'Wi-Fi',
          subtitle: wifiSub,
          isActive: wifiTile.isActive,
          onToggle: () {
            HapticFeedback.mediumImpact();
            state.toggleTile('wifi');
          },
          onRowTap: () {
            Navigator.of(context).pop();
            SystemHardwareService.openWifiSettings();
          },
        ),
        const SizedBox(height: 18),

        // Bottom Buttons: All Networks & Done
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
                SystemHardwareService.openWifiSettings();
              },
              icon: Icon(
                Icons.tune_rounded,
                size: 17,
                color: colors.activePill,
              ),
              label: Text(
                'All networks',
                style: font.textStyleBuilder(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.activePill,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.activePill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Done',
                  style: font.textStyleBuilder(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.onActivePill,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBluetoothContent(BuildContext context, ShadeStateProvider state) {
    final btTile = state.tiles.firstWhere(
      (t) => t.id == 'bluetooth',
      orElse: () => QsTileModel.defaultStandardTiles[1],
    );
    final btSub = (btTile.subtitle != null && btTile.subtitle!.isNotEmpty)
        ? btTile.subtitle!
        : (btTile.isActive ? 'On' : 'Off');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dialog Header
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: btTile.isActive ? colors.activePill : colors.inactivePill,
                shape: BoxShape.circle,
              ),
              child: Icon(
                btTile.isActive
                    ? Icons.bluetooth_connected_rounded
                    : Icons.bluetooth_disabled_rounded,
                size: 22,
                color: btTile.isActive
                    ? colors.onActivePill
                    : colors.onInactivePill,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bluetooth',
                    style: font.textStyleBuilder(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    btTile.isActive ? btSub : 'Bluetooth is turned off',
                    style: font.textStyleBuilder(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 1. Use Bluetooth Toggle Card
        _buildToggleRowCard(
          icon: Icons.bluetooth_rounded,
          title: 'Use Bluetooth',
          subtitle: btTile.isActive ? 'Visible to nearby devices' : 'Off',
          isActive: btTile.isActive,
          onToggle: () {
            HapticFeedback.mediumImpact();
            state.toggleTile('bluetooth');
          },
          onRowTap: () {
            HapticFeedback.mediumImpact();
            state.toggleTile('bluetooth');
          },
        ),
        const SizedBox(height: 10),

        // 2. Pair New Device / Connected Status Card
        InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
            SystemHardwareService.openBluetoothSettings();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.background.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.inactivePill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.headphones_rounded,
                    size: 19,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        btTile.isActive && btSub != 'On' && btSub != 'Off'
                            ? btSub
                            : 'Saved & Pair new device',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: font.textStyleBuilder(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to manage Bluetooth devices',
                        style: font.textStyleBuilder(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Bottom Buttons: Bluetooth Settings & Done
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
                SystemHardwareService.openBluetoothSettings();
              },
              icon: Icon(
                Icons.settings_bluetooth_rounded,
                size: 17,
                color: colors.activePill,
              ),
              label: Text(
                'More settings',
                style: font.textStyleBuilder(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.activePill,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.activePill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Done',
                  style: font.textStyleBuilder(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.onActivePill,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleRowCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    required VoidCallback onToggle,
    required VoidCallback onRowTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onRowTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? colors.activePill.withValues(alpha: 0.16)
              : colors.background.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive
                ? colors.activePill.withValues(alpha: 0.45)
                : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isActive ? colors.activePill : colors.inactivePill,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 19,
                color: isActive ? colors.onActivePill : colors.onInactivePill,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: font.textStyleBuilder(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: font.textStyleBuilder(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: isActive,
              onChanged: (_) => onToggle(),
              activeThumbColor: colors.onActivePill,
              activeTrackColor: colors.activePill,
              inactiveThumbColor: colors.textSecondary,
              inactiveTrackColor: colors.inactivePill,
            ),
          ],
        ),
      ),
    );
  }
}
