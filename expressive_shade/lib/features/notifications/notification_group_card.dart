import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/font_config.dart';
import '../../models/notification_model.dart';
import '../../models/notification_style.dart';
import '../../theme/m3_expressive_theme.dart';
import '../../widgets/notification_channel_settings_card.dart';
import '../../widgets/springy_dismissible_notification.dart';

/// A cohesive grouped notification container for an app.
class NotificationGroupCard extends StatefulWidget {
  final List<NotificationModel> notifications;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final void Function(String id) onDismiss;
  final void Function(NotificationModel notification, NotificationAction action)? onActionTap;
  final void Function(NotificationModel notification, NotificationAction action, String text)? onReply;
  final void Function(NotificationModel notification)? onTap;
  final void Function(NotificationModel notification)? onSnooze;
  final NotificationStyle style;

  const NotificationGroupCard({
    super.key,
    required this.notifications,
    required this.colors,
    required this.font,
    required this.onDismiss,
    this.onActionTap,
    this.onReply,
    this.onTap,
    this.onSnooze,
    this.style = NotificationStyle.android17,
  });

  @override
  State<NotificationGroupCard> createState() => _NotificationGroupCardState();
}

class _NotificationGroupCardState extends State<NotificationGroupCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  String? _settingsNotificationId;
  NotificationAction? _replyingAction;
  String? _replyingNotificationId;
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _sendReply(NotificationModel notif, NotificationAction action) {
    final text = _replyController.text.trim();
    if (text.isNotEmpty && widget.onReply != null) {
      HapticFeedback.mediumImpact();
      widget.onReply!(notif, action, text);
      _replyController.clear();
      setState(() {
        _replyingAction = null;
        _replyingNotificationId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notifications.isEmpty) return const SizedBox.shrink();

    final colors = widget.colors;
    final font = widget.font;

    // Distinguish between summary notification and child message notifications
    NotificationModel? summaryNotif;
    for (final n in widget.notifications) {
      if (n.isGroupSummary ||
          (n.title.toLowerCase() == n.appName.toLowerCase() &&
              n.content.toLowerCase().contains('message'))) {
        summaryNotif = n;
        break;
      }
    }

    final childNotifs = widget.notifications
        .where((n) => summaryNotif == null || n.id != summaryNotif.id)
        .toList();

    // If all notifications were flagged as summary or filtered out, fall back to all
    final effectiveChildren = childNotifs.isNotEmpty ? childNotifs : widget.notifications;
    final primaryNotif = widget.notifications.first;

    // If one of the children is showing settings
    if (_settingsNotificationId != null) {
      final targetNotif = widget.notifications.firstWhere(
        (n) => n.id == _settingsNotificationId,
        orElse: () => primaryNotif,
      );
      return NotificationChannelSettingsCard(
        notification: targetNotif,
        colors: colors,
        font: font,
        borderRadius: BorderRadius.circular(24),
        onClose: () => setState(() => _settingsNotificationId = null),
      );
    }

    // Summary line in header (e.g. "7 messages from 2 chats" or "3 notifications")
    final String summarySubtitle = summaryNotif != null && summaryNotif.content.isNotEmpty
        ? summaryNotif.content
        : '${effectiveChildren.length} notifications';

    final BorderRadius groupBorderRadius = switch (widget.style) {
      NotificationStyle.compact => BorderRadius.circular(20),
      NotificationStyle.oneui => BorderRadius.circular(32),
      NotificationStyle.ios => BorderRadius.circular(20),
      NotificationStyle.hyperOS => BorderRadius.circular(22),
      NotificationStyle.joined => BorderRadius.circular(24),
      NotificationStyle.android17 => BorderRadius.circular(24),
    };

    final Color groupCardBg = switch (widget.style) {
      NotificationStyle.compact => colors.notificationCardBackground,
      NotificationStyle.joined => colors.notificationCardBackground,
      NotificationStyle.ios => colors.isDark
          ? Color.alphaBlend(Colors.white.withValues(alpha: 0.05), colors.notificationCardBackground)
          : Color.alphaBlend(Colors.black.withValues(alpha: 0.03), colors.notificationCardBackground),
      NotificationStyle.oneui => colors.notificationCardBackground,
      NotificationStyle.hyperOS => colors.notificationCardBackground,
      NotificationStyle.android17 => colors.notificationCardBackground,
    };

    final groupCard = Container(
      margin: EdgeInsets.only(bottom: widget.style == NotificationStyle.compact ? 8 : 10),
      child: ClipRRect(
        borderRadius: groupBorderRadius,
        child: Container(
          decoration: BoxDecoration(
            color: groupCardBg,
            borderRadius: groupBorderRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Unified Group Header Row
              _buildGroupHeader(
                primaryNotif: primaryNotif,
                summarySubtitle: summarySubtitle,
                count: effectiveChildren.length,
                colors: colors,
                font: font,
              ),

              // 2. Child Notifications Area
              AnimatedCrossFade(
                duration: _isExpanded ? M3Motion.expandDuration : M3Motion.collapseDuration,
                firstCurve: M3Motion.emphasizedDecelerate,
                secondCurve: M3Motion.emphasizedAccelerate,
                sizeCurve: _isExpanded ? M3Motion.emphasizedDecelerate : M3Motion.emphasizedAccelerate,
                crossFadeState:
                    _isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                firstChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < effectiveChildren.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          thickness: 0.8,
                          color: colors.textSecondary.withValues(alpha: 0.12),
                          indent: 14,
                          endIndent: 14,
                        ),
                      _buildChildNotificationItem(
                        notif: effectiveChildren[i],
                        colors: colors,
                        font: font,
                      ),
                    ],
                  ],
                ),
                secondChild: _buildCollapsedPreview(
                  latestNotif: effectiveChildren.first,
                  remainingCount: effectiveChildren.length - 1,
                  colors: colors,
                  font: font,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final bool canDismissGroup = widget.notifications.any((n) => n.isClearable);
    if (!_isExpanded && canDismissGroup) {
      return SpringyDismissibleNotification(
        key: Key('group_dismiss_${primaryNotif.packageName}_${primaryNotif.groupKey}'),
        colors: colors,
        borderRadius: BorderRadius.circular(24),
        margin: const EdgeInsets.only(bottom: 10),
        onDismissed: () {
          for (final n in widget.notifications.where((n) => n.isClearable)) {
            widget.onDismiss(n.id);
          }
        },
        child: groupCard,
      );
    }

    return groupCard;
  }

  Widget _buildGroupHeader({
    required NotificationModel primaryNotif,
    required String summarySubtitle,
    required int count,
    required ExpressiveThemeColors colors,
    required FontConfig font,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _isExpanded = !_isExpanded);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Row(
          children: [
            // App Icon
            Container(
              width: 24,
              height: 24,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: primaryNotif.appColor.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
              child: primaryNotif.appIconBytes != null
                  ? Image.memory(
                      primaryNotif.appIconBytes!,
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(primaryNotif.appIcon,
                            size: 13, color: primaryNotif.appColor),
                      ),
                    )
                  : Center(
                      child: Icon(primaryNotif.appIcon,
                          size: 13, color: primaryNotif.appColor),
                    ),
            ),
            const SizedBox(width: 8),

            // App Name
            Flexible(
              flex: 2,
              child: Text(
                primaryNotif.appName,
                style: font.textStyleBuilder(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),

            // Dot
            Text(
              '•',
              style: TextStyle(
                fontSize: 11,
                color: colors.textSecondary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 6),

            // Summary Subtitle (e.g. "7 messages from 2 chats")
            Expanded(
              flex: 2,
              child: Text(
                summarySubtitle,
                style: font.textStyleBuilder(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),

            // Timestamp
            Text(
              widget.style == NotificationStyle.ios
                  ? primaryNotif.relativeTime
                  : (widget.style == NotificationStyle.joined
                      ? primaryNotif.clockTime
                      : primaryNotif.timeAgo),
              style: font.textStyleBuilder(
                fontSize: 11.5,
                color: colors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 8),

            // Expand / Collapse Pill Badge (Matches Android 17 Expressive reference tray)
            AnimatedContainer(
              duration: M3Motion.microDuration,
              curve: M3Motion.emphasized,
              padding: EdgeInsets.symmetric(
                horizontal: (_isExpanded && widget.style == NotificationStyle.android17) ? 7 : 8,
                vertical: 2.5,
              ),
              decoration: BoxDecoration(
                color: (_isExpanded && widget.style == NotificationStyle.android17)
                    ? (colors.isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.black.withValues(alpha: 0.06))
                    : colors.activePill.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isExpanded || widget.style != NotificationStyle.android17) ...[
                    Text(
                      '$count',
                      style: font.textStyleBuilder(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: colors.isDark ? colors.activePill : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 2),
                  ],
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: M3Motion.microDuration,
                    curve: M3Motion.emphasized,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 15,
                      color: (_isExpanded && widget.style == NotificationStyle.android17)
                          ? colors.textPrimary.withValues(alpha: 0.85)
                          : (colors.isDark ? colors.activePill : colors.textPrimary),
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

  Widget _buildChildNotificationItem({
    required NotificationModel notif,
    required ExpressiveThemeColors colors,
    required FontConfig font,
  }) {
    final isReplying = _replyingNotificationId == notif.id && _replyingAction != null;

    return SpringyDismissibleNotification(
      key: Key(notif.id),
      colors: colors,
      borderRadius: BorderRadius.zero,
      onDismissed: () => widget.onDismiss(notif.id),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () {
          HapticFeedback.heavyImpact();
          setState(() => _settingsNotificationId = notif.id);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Chat Title / Sender Row
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: notif.canOpen && widget.onTap != null
                    ? () => widget.onTap!(notif)
                    : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notif.title,
                                  style: font.textStyleBuilder(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.style == NotificationStyle.ios
                                    ? notif.relativeTime
                                    : (widget.style == NotificationStyle.joined
                                        ? notif.clockTime
                                        : notif.timeAgo),
                                style: font.textStyleBuilder(
                                  fontSize: 11.5,
                                  color: colors.textSecondary.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            notif.content,
                            style: font.textStyleBuilder(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w400,
                              color: colors.textSecondary,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Actions (Reply, Mark as read, Mute, Snooze)
              if (notif.actions.isNotEmpty || widget.onSnooze != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final action in notif.actions)
                      _buildActionChip(
                        label: action.title,
                        colors: colors,
                        font: font,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (action.hasRemoteInput && widget.onReply != null) {
                            setState(() {
                              if (_replyingNotificationId == notif.id &&
                                  _replyingAction == action) {
                                _replyingNotificationId = null;
                                _replyingAction = null;
                              } else {
                                _replyingNotificationId = notif.id;
                                _replyingAction = action;
                              }
                            });
                          } else {
                            widget.onActionTap?.call(notif, action);
                          }
                        },
                      ),
                    if (widget.onSnooze != null)
                      _buildActionChip(
                        label: 'Snooze',
                        colors: colors,
                        font: font,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onSnooze!(notif);
                        },
                      ),
                  ],
                ),
              ],

              // Inline Reply input field
              if (isReplying) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _replyController,
                  autofocus: true,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendReply(notif, _replyingAction!),
                  style: font.textStyleBuilder(fontSize: 13.0, color: colors.textPrimary),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: _replyingAction!.title,
                    hintStyle: font.textStyleBuilder(
                        fontSize: 13.0, color: colors.textSecondary),
                    filled: true,
                    fillColor: colors.background.withValues(alpha: 0.8),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.send_rounded, size: 18, color: colors.activePill),
                      onPressed: () => _sendReply(notif, _replyingAction!),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedPreview({
    required NotificationModel latestNotif,
    required int remainingCount,
    required ExpressiveThemeColors colors,
    required FontConfig font,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _isExpanded = true);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    latestNotif.title,
                    style: font.textStyleBuilder(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    latestNotif.content,
                    style: font.textStyleBuilder(
                      fontSize: 12.0,
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (remainingCount > 0) ...[
              const SizedBox(width: 8),
              Text(
                '+$remainingCount more',
                style: font.textStyleBuilder(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
