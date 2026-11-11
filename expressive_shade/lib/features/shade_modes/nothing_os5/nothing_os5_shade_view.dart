import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/font_config.dart';
import '../../../models/media_player_style.dart';
import '../../../models/notification_model.dart';
import '../../../models/notification_style.dart';
import '../../../models/qs_tile_model.dart';
import '../../../theme/m3_expressive_theme.dart';
import '../../../widgets/expressive_media_card.dart';
import '../../notifications/notification_list.dart';
import '../../lyrics/widgets/inline_lyrics_view.dart';
import 'bento_grid_packer.dart';
import 'widgets/nothing_os5_header.dart';
import 'widgets/nothing_os5_media_cards.dart';
import 'widgets/nothing_os5_sliders.dart';
import 'widgets/nothing_os5_tile.dart';

class NothingOs5ShadeView extends StatelessWidget {
  final PageController pageController;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final List<QsTileModel> tiles;
  final double brightness;
  final double volume;
  final int ringerMode;
  final int batteryLevel;
  final bool isCharging;
  final String carrierName;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<int> onRingerModeChanged;
  final ValueChanged<String> onToggleTile;
  final ValueChanged<String> onLongPressTile;
  final ValueChanged<String> onResizeTile;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onEditTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onPowerTap;
  final VoidCallback onOpenHistory;
  final VoidCallback onClearAllNotifications;

  // Media
  final String mediaTitle;
  final String mediaArtist;
  final String mediaApp;
  final bool isPlaying;
  final double mediaProgress;
  final dynamic mediaArtwork;
  final MediaPlayerStyle mediaPlayerStyle;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipNext;
  final VoidCallback onSkipPrevious;
  final ValueChanged<double> onProgressChanged;

  // Notifications
  final List<NotificationModel> notifications;
  final NotificationStyle notificationStyle;
  final ValueChanged<String> onDismissNotification;
  final void Function(NotificationModel, NotificationAction)? onActionTap;
  final void Function(NotificationModel, NotificationAction, String)? onReply;
  final void Function(NotificationModel)? onOpenNotification;
  final void Function(NotificationModel)? onSnoozeNotification;

