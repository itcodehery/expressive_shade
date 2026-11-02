import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/font_config.dart';
import '../models/notification_model.dart';
import '../theme/m3_expressive_theme.dart';

class ExpressiveNotificationCard extends StatefulWidget {
  final NotificationModel notification;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final VoidCallback onDismiss;
  final ValueChanged<String>? onActionTap;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final int groupCount;

  const ExpressiveNotificationCard({
    super.key,
    required this.notification,
    required this.colors,
    required this.font,
    required this.onDismiss,
    this.onActionTap,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.groupCount = 1,
  });

  @override
  State<ExpressiveNotificationCard> createState() => _ExpressiveNotificationCardState();
}

class _ExpressiveNotificationCardState extends State<ExpressiveNotificationCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final colors = widget.colors;
    final font = widget.font;

    // Dynamic squircle corners based on app cluster position
    final BorderRadius borderRadius = BorderRadius.only(
      topLeft: Radius.circular(widget.isFirstInGroup ? 22 : 8),
      topRight: Radius.circular(widget.isFirstInGroup ? 22 : 8),
      bottomLeft: Radius.circular(widget.isLastInGroup ? 22 : 8),
      bottomRight: Radius.circular(widget.isLastInGroup ? 22 : 8),
    );

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.horizontal,
      movementDuration: const Duration(milliseconds: 240),
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.32,
        DismissDirection.endToStart: 0.32,
      },
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        widget.onDismiss();
      },
      background: const SizedBox.shrink(),
      secondaryBackground: const SizedBox.shrink(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: widget.isLastInGroup ? 10 : 3),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: borderRadius,
          border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: colors.isDark ? 0.12 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row: App Icon / Avatar, App Name, Time, Group Badge & Chevron
            Row(
              children: [
                // App Icon / Conversation Avatar with badge
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: notification.appColor.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(notification.appIcon, size: 14, color: notification.appColor),
                  ),
                ),
                const SizedBox(width: 8),

                // App Name with ellipsis overflow protection
                Flexible(
                  child: Text(
                    notification.appName,
                    style: font.textStyleBuilder(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 5),

                // Separator Dot
                Text(
                  '•',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 5),

                // Relative Time
                Text(
                  notification.timeAgo,
                  style: font.textStyleBuilder(
                    fontSize: 12.0,
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                ),

                const Spacer(),

                // Group Count Badge (e.g. '2 v' from screenshot)
                if (widget.groupCount > 1 && widget.isFirstInGroup) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.activePill.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.groupCount}',
                          style: font.textStyleBuilder(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w700,
                            color: colors.activePill,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 13,
                          color: colors.activePill,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // Expand / Collapse Chevron Button
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 19,
                      color: colors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Notification Title / Sender Name (bold, protected against overflow)
            Text(
              notification.title,
              style: font.textStyleBuilder(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),

            // Message Body (expandable on chevron click)
            Text(
              notification.content,
              style: font.textStyleBuilder(
                fontSize: 13.0,
                color: colors.textSecondary,
              ),
              maxLines: _isExpanded ? null : 1,
              overflow: _isExpanded ? TextOverflow.clip : TextOverflow.ellipsis,
            ),

            // Inline Action Pills (e.g. 'Mark as read', 'Reply')
            if (_isExpanded && notification.actions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: notification.actions.map((action) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onActionTap?.call(action);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.background.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colors.textSecondary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        action,
                        style: font.textStyleBuilder(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
