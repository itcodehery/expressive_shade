import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_dock_item.dart';
import '../../models/font_config.dart';
import '../../models/media_player_style.dart';
import '../../models/notification_model.dart';
import '../../models/notification_style.dart';
import '../../models/qs_tile_model.dart';
import '../../models/shade_mode.dart';
import '../../models/slider_style.dart';
import '../../providers/shade_state_provider.dart';
import '../../services/system_apps_service.dart';
import '../../theme/m3_expressive_theme.dart';
import '../../features/notifications/notification_card.dart';
import '../../widgets/expressive_media_card.dart';
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
            padding: const EdgeInsets.only(bottom: 20),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => state.setShadeMode(mode),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.activePill.withValues(alpha: 0.12)
                      : colors.surface,
                  borderRadius: BorderRadius.circular(28),
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
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.activePill
                                : colors.inactivePill,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Icon(
                              mode == ShadeMode.split
                                  ? Icons.splitscreen_rounded
                                  : (mode == ShadeMode.smart
                                        ? Icons.grid_view_rounded
                                        : Icons.view_stream_rounded),
                              size: 24,
                              color: isSelected
                                  ? colors.onActivePill
                                  : colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mode.displayName,
                                style: state.selectedFont.textStyleBuilder(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                mode.description,
                                style: state.selectedFont.textStyleBuilder(
                                  fontSize: 12.5,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? colors.activePill
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? colors.activePill
                                  : colors.textSecondary.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 7,
                                    height: 7,
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
                    const SizedBox(height: 14),
                    // Live UI architecture mockup preview
                    _buildShadeModePreview(
                      mode,
                      colors,
                      state.selectedFont,
                      isSelected,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        if (state.shadeMode == ShadeMode.split) ...[
          const SizedBox(height: 12),
          _buildAppDockSection(context, state, colors),
        ],
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
                  color: isSelected
                      ? colors.activePill.withValues(alpha: 0.15)
                      : colors.surface,
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
                            color: isSelected
                                ? colors.activePill
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? colors.activePill
                                  : colors.textSecondary.withValues(alpha: 0.5),
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
          subtitle:
              'Combined Wi-Fi & Mobile Data in a single expandable 1x2 pill.',
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
          subtitle:
              'Individual tiles for Wi-Fi and Mobile Data with direct one-tap toggles.',
          icon: Icons.signal_cellular_alt_rounded,
          isSelected: state.networkTileStyle == NetworkTileStyle.separate,
          colors: colors,
          font: state.selectedFont,
          onTap: () {
            HapticFeedback.lightImpact();
            state.setNetworkTileStyle(NetworkTileStyle.separate);
          },
        ),
        const SizedBox(height: 28),

        Text(
          'Media Player Layout Style',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose from 5 distinct expressive media card styles for your Quick Settings shade.',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        ...MediaPlayerStyle.values.map((style) {
          final isSelected = state.mediaPlayerStyle == style;
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () {
                HapticFeedback.selectionClick();
                state.setMediaPlayerStyle(style);
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.activePill.withValues(alpha: 0.12)
                      : colors.surface,
                  borderRadius: BorderRadius.circular(28),
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
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.activePill
                                : colors.inactivePill,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.play_circle_filled_rounded,
                              size: 24,
                              color: isSelected
                                  ? colors.onActivePill
                                  : colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                style.displayName,
                                style: state.selectedFont.textStyleBuilder(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                style.description,
                                style: state.selectedFont.textStyleBuilder(
                                  fontSize: 12.5,
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
                            color: isSelected
                                ? colors.activePill
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? colors.activePill
                                  : colors.textSecondary.withValues(alpha: 0.5),
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
                    const SizedBox(height: 14),
                    // Live preview of the card style
                    IgnorePointer(
                      child: ExpressiveMediaCard(
                        title: 'Blinding Lights',
                        artist: 'The Weeknd',
                        appSource: 'Spotify',
                        isPlaying: true,
                        progress: 0.45,
                        colors: colors,
                        font: state.selectedFont,
                        style: style,
                        onPlayPause: () {},
                        onProgressChanged: (_) {},
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
          'Notification Card Style',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Customize your notification appearance: Android 17 Expressive, iOS Notification Center, Samsung OneUI Stadium, Compact Mode (swipe right for actions), or HyperOS Floating Pill.',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        ...NotificationStyle.values.map((style) {
          final isSelected = state.notificationStyle == style;
          final sampleNotif = NotificationModel(
            id: 'preview_${style.name}',
            packageName: 'com.google.android.apps.messaging',
            appName: 'Messages',
            title: 'Tim Cook',
            content: 'Hey! Look at this notification styling preview. It looks clean and tactile!',
            timeAgo: '2m ago',
            appIcon: Icons.chat_bubble_rounded,
            appColor: const Color(0xFF2563EB),
            actions: const [
              NotificationAction(index: 0, title: 'Reply', hasRemoteInput: true),
              NotificationAction(index: 1, title: 'Mark as read', hasRemoteInput: false),
            ],
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () {
                HapticFeedback.selectionClick();
                state.setNotificationStyle(style);
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.activePill.withValues(alpha: 0.12)
                      : colors.surface,
                  borderRadius: BorderRadius.circular(28),
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
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.activePill
                                : colors.inactivePill,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.notifications_active_rounded,
                              size: 24,
                              color: isSelected
                                  ? colors.onActivePill
                                  : colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                style.displayName,
                                style: state.selectedFont.textStyleBuilder(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                style.description,
                                style: state.selectedFont.textStyleBuilder(
                                  fontSize: 12.5,
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
                            color: isSelected
                                ? colors.activePill
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? colors.activePill
                                  : colors.textSecondary.withValues(alpha: 0.5),
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
                    const SizedBox(height: 14),
                    // Live realistic preview of this notification style
                    IgnorePointer(
                      child: NotificationCard(
                        notification: sampleNotif,
                        colors: colors,
                        font: state.selectedFont,
                        style: style,
                        onDismiss: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
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
          color: isSelected
              ? colors.activePill.withValues(alpha: 0.15)
              : colors.surface,
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
                  color: isSelected
                      ? colors.activePill
                      : colors.textSecondary.withValues(alpha: 0.5),
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

  Widget _buildShadeModePreview(
    ShadeMode mode,
    ExpressiveThemeColors colors,
    FontConfig font,
    bool isSelected,
  ) {
    return Container(
      height: 104,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? colors.activePill.withValues(alpha: 0.35)
              : colors.inactivePill.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: switch (mode) {
        ShadeMode.split => _buildSplitPreview(colors, font),
        ShadeMode.unified => _buildUnifiedPreview(colors, font),
        ShadeMode.smart => _buildMatrixPreview(colors, font),
      },
    );
  }

  Widget _buildSplitPreview(ExpressiveThemeColors colors, FontConfig font) {
    return Column(
      children: [
        // Top tab switcher
        Container(
          height: 20,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
                decoration: BoxDecoration(
                  color: colors.activePill,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Alerts',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: colors.onActivePill,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Controls',
                style: TextStyle(fontSize: 9, color: colors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Mini split side-by-side
        Expanded(
          child: Row(
            children: [
              // Left panel: notifications
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.mail_outline_rounded,
                            size: 12,
                            color: colors.activePill,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color:
                                    colors.textPrimary.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 12,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color:
                                    colors.textSecondary.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right panel: toggles
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: colors.activePill,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(
                              Icons.wifi_rounded,
                              size: 12,
                              color: colors.onActivePill,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: colors.inactivePill,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(
                              Icons.bluetooth_rounded,
                              size: 12,
                              color: colors.onInactivePill,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.volume_up_rounded,
                            size: 11,
                            color: colors.activePill,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: colors.activePill,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedPreview(ExpressiveThemeColors colors, FontConfig font) {
    return Column(
      children: [
        // Top status line
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '10:00',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            Row(
              children: [
                Icon(Icons.wifi_rounded, size: 9, color: colors.textPrimary),
                const SizedBox(width: 3),
                Icon(
                  Icons.battery_full_rounded,
                  size: 9,
                  color: colors.activePill,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 5),
        // 4 toggles across
        Row(
          children: [
            Expanded(
              child: Container(
                height: 22,
                decoration: BoxDecoration(
                  color: colors.activePill,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.wifi_rounded,
                  size: 11,
                  color: colors.onActivePill,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 22,
                decoration: BoxDecoration(
                  color: colors.activePill,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.bluetooth_rounded,
                  size: 11,
                  color: colors.onActivePill,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 22,
                decoration: BoxDecoration(
                  color: colors.inactivePill,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.flashlight_on_rounded,
                  size: 11,
                  color: colors.onInactivePill,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 22,
                decoration: BoxDecoration(
                  color: colors.inactivePill,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.do_not_disturb_on_rounded,
                  size: 11,
                  color: colors.onInactivePill,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Unified notification card below
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.9),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active_rounded,
                  size: 12,
                  color: colors.activePill,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 4.5,
                        width: 70,
                        decoration: BoxDecoration(
                          color: colors.textPrimary,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                      const SizedBox(height: 2.5),
                      Container(
                        height: 3.5,
                        width: 110,
                        decoration: BoxDecoration(
                          color: colors.textSecondary.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatrixPreview(ExpressiveThemeColors colors, FontConfig font) {
    return Column(
      children: [
        // Top chips: time & battery
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '3:28 pm • 12/04',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: colors.activePill,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.battery_charging_full_rounded,
                    size: 9,
                    color: colors.activePill,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '20%',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Capsule brightness bar
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: colors.inactivePill,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            Container(
              width: 44,
              height: 14,
              decoration: BoxDecoration(
                color: colors.activePill,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(
                Icons.wb_sunny_rounded,
                size: 9,
                color: colors.onActivePill,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // 3-column tiles
        Row(
          children: [
            Expanded(
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: colors.activePill,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  Icons.wifi_rounded,
                  size: 11,
                  color: colors.onActivePill,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: colors.activePill,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  Icons.signal_cellular_alt_rounded,
                  size: 11,
                  color: colors.onActivePill,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: colors.inactivePill,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  Icons.bluetooth_rounded,
                  size: 11,
                  color: colors.onInactivePill,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Mini notification with right vertical accent strip
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.call_missed_rounded,
                  size: 11,
                  color: colors.activePill,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: colors.textPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colors.activePill,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppDockSection(
    BuildContext context,
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: state.appDockEnabled
              ? colors.activePill.withValues(alpha: 0.5)
              : colors.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
          width: state.appDockEnabled ? 2.0 : 1.0,
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
                  color: state.appDockEnabled
                      ? colors.activePill
                      : colors.inactivePill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    Icons.apps_rounded,
                    size: 24,
                    color: state.appDockEnabled
                        ? colors.onActivePill
                        : colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Split Shade App Dock',
                          style: state.selectedFont.textStyleBuilder(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.activePill.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'NEW',
                            style: state.selectedFont.textStyleBuilder(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: colors.activePill,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Pin up to 8 apps below notifications for rapid access.',
                      style: state.selectedFont.textStyleBuilder(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: state.appDockEnabled,
                activeTrackColor: colors.activePill,
                activeThumbColor: colors.onActivePill,
                onChanged: (enabled) {
                  HapticFeedback.lightImpact();
                  state.setAppDockEnabled(enabled);
                },
              ),
            ],
          ),
          if (state.appDockEnabled) ...[
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Live Preview of the App Dock
            Text(
              'Dock Appearance Preview',
              style: state.selectedFont.textStyleBuilder(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _buildAppDockPreview(context, state, colors),
            const SizedBox(height: 20),

            // Selected Apps Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pinned Applications (${state.appDockApps.length}/8)',
                  style: state.selectedFont.textStyleBuilder(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                if (state.appDockApps.length < 8)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openAppPicker(context, state, colors),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_circle_rounded,
                            size: 16,
                            color: colors.activePill,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add App',
                            style: state.selectedFont.textStyleBuilder(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.activePill,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (state.appDockApps.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.background.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colors.textSecondary.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 32,
                      color: colors.textSecondary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No apps in dock yet',
                      style: state.selectedFont.textStyleBuilder(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "Add App" to pick applications from your phone and choose unique Quick Settings tile colors.',
                      textAlign: TextAlign.center,
                      style: state.selectedFont.textStyleBuilder(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.activePill,
                        foregroundColor: colors.onActivePill,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add First App'),
                      onPressed: () => _openAppPicker(context, state, colors),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  for (final app in state.appDockApps) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors.background.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colors.textSecondary.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          _AppIconWidget(
                            packageName: app.packageName,
                            appName: app.appName,
                            fallbackIcon: Icons.apps_rounded,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.appName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: state.selectedFont.textStyleBuilder(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  app.packageName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: state.selectedFont.textStyleBuilder(
                                    fontSize: 11,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Color swatch button
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openColorPicker(
                              context,
                              state,
                              colors,
                              app,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: app.color.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: app.color,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: app.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.color_lens_rounded,
                                    size: 14,
                                    color: app.color,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Delete button
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                            ),
                            color: Colors.redAccent.withValues(alpha: 0.8),
                            splashRadius: 20,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              state.removeAppDockItem(app.packageName);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppDockPreview(
    BuildContext context,
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    if (state.appDockApps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: colors.isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Center(
          child: Text(
            'Empty Dock (Add apps below to preview)',
            style: state.selectedFont.textStyleBuilder(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    final rows = <List<AppDockItem>>[];
    for (int i = 0; i < state.appDockApps.length; i += 4) {
      final end = (i + 4 < state.appDockApps.length)
          ? i + 4
          : state.appDockApps.length;
      rows.add(state.appDockApps.sublist(i, end));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int r = 0; r < rows.length; r++) ...[
            if (r > 0) const SizedBox(height: 10),
            Row(
              children: [
                for (int c = 0; c < rows[r].length; c++) ...[
                  if (c > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: rows[r][c].color,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: rows[r][c].color.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _AppIconWidget(
                              packageName: rows[r][c].packageName,
                              appName: rows[r][c].appName,
                              fallbackIcon: Icons.apps_rounded,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rows[r][c].appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: state.selectedFont.textStyleBuilder(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (rows[r].length < 4)
                  for (int s = 0; s < 4 - rows[r].length; s++) ...[
                    const SizedBox(width: 8),
                    const Spacer(),
                  ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _openAppPicker(
    BuildContext context,
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AppPickerBottomSheet(
        state: state,
        colors: colors,
        onAppSelected: (appInfo) {
          Navigator.pop(sheetContext);
          _openColorPicker(
            context,
            state,
            colors,
            AppDockItem(
              packageName: appInfo.packageName,
              appName: appInfo.appName,
              colorValue: _suggestedColors[state.appDockApps.length %
                  _suggestedColors.length],
            ),
            isNew: true,
          );
        },
      ),
    );
  }

  void _openColorPicker(
    BuildContext context,
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
    AppDockItem item, {
    bool isNew = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _TileColorPickerBottomSheet(
        state: state,
        colors: colors,
        initialItem: item,
        isNew: isNew,
      ),
    );
  }

  static const List<int> _suggestedColors = [
    0xFF1E88E5, // Cobalt Blue
    0xFF00897B, // Emerald Teal
    0xFFFF5722, // Flame Orange
    0xFF7E57C2, // Lavender Violet
    0xFFE53935, // Crimson Red
    0xFFFFB300, // Sunset Gold
    0xFF00ACC1, // Electric Teal
    0xFFD81B60, // Hot Magenta
    0xFF2E7D32, // Mint Green
    0xFF3949AB, // Royal Indigo
    0xFF8E24AA, // Orchid Purple
    0xFF546E7A, // Slate Steel
    0xFF880E4F, // Deep Maroon
    0xFF0288D1, // Cyan Sky
    0xFF263238, // Dark Charcoal
    0xFF6D4C41, // Mocha Bronze
  ];
}

class _AppPickerBottomSheet extends StatefulWidget {
  final ShadeStateProvider state;
  final ExpressiveThemeColors colors;
  final ValueChanged<InstalledAppInfo> onAppSelected;

  const _AppPickerBottomSheet({
    required this.state,
    required this.colors,
    required this.onAppSelected,
  });

  @override
  State<_AppPickerBottomSheet> createState() => _AppPickerBottomSheetState();
}

class _AppPickerBottomSheetState extends State<_AppPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<InstalledAppInfo> _allApps = [];
  List<InstalledAppInfo> _filteredApps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await SystemAppsService.getInstalledApps();
    final dockedPackages =
        widget.state.appDockApps.map((a) => a.packageName).toSet();
    final available =
        apps.where((a) => !dockedPackages.contains(a.packageName)).toList();

    if (mounted) {
      setState(() {
        _allApps = available;
        _filteredApps = available;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredApps = _allApps;
      } else {
        _filteredApps = _allApps
            .where(
              (a) =>
                  a.appName.toLowerCase().contains(q) ||
                  a.packageName.toLowerCase().contains(q),
            )
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final font = widget.state.selectedFont;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: colors.isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.apps_rounded, color: colors.activePill, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Select App for Dock',
                  style: font.textStyleBuilder(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.state.appDockApps.length}/8',
                  style: font.textStyleBuilder(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.activePill,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: font.textStyleBuilder(
                fontSize: 14,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search installed apps...',
                hintStyle: font.textStyleBuilder(
                  fontSize: 14,
                  color: colors.textSecondary.withValues(alpha: 0.6),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colors.textSecondary,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredApps.isEmpty
                    ? Center(
                        child: Text(
                          'No applications found',
                          style: font.textStyleBuilder(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredApps.length,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        itemBuilder: (context, index) {
                          final app = _filteredApps[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            leading: _AppIconWidget(
                              packageName: app.packageName,
                              appName: app.appName,
                              size: 40,
                            ),
                            title: Text(
                              app.appName,
                              style: font.textStyleBuilder(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              app.packageName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: font.textStyleBuilder(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: colors.textSecondary,
                            ),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              widget.onAppSelected(app);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _TileColorPickerBottomSheet extends StatefulWidget {
  final ShadeStateProvider state;
  final ExpressiveThemeColors colors;
  final AppDockItem initialItem;
  final bool isNew;

  const _TileColorPickerBottomSheet({
    required this.state,
    required this.colors,
    required this.initialItem,
    required this.isNew,
  });

  @override
  State<_TileColorPickerBottomSheet> createState() =>
      _TileColorPickerBottomSheetState();
}

class _TileColorPickerBottomSheetState
    extends State<_TileColorPickerBottomSheet> {
  late int _selectedColorValue;

  @override
  void initState() {
    super.initState();
    _selectedColorValue = widget.initialItem.colorValue;
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final font = widget.state.selectedFont;
    final activeColor = Color(_selectedColorValue);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: colors.isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.palette_rounded, color: activeColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Choose Tile Color: ${widget.initialItem.appName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: font.textStyleBuilder(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Live Quick Settings Squircle Tile Preview
          Container(
            width: 80,
            height: 72,
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.40),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: _AppIconWidget(
                packageName: widget.initialItem.packageName,
                appName: widget.initialItem.appName,
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.initialItem.appName,
            style: font.textStyleBuilder(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 22),

          // 16 Vibrant Color Palettes Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: LayoutTab._suggestedColors.map((colorVal) {
              final isChosen = colorVal == _selectedColorValue;
              final col = Color(colorVal);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedColorValue = colorVal);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: col,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isChosen ? Colors.white : Colors.transparent,
                      width: isChosen ? 3.0 : 0.0,
                    ),
                    boxShadow: [
                      if (isChosen)
                        BoxShadow(
                          color: col.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: isChosen
                      ? const Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 26),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                foregroundColor:
                    ThemeData.estimateBrightnessForColor(activeColor) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 4,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                if (widget.isNew) {
                  widget.state.addAppDockItem(
                    widget.initialItem.copyWith(
                      colorValue: _selectedColorValue,
                    ),
                  );
                } else {
                  widget.state.updateAppDockItemColor(
                    widget.initialItem.packageName,
                    _selectedColorValue,
                  );
                }
                Navigator.pop(context);
              },
              child: Text(
                widget.isNew ? 'Add to Dock' : 'Save Tile Color',
                style: font.textStyleBuilder(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ThemeData.estimateBrightnessForColor(activeColor) ==
                          Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppIconWidget extends StatefulWidget {
  final String packageName;
  final String appName;
  final IconData? fallbackIcon;
  final double size;

  const _AppIconWidget({
    required this.packageName,
    this.appName = '',
    this.fallbackIcon,
    this.size = 28,
  });

  @override
  State<_AppIconWidget> createState() => _AppIconWidgetState();
}

class _AppIconWidgetState extends State<_AppIconWidget> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await SystemAppsService.getAppIcon(widget.packageName);
    if (mounted && bytes != null && bytes.isNotEmpty) {
      setState(() => _bytes = bytes);
    }
  }

  @override
  void didUpdateWidget(covariant _AppIconWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packageName != widget.packageName) {
      _load();
    }
  }

  IconData _resolveIcon() {
    if (widget.fallbackIcon != null) return widget.fallbackIcon!;
    final p = widget.packageName.toLowerCase();
    final n = widget.appName.toLowerCase();
    if (p.contains('camera') || n.contains('camera')) return Icons.camera_alt_rounded;
    if (p.contains('dialer') || p.contains('phone') || n.contains('phone') || n.contains('call')) {
      return Icons.phone_rounded;
    }
    if (p.contains('message') || p.contains('sms') || n.contains('message') || n.contains('chat')) {
      return Icons.chat_bubble_rounded;
    }
    if (p.contains('chrome') || p.contains('browser') || n.contains('browser') || n.contains('web')) {
      return Icons.language_rounded;
    }
    if (p.contains('music') || p.contains('spotify') || n.contains('music') || n.contains('audio')) {
      return Icons.music_note_rounded;
    }
    if (p.contains('gallery') || p.contains('photo') || n.contains('photo') || n.contains('image')) {
      return Icons.photo_library_rounded;
    }
    if (p.contains('clock') || p.contains('alarm') || n.contains('clock') || n.contains('alarm')) {
      return Icons.access_time_rounded;
    }
    if (p.contains('settings') || n.contains('settings')) return Icons.settings_rounded;
    if (p.contains('mail') || p.contains('gmail') || n.contains('mail')) return Icons.mail_rounded;
    if (p.contains('map') || n.contains('map')) return Icons.map_rounded;
    if (p.contains('calc') || n.contains('calc')) return Icons.calculate_rounded;
    if (p.contains('calendar') || n.contains('calendar')) return Icons.calendar_month_rounded;
    if (p.contains('video') || p.contains('youtube') || n.contains('video') || n.contains('youtube')) {
      return Icons.play_arrow_rounded;
    }
    return Icons.apps_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.size * 0.28),
        child: Image.memory(
          _bytes!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      );
    }
    return Icon(
      _resolveIcon(),
      size: widget.size,
      color: Colors.white70,
    );
  }
}
