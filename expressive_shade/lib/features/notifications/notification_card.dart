import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/font_config.dart';
import '../../models/notification_model.dart';
import '../../theme/m3_expressive_theme.dart';
import '../../widgets/notification_channel_settings_card.dart';
import '../../widgets/springy_dismissible_notification.dart';

class NotificationCard extends StatefulWidget {
  final NotificationModel notification;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final VoidCallback onDismiss;
  final ValueChanged<NotificationAction>? onActionTap;
  final void Function(NotificationAction action, String text)? onReply;
  final VoidCallback? onTap;
  final VoidCallback? onSnooze;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final int groupCount;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.colors,
    required this.font,
    required this.onDismiss,
    this.onActionTap,
    this.onReply,
    this.onTap,
    this.onSnooze,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.groupCount = 1,
  });

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  bool _isExpanded = true;
  bool _isShowingSettings = false;
  NotificationAction? _replyingTo;
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _sendReply() {
    final text = _replyController.text.trim();
    final action = _replyingTo;
    if (text.isEmpty || action == null) return;
    HapticFeedback.lightImpact();
    widget.onReply?.call(action, text);
    _replyController.clear();
    setState(() => _replyingTo = null);
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final colors = widget.colors;
    final font = widget.font;

    // Dynamic squircle corners based on app cluster position
    final BorderRadius borderRadius = (widget.groupCount <= 1)
        ? BorderRadius.circular(22)
        : BorderRadius.only(
            topLeft: Radius.circular(widget.isFirstInGroup ? 22 : 8),
            topRight: Radius.circular(widget.isFirstInGroup ? 22 : 8),
            bottomLeft: Radius.circular(widget.isLastInGroup ? 22 : 8),
            bottomRight: Radius.circular(widget.isLastInGroup ? 22 : 8),
          );

    if (_isShowingSettings) {
      return NotificationChannelSettingsCard(
        notification: notification,
        colors: colors,
        font: font,
        borderRadius: borderRadius,
        onClose: () => setState(() => _isShowingSettings = false),
      );
    }

    return SpringyDismissibleNotification(
      key: Key(notification.id),
      colors: colors,
      borderRadius: borderRadius,
      margin: EdgeInsets.only(bottom: (widget.groupCount <= 1 || widget.isLastInGroup) ? 10 : 3),
      onDismissed: () {
        widget.onDismiss();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () {
          HapticFeedback.heavyImpact();
          setState(() => _isShowingSettings = true);
        },
        child: ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: colors.isDark ? 0.62 : 0.72),
                borderRadius: borderRadius,
                border: Border.all(
                  color: Colors.white.withValues(alpha: colors.isDark ? 0.10 : 0.35),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: colors.isDark ? 0.14 : 0.06),
                    blurRadius: 10,
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
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: notification.appColor.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                    child: notification.appIconBytes != null
                        ? Image.memory(
                            notification.appIconBytes!,
                            width: 26,
                            height: 26,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(notification.appIcon, size: 14, color: notification.appColor),
                            ),
                          )
                        : Center(
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

              // Title + body: tapping opens the source app
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: notification.canOpen && widget.onTap != null ? widget.onTap : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  ],
                ),
              ),

              // Inline Action Pills (e.g. 'Mark as read', 'Reply') plus Snooze
              if (_isExpanded && (notification.actions.isNotEmpty || widget.onSnooze != null)) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final action in notification.actions)
                      _buildPill(
                        action.title,
                        colors,
                        font,
                        () {
                          HapticFeedback.lightImpact();
                          if (action.hasRemoteInput && widget.onReply != null) {
                            setState(() => _replyingTo = _replyingTo == action ? null : action);
                          } else {
                            widget.onActionTap?.call(action);
                          }
                        },
                      ),
                    if (widget.onSnooze != null)
                      _buildPill('Snooze', colors, font, () {
                        HapticFeedback.lightImpact();
                        widget.onSnooze!();
                      }),
                  ],
                ),
              ],

              // Inline reply field
              if (_isExpanded && _replyingTo != null) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _replyController,
                  autofocus: true,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendReply(),
                  style: font.textStyleBuilder(fontSize: 13.0, color: colors.textPrimary),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: _replyingTo!.title,
                    hintStyle: font.textStyleBuilder(fontSize: 13.0, color: colors.textSecondary),
                    filled: true,
                    fillColor: colors.background.withValues(alpha: 0.8),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.send_rounded, size: 18, color: colors.activePill),
                      onPressed: _sendReply,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    ),
    );
  }

  Widget _buildPill(String label, ExpressiveThemeColors colors, FontConfig font, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: colors.background.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.textSecondary.withValues(alpha: 0.15)),
        ),
        child: Text(
          label,
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
  }
}
