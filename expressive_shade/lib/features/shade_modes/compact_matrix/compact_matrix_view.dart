import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/font_config.dart';
import '../../../../models/media_player_style.dart';
import '../../../../models/notification_model.dart';
import '../../../../models/notification_style.dart';
import '../../../../models/qs_tile_model.dart';
import '../../../../models/slider_style.dart';
import '../../../../services/smart_notification_classifier.dart';
import '../../../../theme/m3_expressive_theme.dart';
import '../../../../widgets/expressive_media_card.dart';
import '../../lyrics/widgets/inline_lyrics_view.dart';
import '../../../../widgets/expressive_pill.dart';
import '../../../../widgets/expressive_slider.dart';
import '../../notifications/notification_card.dart';
import '../common/shade_tiles_grid.dart';
import 'widgets/matrix_header.dart';
import 'widgets/matrix_tile.dart';

class CompactMatrixView extends StatefulWidget {
  final int batteryLevel;
  final bool isCharging;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final List<QsTileModel> tiles;
  final List<NotificationModel> notifications;
  final NotificationStyle notificationStyle;
  final bool isExpanded;
  final Animation<double> bouncyAnimation;
  final bool isUnorganized;
  final double brightness;
  final SliderStyle sliderStyle;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<String> onToggleTile;
  final ValueChanged<String> onLongPressTile;
  final VoidCallback onToggleExpand;
  final VoidCallback onEditTap;
  final VoidCallback onToggleOrganize;
  final VoidCallback onClearAll;
  final VoidCallback onOpenHistory;
  final ValueChanged<String> onDismissNotification;
  final ValueChanged<NotificationModel> onOpenNotification;
  final void Function(NotificationModel, NotificationAction)? onActionTap;
  final void Function(NotificationModel, NotificationAction, String)? onReply;
  final void Function(NotificationModel)? onSnoozeNotification;
  final ValueNotifier<TileImpulse?>? impulseNotifier;
  final ScrollController scrollController;

  // Media
  final String mediaTitle;
  final String mediaArtist;
  final String mediaApp;
  final bool isPlaying;
  final double mediaProgress;
  final dynamic mediaArtwork;
  final MediaPlayerStyle mediaPlayerStyle;
  final VoidCallback? onPlayPause;
  final VoidCallback? onSkipNext;
  final VoidCallback? onSkipPrevious;
  final ValueChanged<double>? onProgressChanged;

  const CompactMatrixView({
    super.key,
    required this.batteryLevel,
    required this.isCharging,
    required this.colors,
    required this.font,
    required this.tiles,
    required this.notifications,
    this.notificationStyle = NotificationStyle.android17,
    required this.isExpanded,
    required this.bouncyAnimation,
    required this.isUnorganized,
    required this.brightness,
    required this.sliderStyle,
    required this.onBrightnessChanged,
    required this.onToggleTile,
    required this.onLongPressTile,
    required this.onToggleExpand,
    required this.onEditTap,
    required this.onToggleOrganize,
    required this.onClearAll,
    required this.onOpenHistory,
    required this.onDismissNotification,
    required this.onOpenNotification,
    this.onActionTap,
    this.onReply,
    this.onSnoozeNotification,
    required this.impulseNotifier,
    required this.scrollController,
    this.mediaTitle = '',
    this.mediaArtist = '',
    this.mediaApp = '',
    this.isPlaying = false,
    this.mediaProgress = 0.0,
    this.mediaArtwork,
    this.mediaPlayerStyle = MediaPlayerStyle.expressiveWave,
    this.onPlayPause,
    this.onSkipNext,
    this.onSkipPrevious,
    this.onProgressChanged,
  });

  @override
  State<CompactMatrixView> createState() => _CompactMatrixViewState();
}

