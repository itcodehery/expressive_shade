import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/font_config.dart';
import '../../models/media_player_style.dart';
import '../../models/notification_model.dart';
import '../../models/notification_style.dart';
import '../../models/qs_tile_model.dart';
import '../../models/shade_mode.dart';
import '../../models/slider_style.dart';
import '../../providers/shade_state_provider.dart';
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
                              switch (mode) {
                                ShadeMode.split => Icons.splitscreen_rounded,
                                ShadeMode.smart => Icons.grid_view_rounded,
                                ShadeMode.nothingOs5 =>
                                  Icons.dashboard_customize_rounded,
                                ShadeMode.unified => Icons.view_stream_rounded,
                              },
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
        ShadeMode.nothingOs5 => _buildNothingOs5Preview(colors, font),
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

  Widget _buildNothingOs5Preview(ExpressiveThemeColors colors, FontConfig font) {
    return Row(
      children: [
        // Left pane: Hero Media + Notification card + Bottom pill bar
        Expanded(
          child: Column(
            children: [
              // Hero media box
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2028),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.music_note_rounded,
                      size: 10,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 16,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE1FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              // Notification card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors.activePill,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.textPrimary.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Bottom pills
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(
                    width: 14,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 24,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Right pane: Compact media + 1x2 pills + 1x1 circles + 2x2 vertical sliders
        Expanded(
          child: Column(
            children: [
              // Compact media
              Container(
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors.activePill,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: colors.textPrimary.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.pause_rounded,
                      size: 10,
                      color: colors.textPrimary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              // Row of two 1x2 pills
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors.activePill,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors.activePill,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // Bento bottom area: 2x2 & 1x1 on left, vertical sliders on right
              Expanded(
                child: Row(
                  children: [
                    // 2x2 Bento square
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.inactivePill,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Center(
                          child: Text(
                            '2×2',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: colors.onInactivePill,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Two vertical sliders
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: colors.activePill.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: colors.activePill,
                                borderRadius: BorderRadius.circular(99),
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
}
