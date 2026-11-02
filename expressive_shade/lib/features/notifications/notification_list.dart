import 'package:flutter/material.dart';
import '../../models/font_config.dart';
import '../../models/notification_model.dart';
import '../../theme/m3_expressive_theme.dart';
import 'notification_card.dart';

class NotificationList extends StatelessWidget {
  final List<NotificationModel> notifications;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final void Function(String id) onDismiss;
  final void Function(NotificationModel notification, NotificationAction action)? onActionTap;
  final void Function(NotificationModel notification, NotificationAction action, String text)? onReply;
  final void Function(NotificationModel notification)? onTap;
  final void Function(NotificationModel notification)? onSnooze;

  const NotificationList({
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
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: colors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'No new notifications',
              style: font.textStyleBuilder(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Group notifications by appName
    final grouped = <String, List<NotificationModel>>{};
    for (final notif in notifications) {
      grouped.putIfAbsent(notif.appName, () => []).add(notif);
    }

    final children = <Widget>[];
    for (final entry in grouped.entries) {
      final appNotifs = entry.value;
      for (int i = 0; i < appNotifs.length; i++) {
        final notif = appNotifs[i];
        children.add(
          NotificationCard(
            key: ValueKey(notif.id),
            notification: notif,
            colors: colors,
            font: font,
            isFirstInGroup: i == 0,
            isLastInGroup: i == appNotifs.length - 1,
            groupCount: appNotifs.length,
            onDismiss: () => onDismiss(notif.id),
            onActionTap: onActionTap != null ? (a) => onActionTap!(notif, a) : null,
            onReply: onReply != null ? (a, text) => onReply!(notif, a, text) : null,
            onTap: onTap != null ? () => onTap!(notif) : null,
            onSnooze: onSnooze != null ? () => onSnooze!(notif) : null,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
