import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/font_config.dart';
import '../../../../models/media_player_style.dart';
import '../../../../models/notification_model.dart';
import '../../../../models/notification_style.dart';
import '../../../../models/qs_tile_model.dart';
import '../../../../models/slider_style.dart';
import '../../../../theme/m3_expressive_theme.dart';
import '../../../../widgets/expressive_media_card.dart';
import '../../../../widgets/expressive_pill.dart';
import '../../../../widgets/expressive_slider.dart';
import '../../notifications/notification_list.dart';
import '../../lyrics/widgets/inline_lyrics_view.dart';
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
  final NotificationStyle notificationStyle;
  final ValueChanged<String> onDismissNotification;
  final VoidCallback? onClearAllNotifications;
  final VoidCallback? onOpenHistory;
  final ValueChanged<NotificationStyle>? onNotificationStyleChanged;
  final VoidCallback? onOpenNotificationSettings;
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
    this.notificationStyle = NotificationStyle.android17,
    required this.onDismissNotification,
    this.onClearAllNotifications,
    this.onOpenHistory,
    this.onNotificationStyleChanged,
    this.onOpenNotificationSettings,
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
              // Page 0: Dedicated Notifications Sheet (Follows theme with darker background and curved bottom corners)
              Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: _buildNotificationsContainer(context),
                ),
              ),

              // Page 1: Control Center Panel
              Container(
                color: Colors.transparent,
                child: ListView(
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
                  InlineLyricsView(
                    colors: colors,
                    font: font,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicTilesGrid() {
    final pages = packTilesIntoBentoPages(tiles, maxCols: 4, maxRowsPerPage: 5);
    if (pages.isEmpty) return const SizedBox.shrink();

    if (pages.length == 1) {
      return _buildBentoTilesPage(pages.first, 0);
    }

    const double fixedHeight = (5 * 68.0) + (4 * 12.0) + 2.0;

    return PaginatedTilesContainer(
      colors: colors,
      pageCount: pages.length,
      fixedHeight: fixedHeight,
      builder: (context, pageIndex) {
        return _buildBentoTilesPage(pages[pageIndex], pageIndex * 5);
      },
    );
  }

  Widget _buildBentoTilesPage(StandardBentoPage page, int baseRowIndex) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double colSpacing = 10.0;
        const double rowSpacing = 12.0;
        const double rowHeight = 68.0;
        final double maxW = constraints.maxWidth;
        final double cellWidth = (maxW - (3 * colSpacing)) / 4.0;
        final int rowsCount = page.totalRows.clamp(1, 5);
        final double totalH =
            (rowsCount * rowHeight) + ((rowsCount - 1) * rowSpacing);

        return SizedBox(
          width: maxW,
          height: totalH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final p in page.placements)
                Positioned(
                  key: ValueKey('split_tile_${p.tile.id}'),
                  left: p.col * (cellWidth + colSpacing),
                  top: p.row * (rowHeight + rowSpacing),
                  width: (p.colSpan * cellWidth) +
                      ((p.colSpan - 1) * colSpacing),
                  height: (p.rowSpan * rowHeight) +
                      ((p.rowSpan - 1) * rowSpacing),
                  child: ExpressivePill(
                    tile: p.tile,
                    colors: colors,
                    font: font,
                    row: baseRowIndex + p.row,
                    col: p.col,
                    impulseNotifier: impulseNotifier,
                    onResizeTap: () => onResizeTile(p.tile.id),
                    onTap: () => onToggleTile(p.tile.id),
                    onLongPress: () => onLongPressTile(p.tile.id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationsContainer(BuildContext context) {
    final containerBg = colors.notificationContainerBackground;
    final pillBtnBg = colors.notificationCardBackground;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          const SizedBox(height: 6),

          // Bottom Notification Tray Footer Bar (History | Clear all | Notification Type)
          Row(
            children: [
              // 1. Notification History Pill Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onOpenHistory?.call();
                  },
                  child: Container(
                    width: 68,
                    height: 44,
                    decoration: BoxDecoration(
                      color: pillBtnBg,
                      borderRadius: BorderRadius.circular(22),
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
              ),
              const SizedBox(width: 8),

              // 2. Center "Clear all" Stadium Pill Button
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onClearAllNotifications?.call();
                    },
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: pillBtnBg,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: Text(
                          'Clear all',
                          style: font.textStyleBuilder(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 3. Notification Type / Settings Pill Button (Bell + Gear badge)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showNotificationTypeSheet(context);
                  },
                  child: Container(
                    width: 68,
                    height: 44,
                    decoration: BoxDecoration(
                      color: pillBtnBg,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.notifications_rounded,
                            size: 19,
                            color: colors.textPrimary,
                          ),
                          Positioned(
                            right: -4,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: pillBtnBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.settings_rounded,
                                size: 10,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNotificationTypeSheet(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colors.textPrimary.withValues(alpha: 0.12),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_active_rounded,
                              size: 20,
                              color: colors.activePill,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Notification Type',
                              style: font.textStyleBuilder(
                                fontSize: 17.0,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final styleOption in NotificationStyle.values) ...[
                      Builder(
                        builder: (context) {
                          final isSelected = styleOption == notificationStyle;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onNotificationStyleChanged?.call(styleOption);
                                Navigator.of(ctx).pop();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colors.activePill.withValues(alpha: 0.18)
                                      : colors.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? colors.activePill
                                        : Colors.transparent,
                                    width: 1.4,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            styleOption.displayName,
                                            style: font.textStyleBuilder(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            styleOption.description,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: font.textStyleBuilder(
                                              fontSize: 11.5,
                                              color: colors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 20,
                                        color: colors.activePill,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    if (onOpenNotificationSettings != null) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            onOpenNotificationSettings!();
                          },
                          icon: Icon(
                            Icons.settings_outlined,
                            size: 16,
                            color: colors.textPrimary,
                          ),
                          label: Text(
                            'System Notification Settings',
                            style: font.textStyleBuilder(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