class _CompactMatrixViewState extends State<CompactMatrixView> {
  @override
  Widget build(BuildContext context) {
    final rows3 = packTilesInto3ColRows(widget.tiles);
    final topTwoRows = rows3.take(2).toList();
    final remainingRows = rows3.skip(2).toList();

    return ListView(
      controller: widget.scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.zero,
      children: [
        // 1 & 2. Top Opaque Area: Header Chips, Sliders & Quick Tiles (Full Width Edge-to-Edge)
        Container(
          width: double.infinity,
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MatrixHeader(
                batteryLevel: widget.batteryLevel,
                isCharging: widget.isCharging,
                colors: widget.colors,
                font: widget.font,
                onEditTap: widget.onEditTap,
              ),
              const SizedBox(height: 12),

              // 2. Quick Settings Section
              Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brightness Slider (animates above tiles on expand)
            ClipRect(
              child: SizeTransition(
                sizeFactor: widget.bouncyAnimation,
                alignment: Alignment.topCenter,
                child: FadeTransition(
                  opacity: widget.bouncyAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExpressiveSlider(
                        value: widget.brightness,
                        onChanged: widget.onBrightnessChanged,
                        leadingIcon: Icons.wb_sunny_rounded,
                        trailingIcon: Icons.auto_mode_rounded,
                        onTrailingTap: () => HapticFeedback.lightImpact(),
                        colors: widget.colors,
                        style: widget.sliderStyle,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),

            // Top 2 rows (always visible)
            _buildSmartTilesRowsPage(topTwoRows, 0),

            // Remaining expandable rows
            if (remainingRows.isNotEmpty) ...[
              ClipRect(
                child: SizeTransition(
                  sizeFactor: widget.bouncyAnimation,
                  alignment: Alignment.topCenter,
                  child: FadeTransition(
                    opacity: widget.bouncyAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _buildSmartTilesRowsPage(remainingRows, 2),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Drag handle to expand/collapse
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onToggleExpand,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: AnimatedBuilder(
                    animation: widget.bouncyAnimation,
                    builder: (context, _) {
                      final isExp = widget.bouncyAnimation.value > 0.5;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.colors.activePill.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 34,
                              height: 3.5,
                              decoration: BoxDecoration(
                                color: widget.colors.activePill.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              isExp
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: widget.colors.activePill,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Media Player Card + Inline Integration
      if (widget.isPlaying || (widget.mediaTitle.isNotEmpty && widget.mediaTitle != 'No media playing')) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExpressiveMediaCard(
                title: widget.mediaTitle,
                artist: widget.mediaArtist,
                appSource: widget.mediaApp,
                isPlaying: widget.isPlaying,
                progress: widget.mediaProgress,
                artwork: widget.mediaArtwork,
                colors: widget.colors,
                font: widget.font,
                style: widget.mediaPlayerStyle,
                onPlayPause: widget.onPlayPause ?? () {},
                onSkipNext: widget.onSkipNext,
                onSkipPrevious: widget.onSkipPrevious,
                onProgressChanged: widget.onProgressChanged ?? (_) {},
              ),
              InlineLyricsView(
                colors: widget.colors,
                font: widget.font,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],

        // 3. Categorized Notifications (Follows theme with darker background and curved bottom corners)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 28),
            decoration: BoxDecoration(
              color: widget.colors.notificationContainerBackground,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: widget.colors.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: _buildNotificationsSection(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSmartTilesRowsPage(List<List<QsTileModel>> rows, int baseRow) {
    return Column(
      children: [
        for (int r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 10),
          Row(
            children: [
              for (int c = 0; c < 3; c++) ...[
                if (c > 0) const SizedBox(width: 10),
                Expanded(
                  child: c < rows[r].length
                      ? MatrixTile(
                          tile: rows[r][c],
                          colors: widget.colors,
                          row: baseRow + r,
                          col: c,
                          impulseNotifier: widget.impulseNotifier,
                          onTap: () => widget.onToggleTile(rows[r][c].id),
                          onLongPress: () => widget.onLongPressTile(rows[r][c].id),
                        )
                      : const SizedBox(height: 58),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildNotificationsSection() {
    Widget content;
    if (widget.notifications.isEmpty) {
      content = Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        alignment: Alignment.center,
        child: Text(
          'No notifications',
          style: widget.font.textStyleBuilder(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: widget.colors.activePill.withValues(alpha: 0.6),
          ),
        ),
      );
    } else if (widget.isUnorganized) {
      final nonSummaryList =
          widget.notifications.where((n) => !n.isGroupSummary).toList();
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('All notifications'),
          const SizedBox(height: 10),
          for (int i = 0; i < nonSummaryList.length; i++)
            _buildSmartNotifCard(
              nonSummaryList[i],
              isFirst: i == 0,
              isLast: i == nonSummaryList.length - 1,
            ),
          _buildActionButtonsRow(),
        ],
      );
    } else {
      final priorityList = <NotificationModel>[];
      final updatesList = <NotificationModel>[];
      final lowPriorityList = <NotificationModel>[];

      for (final rawNotif in widget.notifications) {
        if (rawNotif.isGroupSummary) continue;
        final notif = _resolveClassified(rawNotif);
        switch (notif.category) {
          case NotificationCategory.realtime:
          case NotificationCategory.security:
          case NotificationCategory.conversations:
            priorityList.add(notif);
          case NotificationCategory.updates:
            updatesList.add(notif);
          case NotificationCategory.socials:
          case NotificationCategory.promotions:
          case NotificationCategory.silent:
            lowPriorityList.add(notif);
        }
      }

      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (priorityList.isNotEmpty) ...[
            _buildSectionHeader('Priority & People'),
            const SizedBox(height: 8),
            for (int i = 0; i < priorityList.length; i++)
              _buildSmartNotifCard(
                priorityList[i],
                isFirst: i == 0,
                isLast: i == priorityList.length - 1,
              ),
            if (updatesList.isNotEmpty || lowPriorityList.isNotEmpty)
              const SizedBox(height: 16),
          ],
          if (updatesList.isNotEmpty) ...[
            _buildSectionHeader('Updates'),
            const SizedBox(height: 8),
            for (int i = 0; i < updatesList.length; i++)
              _buildSmartNotifCard(
                updatesList[i],
                isFirst: i == 0,
                isLast: i == updatesList.length - 1,
              ),
            if (lowPriorityList.isNotEmpty) const SizedBox(height: 16),
          ],
          if (lowPriorityList.isNotEmpty) ...[
            _buildSectionHeader('Promotions & Social'),
            const SizedBox(height: 8),
            for (int i = 0; i < lowPriorityList.length; i++)
              _buildSmartNotifCard(
                lowPriorityList[i],
                isFirst: i == 0,
                isLast: i == lowPriorityList.length - 1,
              ),
          ],
          _buildActionButtonsRow(),
        ],
      );
    }

    return content;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: widget.font.textStyleBuilder(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: widget.colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSmartNotifCard(
    NotificationModel notif, {
    required bool isFirst,
    required bool isLast,
  }) {
    return NotificationCard(
      key: ValueKey(notif.id),
      notification: notif,
      colors: widget.colors,
      font: widget.font,
      style: widget.notificationStyle,
      isFirstInGroup: isFirst,
      isLastInGroup: isLast,
      groupCount: 1,
      onDismiss: () => widget.onDismissNotification(notif.id),
      onActionTap: widget.onActionTap != null
          ? (a) => widget.onActionTap!(notif, a)
          : null,
      onReply: widget.onReply != null
          ? (a, text) => widget.onReply!(notif, a, text)
          : null,
      onTap: () => widget.onOpenNotification(notif),
      onSnooze: widget.onSnoozeNotification != null
          ? () => widget.onSnoozeNotification!(notif)
          : null,
    );
  }

  NotificationModel _resolveClassified(NotificationModel n) {
    if (n.isUserCategoryOverride) {
      return n;
    }
    final pkg = n.packageName.isNotEmpty ? n.packageName : n.appName;
    final res = SmartNotificationClassifier.classify(
      appName: n.appName,
      packageName: pkg,
      title: n.title,
      content: n.content,
      channelId: n.channelId,
      androidCategory: n.androidCategory,
      isConversation: n.isConversation,
      hasReplyAction: n.actions.any((a) => a.hasRemoteInput),
    );
    return n.copyWith(
      category: res.category,
      categoryConfidence: res.confidence,
      extractedOtp: res.extractedOtp ?? n.extractedOtp,
      isUserCategoryOverride: res.isUserOverride,
    );
  }

  Widget _buildActionButtonsRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.history_rounded,
            onTap: widget.onOpenHistory,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: widget.isUnorganized ? Icons.grid_view_rounded : Icons.sort_rounded,
            onTap: widget.onToggleOrganize,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: widget.onClearAll,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: widget.colors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Clear all',
                    style: widget.font.textStyleBuilder(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: widget.colors.activePill,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: widget.colors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Icon(icon, size: 21, color: widget.colors.activePill),
        ),
      ),
    );
  }
}
