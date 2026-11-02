import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/font_config.dart';
import '../../../../models/media_player_style.dart';
import '../../../../models/notification_model.dart';
import '../../../../models/qs_tile_model.dart';
import '../../../../models/slider_style.dart';
import '../../../../theme/m3_expressive_theme.dart';
import '../../../../widgets/expressive_media_card.dart';
import '../../../../widgets/expressive_pill.dart';
import '../../../../widgets/expressive_slider.dart';
import '../../notifications/notification_list.dart';
import '../common/shade_tiles_grid.dart';

class SplitShadeView extends StatelessWidget {
  final PageController pageController;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final List<QsTileModel> tiles;
  final double brightness;
  final double volume;
  final SliderStyle sliderStyle;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<String> onToggleTile;
  final ValueChanged<String> onLongPressTile;
  final ValueChanged<String> onResizeTile;
  final ValueNotifier<TileImpulse?>? impulseNotifier;
  final ValueChanged<int> onPageChanged;

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
  final ValueChanged<String> onDismissNotification;
  final void Function(NotificationModel, NotificationAction)? onActionTap;
  final void Function(NotificationModel, NotificationAction, String)? onReply;
  final void Function(NotificationModel)? onOpenNotification;
  final void Function(NotificationModel)? onSnoozeNotification;

  const SplitShadeView({
    super.key,
    required this.pageController,
    required this.colors,
    required this.font,
    required this.tiles,
    required this.brightness,
    required this.volume,
    required this.sliderStyle,
    required this.onBrightnessChanged,
    required this.onVolumeChanged,
    required this.onToggleTile,
    required this.onLongPressTile,
    required this.onResizeTile,
    required this.impulseNotifier,
    required this.onPageChanged,
    required this.mediaTitle,
    required this.mediaArtist,
    required this.mediaApp,
    required this.isPlaying,
    required this.mediaProgress,
    this.mediaArtwork,
    required this.mediaPlayerStyle,
    required this.onPlayPause,
    required this.onSkipNext,
    required this.onSkipPrevious,
    required this.onProgressChanged,
    required this.notifications,
    required this.onDismissNotification,
    this.onActionTap,
    this.onReply,
    this.onOpenNotification,
    this.onSnoozeNotification,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Expanded(
          child: PageView(
            controller: pageController,
            onPageChanged: onPageChanged,
            children: [
              // Page 0: Dedicated Notifications Sheet
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  NotificationList(
                    notifications: notifications,
                    colors: colors,
                    font: font,
                    onDismiss: onDismissNotification,
                    onActionTap: onActionTap,
                    onReply: onReply,
                    onTap: onOpenNotification,
                    onSnooze: onSnoozeNotification,
                  ),
                ],
              ),

              // Page 1: Control Center Panel
              ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  // Brightness Slider
                  ExpressiveSlider(
                    value: brightness,
                    onChanged: onBrightnessChanged,
                    leadingIcon: Icons.wb_sunny_rounded,
                    trailingIcon: Icons.auto_mode_rounded,
                    onTrailingTap: () => HapticFeedback.lightImpact(),
                    colors: colors,
                    style: sliderStyle,
                  ),
                  const SizedBox(height: 10),

                  // Volume Slider
                  ExpressiveSlider(
                    value: volume,
                    onChanged: onVolumeChanged,
                    leadingIcon: volume == 0
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    trailingIcon: Icons.more_vert_rounded,
                    onTrailingTap: () => HapticFeedback.lightImpact(),
                    colors: colors,
                    style: sliderStyle,
                  ),
                  const SizedBox(height: 16),

                  // Tiles Grid
                  _buildDynamicTilesGrid(),
                  const SizedBox(height: 24),

                  // Media Card
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
                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicTilesGrid() {
    final rows = packTilesIntoRows(tiles);

    if (rows.length <= 5) {
      return _buildTilesGridPage(rows, 0);
    }

    final List<List<List<QsTileModel>>> pages = [];
    for (int i = 0; i < rows.length; i += 5) {
      final end = (i + 5 < rows.length) ? i + 5 : rows.length;
      pages.add(rows.sublist(i, end));
    }

    const double fixedHeight = (5 * 68.0) + (4 * 12.0);

    return PaginatedTilesContainer(
      colors: colors,
      pages: pages,
      fixedHeight: fixedHeight,
      builder: (context, pageIndex) {
        return _buildTilesGridPage(pages[pageIndex], pageIndex * 5);
      },
    );
  }

  Widget _buildTilesGridPage(List<List<QsTileModel>> rows, int baseRowIndex) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 12),
          Row(
            children: [
              for (int t = 0; t < rows[r].length; t++) ...[
                if (t > 0) const SizedBox(width: 10),
                Expanded(
                  flex: rows[r][t].isWide ? 2 : 1,
                  child: ExpressivePill(
                    tile: rows[r][t],
                    colors: colors,
                    font: font,
                    row: baseRowIndex + r,
                    col: t,
                    impulseNotifier: impulseNotifier,
                    onResizeTap: () => onResizeTile(rows[r][t].id),
                    onTap: () => onToggleTile(rows[r][t].id),
                    onLongPress: () => onLongPressTile(rows[r][t].id),
                  ),
                ),
              ],
              if (rowSpan(rows[r]) < 4) Spacer(flex: 4 - rowSpan(rows[r])),
            ],
          ),
        ],
      ],
    );
  }
}