  const NothingOs5ShadeView({
    super.key,
    required this.pageController,
    required this.colors,
    required this.font,
    required this.tiles,
    required this.brightness,
    required this.volume,
    required this.ringerMode,
    required this.batteryLevel,
    required this.isCharging,
    required this.carrierName,
    required this.onBrightnessChanged,
    required this.onVolumeChanged,
    required this.onRingerModeChanged,
    required this.onToggleTile,
    required this.onLongPressTile,
    required this.onResizeTile,
    required this.onPageChanged,
    required this.onEditTap,
    required this.onSettingsTap,
    required this.onPowerTap,
    required this.onOpenHistory,
    required this.onClearAllNotifications,
    required this.mediaTitle,
    required this.mediaArtist,
    required this.mediaApp,
    required this.isPlaying,
    required this.mediaProgress,
    this.mediaArtwork,
    this.mediaPlayerStyle = MediaPlayerStyle.expressiveWave,
    required this.onPlayPause,
    required this.onSkipNext,
    required this.onSkipPrevious,
    required this.onProgressChanged,
    required this.notifications,
    this.notificationStyle = NotificationStyle.android17,
    required this.onDismissNotification,
    this.onActionTap,
    this.onReply,
    this.onOpenNotification,
    this.onSnoozeNotification,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final topInset = topPadding > 0 ? topPadding + 8.0 : 16.0;

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          // Shared Top Status Header (Time, Date, Battery & Carrier stay stationary across both panes)
          Padding(
            padding: EdgeInsets.fromLTRB(18, topInset, 18, 12),
            child: NothingOs5StatusHeader(
              font: font,
              colors: colors,
              batteryLevel: batteryLevel,
              isCharging: isCharging,
              carrierName: carrierName,
            ),
          ),

          // Swipeable Split Panes below the shared header
          Expanded(
            child: PageView(
              controller: pageController,
              onPageChanged: onPageChanged,
              children: [
                // Page 0: Left Pane — NothingOS 5 Notifications Sheet
                _buildNotificationsPane(context),

                // Page 1: Right Pane — NothingOS 5 Bento Control Center
                _buildControlCenterPane(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsPane(BuildContext context) {
    final pillBtnBg = colors.isDark
        ? colors.surface.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.85);

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
              children: [
                // 1. Media Player Card (Respects selected MediaPlayerStyle)
                ExpressiveMediaCard(
                  title: mediaTitle,
                  artist: mediaArtist,
                  appSource: mediaApp,
                  isPlaying: isPlaying,
                  progress: mediaProgress,
                  artwork: mediaArtwork,
                  colors: colors,
                  font: font,
                  style: mediaPlayerStyle,
                  onPlayPause: onPlayPause,
                  onSkipNext: onSkipNext,
                  onSkipPrevious: onSkipPrevious,
                  onProgressChanged: onProgressChanged,
                ),
                InlineLyricsView(
                  colors: colors,
                  font: font,
                ),
                const SizedBox(height: 20),

                // 3. Section Header ("Silent" / "Notifications" + "x" button)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notifications.isEmpty ? 'Silent' : 'Notifications',
                        style: font.textStyleBuilder(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                      if (notifications.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onClearAllNotifications();
                          },
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 4. Notifications List
                NotificationList(
                  notifications: notifications,
                  colors: colors,
                  font: font,
                  style: notificationStyle,
                  onDismiss: onDismissNotification,
                  onActionTap: onActionTap,
                  onReply: onReply,
                  onTap: onOpenNotification,
                  onSnooze: onSnoozeNotification,
                ),
              ],
            ),
          ),

          // 5. Bottom Pill Action Bar (History, Notification Settings, Clear All)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            child: Row(
              children: [
                // History Pill Button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onOpenHistory();
                  },
                  child: Container(
                    width: 56,
                    height: 38,
                    decoration: BoxDecoration(
                      color: pillBtnBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.history_rounded,
                        size: 20,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Notification Settings Pill Button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSettingsTap();
                  },
                  child: Container(
                    width: 56,
                    height: 38,
                    decoration: BoxDecoration(
                      color: pillBtnBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 20,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Clear all Pill Button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onClearAllNotifications();
                  },
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: pillBtnBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        'Clear all',
                        style: font.textStyleBuilder(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlCenterPane(BuildContext context) {
    return Container(
      color: colors.background,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
        children: [
          // 1. NothingOS 5 Control Toolbar (Edit, Settings, Power)
          NothingOs5ControlToolbar(
            font: font,
            colors: colors,
            onEditTap: onEditTap,
            onSettingsTap: onSettingsTap,
            onPowerTap: onPowerTap,
          ),
          const SizedBox(height: 16),

          // 3. Compact Media Card
          NothingOs5CompactMediaCard(
            title: mediaTitle,
            artist: mediaArtist,
            isPlaying: isPlaying,
            artwork: mediaArtwork,
            font: font,
            colors: colors,
            onPlayPause: onPlayPause,
            onSkipNext: onSkipNext,
          ),
          InlineLyricsView(
            colors: colors,
            font: font,
          ),
          const SizedBox(height: 14),

          // 4. 4-Column Bento Grid (1x1, 1x2, 2x2 tiles + vertical sliders + ringer pill)
          _buildBentoGrid(),
        ],
      ),
    );
  }

  Widget _buildBentoGrid() {
    final packed = packNothingOs5BentoGrid(
      tiles,
      includeSystemControls: true,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 11.0;
        final double maxW = constraints.maxWidth;
        final double cellWidth = ((maxW - (3 * spacing)) / 4.0).clamp(50.0, 110.0);
        final double cellHeight = (cellWidth * 0.80).clamp(44.0, 68.0);
        final double totalHeight = packed.totalRows > 0
            ? (packed.totalRows * cellHeight) + ((packed.totalRows - 1) * spacing)
            : 0.0;

        return SizedBox(
          width: maxW,
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final item in packed.placements)
                AnimatedPositioned(
                  key: ValueKey('bento_${item.tile?.id ?? item.type.name}'),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: item.col * (cellWidth + spacing),
                  top: item.row * (cellHeight + spacing),
                  width: (item.colSpan * cellWidth) +
                      ((item.colSpan - 1) * spacing),
                  height: (item.rowSpan * cellHeight) +
                      ((item.rowSpan - 1) * spacing),
                  child: _buildBentoItem(item, spacing),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBentoItem(BentoPlacement item, double spacing) {
    switch (item.type) {
      case BentoItemType.volumeSlider:
        return NothingOs5VerticalCapsuleSlider(
          value: volume,
          onChanged: onVolumeChanged,
          icon: volume <= 0.01
              ? Icons.music_off_rounded
              : Icons.music_note_rounded,
          colors: colors,
          onLongPress: () => onLongPressTile('nothing_volume'),
        );
      case BentoItemType.brightnessSlider:
        return NothingOs5VerticalCapsuleSlider(
          value: brightness,
          onChanged: onBrightnessChanged,
          icon: Icons.wb_sunny_outlined,
          colors: colors,
          onLongPress: () => onLongPressTile('nothing_brightness'),
        );
      case BentoItemType.ringerPill:
        return NothingOs5RingerPill(
          ringerMode: ringerMode,
          onModeChanged: onRingerModeChanged,
          colors: colors,
          onLongPress: () => onLongPressTile('nothing_ringer'),
        );
      case BentoItemType.tile:
        final tile = item.tile!;
        return NothingOs5Tile(
          tile: tile,
          colors: colors,
          font: font,
          onTap: () => onToggleTile(tile.id),
          onLongPress: () => onLongPressTile(tile.id),
          onResizeTap: () => onResizeTile(tile.id),
        );
    }
  }
}
