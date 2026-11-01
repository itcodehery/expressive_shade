import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/font_config.dart';
import '../models/notification_model.dart';
import '../theme/m3_expressive_theme.dart';

class ExpressiveNotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final VoidCallback onDismiss;
  final ValueChanged<String>? onActionTap;

  const ExpressiveNotificationCard({
    super.key,
    required this.notification,
    required this.colors,
    required this.font,
    required this.onDismiss,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDismiss();
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 28),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: notification.appColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(notification.appIcon, size: 14, color: notification.appColor),
                ),
                const SizedBox(width: 8),
                Text(
                  notification.appName,
                  style: font.textStyleBuilder(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '•',
                  style: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5)),
                ),
                const SizedBox(width: 6),
                Text(
                  notification.timeAgo,
                  style: font.textStyleBuilder(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: colors.textSecondary.withValues(alpha: 0.7),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Content
            Text(
              notification.title,
              style: font.textStyleBuilder(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              notification.content,
              style: font.textStyleBuilder(
                fontSize: 13,
                color: colors.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // Inline Action Pills
            if (notification.actions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: notification.actions.map((action) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onActionTap?.call(action);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.textSecondary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        action,
                        style: font.textStyleBuilder(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.activePill,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
