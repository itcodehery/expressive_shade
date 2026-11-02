import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/font_config.dart';
import '../../models/notification_model.dart';
import '../../theme/m3_expressive_theme.dart';
import '../../widgets/notification_channel_settings_card.dart';
import '../../widgets/springy_dismissible_notification.dart';

/// A cohesive Material 3 Expressive grouped notification container for an app.
///
/// Features:
/// - One unified outer container card with smooth 24px rounded corners.
/// - Single unified group header displaying App Icon, App Name, summary / count, and latest timestamp.
/// - Expand / collapse animated toggle with an M3 Expressive count pill.
/// - Clean child notification items that do not repeat the app icon or app title.
/// - Each child notification supports individual swipe-to-dismiss, tap-to-open, and inline actions/reply.
class NotificationGroupCard extends StatefulWidget {
  final List<NotificationModel> notifications;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final void Function(String id) onDismiss;
  final void Function(NotificationModel notification, NotificationAction action)? onActionTap;
  final void Function(NotificationModel notification, NotificationAction action, String text)? onReply;
  final void Function(NotificationModel notification)? onTap;
  final void Function(NotificationModel notification)? onSnooze;

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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: colors.isDark ? 0.40 : 0.52),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: colors.isDark ? 0.10 : 0.40),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: colors.isDark ? 0.16 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
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
                  duration: const Duration(milliseconds: 220),
                  firstCurve: Curves.easeOutCubic,
                  secondCurve: Curves.easeInCubic,
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
      ),
    );
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
            Text(
              primaryNotif.appName,
              style: font.textStyleBuilder(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
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
              primaryNotif.timeAgo,
              style: font.textStyleBuilder(
                fontSize: 11.5,
                color: colors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 8),

            // Expand / Collapse Pill Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colors.activePill.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count',
                    style: font.textStyleBuilder(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: colors.activePill,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: colors.activePill,
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
                                notif.timeAgo,
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
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(
          color: colors.background.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.16),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: font.textStyleBuilder(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
