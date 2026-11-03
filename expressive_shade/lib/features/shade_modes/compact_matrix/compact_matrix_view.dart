import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/font_config.dart';
import '../../../../models/notification_model.dart';
import '../../../../models/notification_style.dart';
import '../../../../models/qs_tile_model.dart';
import '../../../../models/slider_style.dart';
import '../../../../theme/m3_expressive_theme.dart';
import '../../../../widgets/expressive_pill.dart';
import '../../../../widgets/expressive_slider.dart';
import '../../../../widgets/notification_channel_settings_card.dart';
import '../../../../widgets/springy_dismissible_notification.dart';
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
  });

  @override
  State<CompactMatrixView> createState() => _CompactMatrixViewState();
}

class _CompactMatrixViewState extends State<CompactMatrixView> {
  String? _settingsNotifId;
  String? _replyingNotifId;
  NotificationAction? _replyingAction;
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _submitReply(NotificationModel notif, NotificationAction action) {
    final text = _replyController.text.trim();
    if (text.isNotEmpty && widget.onReply != null) {
      HapticFeedback.mediumImpact();
      widget.onReply!(notif, action, text);
      _replyController.clear();
      setState(() {
        _replyingNotifId = null;
        _replyingAction = null;
      });
    }
  }

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
          color: widget.colors.background,
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
    if (widget.notifications.isEmpty) {
      return Container(
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
    }

    if (widget.isUnorganized) {
      final nonSummaryList =
          widget.notifications.where((n) => !n.isGroupSummary).toList();
      return Column(
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
    }

    final important = <NotificationModel>[];
    final other = <NotificationModel>[];

    for (final notif in widget.notifications) {
      if (notif.isGroupSummary) continue;
      if (_isImportant(notif)) {
        important.add(notif);
      } else {
        other.add(notif);
      }
    }

    if (important.isEmpty && other.isNotEmpty) {
      important.addAll(other.take((other.length / 2).ceil()));
      other.removeRange(0, important.length);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (important.isNotEmpty) ...[
          _buildSectionHeader('Important'),
          const SizedBox(height: 8),
          for (int i = 0; i < important.length; i++)
            _buildSmartNotifCard(
              important[i],
              isFirst: i == 0,
              isLast: i == important.length - 1,
            ),
          const SizedBox(height: 16),
        ],
        if (other.isNotEmpty) ...[
          _buildSectionHeader('Other'),
          const SizedBox(height: 8),
          for (int i = 0; i < other.length; i++)
            _buildSmartNotifCard(
              other[i],
              isFirst: i == 0,
              isLast: i == other.length - 1,
            ),
        ],
        _buildActionButtonsRow(),
      ],
    );
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
    final BorderRadius borderRadius = switch (widget.notificationStyle) {
      NotificationStyle.compact => BorderRadius.circular(16),
      NotificationStyle.oneui => BorderRadius.circular(32),
      NotificationStyle.ios => BorderRadius.circular(20),
      NotificationStyle.hyperOS => BorderRadius.circular(22),
      NotificationStyle.android17 => BorderRadius.only(
          topLeft: Radius.circular(isFirst ? 22 : 8),
          topRight: Radius.circular(isFirst ? 22 : 8),
          bottomLeft: Radius.circular(isLast ? 22 : 8),
          bottomRight: Radius.circular(isLast ? 22 : 8),
        ),
    };

    final EdgeInsets margin = switch (widget.notificationStyle) {
      NotificationStyle.compact => const EdgeInsets.only(bottom: 8),
      NotificationStyle.oneui => const EdgeInsets.only(bottom: 8),
      NotificationStyle.ios => const EdgeInsets.only(bottom: 10),
      NotificationStyle.hyperOS => const EdgeInsets.only(bottom: 10),
      NotificationStyle.android17 => EdgeInsets.only(bottom: isLast ? 10 : 3),
    };

    final Color cardBg = switch (widget.notificationStyle) {
      NotificationStyle.compact => widget.colors.notificationCardBackground,
      NotificationStyle.ios => widget.colors.isDark
          ? Color.alphaBlend(Colors.white.withValues(alpha: 0.05), widget.colors.notificationCardBackground)
          : Color.alphaBlend(Colors.black.withValues(alpha: 0.03), widget.colors.notificationCardBackground),
      NotificationStyle.oneui => widget.colors.notificationCardBackground,
      NotificationStyle.hyperOS => widget.colors.notificationCardBackground,
      NotificationStyle.android17 => widget.colors.notificationCardBackground,
    };

    if (_settingsNotifId == notif.id) {
      return NotificationChannelSettingsCard(
        notification: notif,
        colors: widget.colors,
        font: widget.font,
        borderRadius: borderRadius,
        onClose: () => setState(() => _settingsNotifId = null),
      );
    }

    return SpringyDismissibleNotification(
      key: Key('matrix_notif_${notif.id}'),
      colors: widget.colors,
      borderRadius: borderRadius,
      margin: margin,
      onDismissed: () => widget.onDismissNotification(notif.id),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onOpenNotification(notif);
        },
        onLongPress: () {
          HapticFeedback.heavyImpact();
          setState(() {
            _settingsNotifId = (_settingsNotifId == notif.id) ? null : notif.id;
          });
        },
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: borderRadius,
              border: Border.all(
                color: widget.colors.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.colors.isDark ? 0.22 : 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: notif.appColor.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: notif.appIconBytes != null
                          ? Image.memory(
                              notif.appIconBytes!,
                              width: 26,
                              height: 26,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(notif.appIcon, size: 14, color: notif.appColor),
                              ),
                            )
                          : Center(
                              child: Icon(notif.appIcon, size: 14, color: notif.appColor),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  notif.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: widget.font.textStyleBuilder(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: widget.colors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '• ${notif.timeAgo}',
                                style: widget.font.textStyleBuilder(
                                  fontSize: 10.5,
                                  color: widget.colors.textSecondary.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notif.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: widget.font.textStyleBuilder(
                              fontSize: 11.5,
                              color: widget.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (notif.actions.isNotEmpty || widget.onSnoozeNotification != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final action in notif.actions)
                        _buildActionChip(
                          label: action.title,
                          colors: widget.colors,
                          font: widget.font,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (action.hasRemoteInput && widget.onReply != null) {
                              setState(() {
                                if (_replyingNotifId == notif.id && _replyingAction == action) {
                                  _replyingNotifId = null;
                                  _replyingAction = null;
                                } else {
                                  _replyingNotifId = notif.id;
                                  _replyingAction = action;
                                }
                              });
                            } else {
                              widget.onActionTap?.call(notif, action);
                            }
                          },
                        ),
                      if (widget.onSnoozeNotification != null)
                        _buildActionChip(
                          label: 'Snooze',
                          colors: widget.colors,
                          font: widget.font,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onSnoozeNotification!(notif);
                          },
                        ),
                    ],
                  ),
                ],
                if (_replyingNotifId == notif.id && _replyingAction != null) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _replyController,
                    autofocus: true,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitReply(notif, _replyingAction!),
                    style: widget.font.textStyleBuilder(
                      fontSize: 12.5,
                      color: widget.colors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: _replyingAction!.title,
                      hintStyle: widget.font.textStyleBuilder(
                        fontSize: 12.5,
                        color: widget.colors.textSecondary,
                      ),
                      filled: true,
                      fillColor: widget.colors.background.withValues(alpha: 0.8),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.send_rounded, size: 16, color: widget.colors.activePill),
                        onPressed: () => _submitReply(notif, _replyingAction!),
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
  }

  Widget _buildActionChip({
    required String label,
    required ExpressiveThemeColors colors,
    required FontConfig font,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: font.textStyleBuilder(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: colors.activePill,
          ),
        ),
      ),
    );
  }

  bool _isImportant(NotificationModel notif) {
    final combined = '${notif.appName} ${notif.title} ${notif.content}'.toLowerCase();
    if (notif.isOngoing) return true;
    return combined.contains('missed call') ||
        combined.contains('call') ||
        combined.contains('otp') ||
        combined.contains('bank') ||
        combined.contains('code') ||
        combined.contains('license') ||
        combined.contains('urgent') ||
        combined.contains('security');
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
