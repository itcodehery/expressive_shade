import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../models/font_config.dart';
import '../../../../models/media_player_style.dart';
import '../../../../models/notification_model.dart';
import '../../../../models/qs_tile_model.dart';
import '../../../../models/shade_theme.dart';
import '../../../../models/slider_style.dart';
import '../../../../theme/m3_expressive_theme.dart';
import '../../../../widgets/expressive_media_card.dart';
import '../../../../widgets/expressive_pill.dart';
import '../../../../widgets/expressive_slider.dart';
import '../../notifications/notification_list.dart';
import '../common/shade_tiles_grid.dart';
import 'widgets/unified_paginated_grid.dart';

class UnifiedShadeView extends StatelessWidget {
  final ScrollController scrollController;
  final Animation<double> bouncyAnimation;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final List<QsTileModel> tiles;
  final double brightness;
  final double volume;
  final SliderStyle sliderStyle;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onToggleExpand;
  final ValueChanged<String> onToggleTile;
  final ValueChanged<String> onLongPressTile;
  final ValueChanged<String> onResizeTile;
  final ValueNotifier<TileImpulse?>? impulseNotifier;
  final ValueNotifier<bool> reduceBlur;
  final CustomThemeData customTheme;

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

  const UnifiedShadeView({
    super.key,
    required this.scrollController,
    required this.bouncyAnimation,
    required this.colors,
    required this.font,
    required this.tiles,
    required this.brightness,
    required this.volume,
    required this.sliderStyle,
    required this.onBrightnessChanged,
    required this.onVolumeChanged,
    required this.onToggleExpand,
    required this.onToggleTile,
    required this.onLongPressTile,
    required this.onResizeTile,
    required this.impulseNotifier,
    required this.reduceBlur,
    required this.customTheme,
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
    final allRows = packTilesIntoRows(tiles);

    return ListView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 0),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Sliders (animates height / opacity)
              ClipRect(
                child: SizeTransition(
                  sizeFactor: bouncyAnimation,
                  alignment: Alignment.topCenter,
                  child: FadeTransition(
                    opacity: bouncyAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExpressiveSlider(
                          value: brightness,
                          onChanged: onBrightnessChanged,
                          leadingIcon: Icons.wb_sunny_rounded,
                          colors: colors,
                          style: sliderStyle,
                        ),
                        const SizedBox(height: 10),
                        ExpressiveSlider(
                          value: volume,
                          onChanged: onVolumeChanged,
                          leadingIcon: volume == 0
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          colors: colors,
                          style: sliderStyle,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Unified Paginated Quick Settings Grid
              _buildUnifiedPaginatedTilesGrid(allRows),

              // 3. Drag Handle / Tap to Expand or Collapse
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggleExpand,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: bouncyAnimation,
                      builder: (context, _) {
                        final isExp = bouncyAnimation.value > 0.5;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.activePill.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 34,
                                height: 3.5,
                                decoration: BoxDecoration(
                                  color: colors.activePill.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                isExp
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: colors.activePill,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // 4. Media Player Card
              if (isPlaying || (mediaTitle.isNotEmpty && mediaTitle != 'No media playing')) ...[
                const SizedBox(height: 10),
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
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 5. Notifications Section
        RepaintBoundary(
          child: _buildNotificationsContainer(context),
        ),
      ],
    );
  }

  Widget _buildUnifiedPaginatedTilesGrid(List<List<QsTileModel>> allRows) {
    if (allRows.isEmpty) return const SizedBox.shrink();

    const maxRowsPerPage = 5;
    final List<List<List<QsTileModel>>> pages = [];
    for (int i = 0; i < allRows.length; i += maxRowsPerPage) {
      final end = (i + maxRowsPerPage < allRows.length)
          ? i + maxRowsPerPage
          : allRows.length;
      pages.add(allRows.sublist(i, end));
    }

    return UnifiedPaginatedTilesContainer(
      colors: colors,
      pages: pages,
      bouncyAnimation: bouncyAnimation,
      builder: (context, pageIndex) {
        final pageRows = pages[pageIndex];
        final topTwo = pageRows.take(2).toList();
        final rest = pageRows.skip(2).toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTilesGridPage(topTwo, pageIndex * maxRowsPerPage),
            if (rest.isNotEmpty) ...[
              ClipRect(
                child: SizeTransition(
                  sizeFactor: bouncyAnimation,
                  alignment: Alignment.topCenter,
                  child: FadeTransition(
                    opacity: bouncyAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        _buildTilesGridPage(rest, pageIndex * maxRowsPerPage + 2),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
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

  Widget _buildNotificationsContainer(BuildContext context) {
    final blurSigma = customTheme.blurIntensity.clamp(4.0, 18.0);
    final cardOpacity = customTheme.cardOpacity.clamp(0.1, 1.0);
    final containerAlpha = (cardOpacity * 0.38).clamp(0.15, 0.55);
    final containerBg = colors.surface.withValues(alpha: containerAlpha);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: ValueListenableBuilder<bool>(
        valueListenable: reduceBlur,
        builder: (context, reduce, child) {
          final sigma = reduce ? blurSigma * 0.4 : blurSigma;
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: child,
          );
        },
        child: Container(
          constraints: BoxConstraints(minHeight: screenHeight + 200),
          decoration: BoxDecoration(
            color: containerBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
          child: NotificationList(
            notifications: notifications,
            colors: colors,
            font: font,
            onDismiss: onDismissNotification,
            onActionTap: onActionTap,
            onReply: onReply,
            onTap: onOpenNotification,
            onSnooze: onSnoozeNotification,
          ),
        ),
      ),
    );
  }
}
