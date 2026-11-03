import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/font_config.dart';
import '../../models/notification_model.dart';
import '../../models/notification_style.dart';
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
  final NotificationStyle style;

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
    this.style = NotificationStyle.android17,
  });

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> with TickerProviderStateMixin {
  // Collapsed by default across all styles (not showing actions until expanded or swiped)
  bool _isExpanded = false;
  bool _isShowingSettings = false;
  NotificationAction? _replyingTo;
  final TextEditingController _replyController = TextEditingController();

  // Compact Mode State & Gestures
  bool _compactActionsRevealed = false;
  double _compactDragDx = 0.0;
  bool _compactIsDismissing = false;
  late AnimationController _compactSpringController;
  late Animation<double> _compactSpringAnimation;
  late AnimationController _compactDismissController;
  late Animation<double> _compactSlideOutAnimation;
  late Animation<double> _compactHeightCollapseAnimation;

  @override
  void initState() {
    super.initState();
    _compactSpringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _compactDismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _compactHeightCollapseAnimation = CurvedAnimation(
      parent: _compactDismissController,
      curve: const Interval(0.35, 1.0, curve: Curves.fastOutSlowIn),
    );
  }

  @override
  void dispose() {
    _replyController.dispose();
    _compactSpringController.dispose();
    _compactDismissController.dispose();
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

  BorderRadius _computeBorderRadius() {
    switch (widget.style) {
      case NotificationStyle.compact:
        return BorderRadius.circular(16);
      case NotificationStyle.oneui:
        return BorderRadius.circular(32);
      case NotificationStyle.ios:
        return BorderRadius.circular(20);
      case NotificationStyle.hyperOS:
        return BorderRadius.circular(22);
      case NotificationStyle.android17:
        if (widget.groupCount <= 1) {
          return BorderRadius.circular(24);
        }
        return BorderRadius.only(
          topLeft: Radius.circular(widget.isFirstInGroup ? 24 : 8),
          topRight: Radius.circular(widget.isFirstInGroup ? 24 : 8),
          bottomLeft: Radius.circular(widget.isLastInGroup ? 24 : 8),
          bottomRight: Radius.circular(widget.isLastInGroup ? 24 : 8),
        );
    }
  }

  EdgeInsets _computeMargin() {
    switch (widget.style) {
      case NotificationStyle.compact:
        return const EdgeInsets.only(bottom: 8);
      case NotificationStyle.oneui:
        return const EdgeInsets.only(bottom: 8);
      case NotificationStyle.ios:
        return const EdgeInsets.only(bottom: 10);
      case NotificationStyle.hyperOS:
        return const EdgeInsets.only(bottom: 10);
      case NotificationStyle.android17:
        return EdgeInsets.only(
          bottom: (widget.groupCount <= 1 || widget.isLastInGroup) ? 10 : 3,
        );
    }
  }

  Color _computeCardBg(ExpressiveThemeColors colors) {
    switch (widget.style) {
      case NotificationStyle.compact:
        return colors.notificationCardBackground;
      case NotificationStyle.ios:
        return colors.isDark
            ? Color.alphaBlend(Colors.white.withValues(alpha: 0.05), colors.notificationCardBackground)
            : Color.alphaBlend(Colors.black.withValues(alpha: 0.03), colors.notificationCardBackground);
      case NotificationStyle.oneui:
      case NotificationStyle.hyperOS:
      case NotificationStyle.android17:
        return colors.notificationCardBackground;
    }
  }

  Border _computeBorder(ExpressiveThemeColors colors) {
    switch (widget.style) {
      case NotificationStyle.compact:
        return Border.all(
          color: colors.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          width: 0.9,
        );
      case NotificationStyle.ios:
        return Border.all(
          color: colors.isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
          width: 0.9,
        );
      case NotificationStyle.oneui:
        return Border.all(
          color: colors.isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.05),
          width: 0.8,
        );
      case NotificationStyle.hyperOS:
        return Border.all(
          color: colors.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          width: 0.8,
        );
      case NotificationStyle.android17:
        return Border.all(
          color: colors.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
          width: 0.8,
        );
    }
  }

  List<BoxShadow> _computeBoxShadow(ExpressiveThemeColors colors) {
    switch (widget.style) {
      case NotificationStyle.compact:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.22 : 0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ];
      case NotificationStyle.ios:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.35 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ];
      case NotificationStyle.oneui:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ];
      case NotificationStyle.hyperOS:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.24 : 0.05),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ];
      case NotificationStyle.android17:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.22 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final colors = widget.colors;
    final font = widget.font;
    final borderRadius = _computeBorderRadius();
    final margin = _computeMargin();
    final cardBg = _computeCardBg(colors);

    if (_isShowingSettings) {
      return NotificationChannelSettingsCard(
        notification: notification,
        colors: colors,
        font: font,
        borderRadius: borderRadius,
        onClose: () => setState(() => _isShowingSettings = false),
      );
    }

    // --- Compact Mode with Swipe-to-Reveal Actions & Swipe-to-Dismiss ---
    if (widget.style == NotificationStyle.compact) {
      return _buildCompactCardWithGestures(
        notification: notification,
        colors: colors,
        font: font,
        borderRadius: borderRadius,
        margin: margin,
        cardBg: cardBg,
      );
    }

    // --- Other 4 Styles (Android 17, iOS, OneUI, HyperOS) ---
    return SpringyDismissibleNotification(
      key: Key(notification.id),
      colors: colors,
      borderRadius: borderRadius,
      margin: margin,
      onDismissed: () {
        widget.onDismiss();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (notification.canOpen && widget.onTap != null) {
            widget.onTap!();
          } else {
            HapticFeedback.selectionClick();
            setState(() => _isExpanded = !_isExpanded);
          }
        },
        onLongPress: () {
          HapticFeedback.heavyImpact();
          setState(() => _isShowingSettings = true);
        },
        child: ClipRRect(
          borderRadius: borderRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: borderRadius,
              border: _computeBorder(colors),
              boxShadow: _computeBoxShadow(colors),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Render Style-specific Content
                switch (widget.style) {
                  NotificationStyle.android17 => _buildAndroid17Content(notification, colors, font),
                  NotificationStyle.ios => _buildIosContent(notification, colors, font),
                  NotificationStyle.oneui => _buildOneUiContent(notification, colors, font),
                  NotificationStyle.hyperOS => _buildHyperOsContent(notification, colors, font),
                  NotificationStyle.compact => const SizedBox.shrink(),
                },

                // Inline Action Buttons (Collapsed by default, revealed when expanded)
                if (_isExpanded && (notification.actions.isNotEmpty || widget.onSnooze != null)) ...[
                  const SizedBox(height: 10),
                  _buildActionsRow(notification, colors, font),
                ],

                // Inline reply field
                if (_isExpanded && _replyingTo != null) ...[
                  const SizedBox(height: 10),
                  _buildInlineReplyField(colors, font),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // --- COMPACT MODE: Swipe-to-Reveal Actions & Swipe-to-Dismiss ---
  // =========================================================================

  void _onCompactDragUpdate(DragUpdateDetails details) {
    if (_compactIsDismissing) return;
    setState(() {
      _compactDragDx += details.delta.dx;
    });
  }

  void _onCompactDragEnd(DragEndDetails details) {
    if (_compactIsDismissing) return;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final velocity = details.primaryVelocity ?? 0.0;
    final dismissThreshold = (screenWidth * 0.35).clamp(80.0, 200.0);

    // 1. Fully Swiping Right -> Dismiss to Right
    if (_compactDragDx > dismissThreshold || velocity > 400.0) {
      _dismissCompact(toRight: true);
      return;
    }

    // 2. Fully Swiping Left -> Dismiss to Left (only if actions not revealed, or swiped far left)
    if (_compactDragDx < -dismissThreshold || velocity < -400.0) {
      _dismissCompact(toRight: false);
      return;
    }

    // 3. Partial Swipe Right -> Reveal Action Tray!
    if (_compactDragDx > 35.0 || velocity > 120.0) {
      _snapCompactTo(revealed: true);
    } else if (_compactDragDx < -25.0) {
      // Swiping left closes actions tray
      _snapCompactTo(revealed: false);
    } else {
      _snapCompactTo(revealed: _compactActionsRevealed);
    }
  }

  void _snapCompactTo({required bool revealed}) {
    HapticFeedback.lightImpact();
    final start = _compactDragDx;
    _compactSpringAnimation = Tween<double>(begin: start, end: 0.0).animate(
      CurvedAnimation(
        parent: _compactSpringController,
        curve: Curves.easeOutCubic,
      ),
    );
    _compactSpringController.reset();
    _compactSpringController.forward();
    _compactSpringController.addListener(_onCompactSpringTick);
    setState(() {
      _compactActionsRevealed = revealed;
    });
  }

  void _onCompactSpringTick() {
    if (!mounted) return;
    setState(() {
      _compactDragDx = _compactSpringAnimation.value;
    });
    if (_compactSpringController.isCompleted) {
      _compactSpringController.removeListener(_onCompactSpringTick);
    }
  }

  void _dismissCompact({required bool toRight}) {
    if (_compactIsDismissing) return;
    _compactIsDismissing = true;
    HapticFeedback.mediumImpact();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final targetDx = toRight ? (screenWidth + 50) : (-screenWidth - 50);

    _compactSlideOutAnimation = Tween<double>(
      begin: _compactDragDx,
      end: targetDx,
    ).animate(
      CurvedAnimation(
        parent: _compactDismissController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeInCubic),
      ),
    );

    _compactDismissController.forward().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  Widget _buildCompactCardWithGestures({
    required NotificationModel notification,
    required ExpressiveThemeColors colors,
    required FontConfig font,
    required BorderRadius borderRadius,
    required EdgeInsets margin,
    required Color cardBg,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final currentDx = _compactIsDismissing
        ? (_compactSlideOutAnimation.value)
        : _compactDragDx;
    final dragFraction = (currentDx.abs() / screenWidth).clamp(0.0, 1.0);
    final opacity = (1.0 - dragFraction * 0.40).clamp(0.0, 1.0);

    return SizeTransition(
      sizeFactor: _compactIsDismissing
          ? Tween<double>(begin: 1.0, end: 0.0).animate(_compactHeightCollapseAnimation)
          : const AlwaysStoppedAnimation(1.0),
      alignment: Alignment.center,
      child: Padding(
        padding: margin,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: _onCompactDragUpdate,
          onHorizontalDragEnd: _onCompactDragEnd,
          onLongPress: () {
            HapticFeedback.heavyImpact();
            setState(() => _isShowingSettings = true);
          },
          onTap: () {
            if (_compactActionsRevealed) {
              _snapCompactTo(revealed: false);
            } else if (notification.canOpen && widget.onTap != null) {
              widget.onTap!();
            } else {
              _snapCompactTo(revealed: true);
            }
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _compactSpringController,
              _compactDismissController,
            ]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(currentDx, 0),
                child: Opacity(
                  opacity: opacity,
                  child: child,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: borderRadius,
                  border: _computeBorder(colors),
                  boxShadow: _computeBoxShadow(colors),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left App / Notification Icon
                        _buildAppIcon(notification, size: 20, isCircle: true),
                        const SizedBox(width: 12),

                        // Middle Content or Swiped Action Tray
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _compactActionsRevealed
                                ? _buildCompactActionTray(notification, colors, font)
                                : _buildCompactRestingRow(notification, colors, font),
                          ),
                        ),
                      ],
                    ),

                    // Inline reply field in compact mode
                    if (_replyingTo != null) ...[
                      const SizedBox(height: 8),
                      _buildInlineReplyField(colors, font),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactRestingRow(NotificationModel notification, ExpressiveThemeColors colors, FontConfig font) {
    return Row(
      key: const ValueKey('compact_resting'),
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                if (notification.title.isNotEmpty) ...[
                  TextSpan(
                    text: '${notification.title}: ',
                    style: font.textStyleBuilder(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
                TextSpan(
                  text: notification.content.isNotEmpty
                      ? notification.content
                      : notification.appName,
                  style: font.textStyleBuilder(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: colors.textSecondary.withValues(alpha: 0.90),
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),

        // Primary Single Action Button (e.g. "Call Back" or "Reply")
        if (notification.actions.isNotEmpty) ...[
          _buildCompactPillButton(
            notification.actions.first.title,
            colors,
            font,
            () {
              final firstAction = notification.actions.first;
              if (firstAction.hasRemoteInput && widget.onReply != null) {
                setState(() => _replyingTo = firstAction);
              } else {
                widget.onActionTap?.call(firstAction);
              }
            },
          ),
          const SizedBox(width: 6),
        ],

        // Right vertical hint tab indicating swipe-to-reveal drawer
        Container(
          width: 4.5,
          height: 24,
          decoration: BoxDecoration(
            color: colors.textSecondary.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactActionTray(NotificationModel notification, ExpressiveThemeColors colors, FontConfig font) {
    return Container(
      key: const ValueKey('compact_tray'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.activePill.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final action in notification.actions) ...[
              _buildCompactPillButton(
                action.title,
                colors,
                font,
                () {
                  HapticFeedback.lightImpact();
                  if (action.hasRemoteInput && widget.onReply != null) {
                    setState(() => _replyingTo = action);
                  } else {
                    widget.onActionTap?.call(action);
                  }
                },
              ),
              const SizedBox(width: 6),
            ],
            if (widget.onSnooze != null) ...[
              _buildCompactPillButton(
                'Snooze',
                colors,
                font,
                () {
                  HapticFeedback.lightImpact();
                  widget.onSnooze!();
                },
              ),
              const SizedBox(width: 6),
            ],
            // Close actions tray button
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _snapCompactTo(revealed: false),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactPillButton(String label, ExpressiveThemeColors colors, FontConfig font, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.isDark ? Colors.white.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.25),
            width: 1.0,
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

  Widget _buildInlineReplyField(ExpressiveThemeColors colors, FontConfig font) {
    return TextField(
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
    );
  }

  // =========================================================================
  // --- STYLE CONTENTS (Android 17, iOS, OneUI, HyperOS) ---
  // =========================================================================

  // --- 1. Android 17 Expressive Style ---
  Widget _buildAndroid17Content(NotificationModel notification, ExpressiveThemeColors colors, FontConfig font) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildAppIcon(notification, size: 24, isCircle: true),
            const SizedBox(width: 8),
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
            Text('•', style: TextStyle(fontSize: 11, color: colors.textSecondary.withValues(alpha: 0.6))),
            const SizedBox(width: 5),
            Text(
              notification.timeAgo,
              style: font.textStyleBuilder(fontSize: 12.0, color: colors.textSecondary),
              maxLines: 1,
            ),
            const Spacer(),
            if (widget.groupCount > 1 && widget.isFirstInGroup) ...[
              _buildGroupBadge(colors, font),
              const SizedBox(width: 6),
            ],
            _buildChevron(colors),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
      ],
    );
  }

  // --- 2. iOS Notification Center Style ---
  Widget _buildIosContent(NotificationModel notification, ExpressiveThemeColors colors, FontConfig font) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAppIcon(notification, size: 38, isSquircle: true),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      notification.appName,
                      style: font.textStyleBuilder(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    notification.timeAgo,
                    style: font.textStyleBuilder(
                      fontSize: 11.5,
                      color: colors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                notification.title,
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
                notification.content,
                style: font.textStyleBuilder(
                  fontSize: 12.5,
                  color: colors.textSecondary,
                ),
                maxLines: _isExpanded ? null : 2,
                overflow: _isExpanded ? TextOverflow.clip : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        _buildChevron(colors),
      ],
    );
  }

  // --- 3. Samsung OneUI Stadium Style ---
  Widget _buildOneUiContent(NotificationModel notification, ExpressiveThemeColors colors, FontConfig font) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.activePill.withValues(alpha: 0.16),
          ),
          child: Center(
            child: _buildAppIcon(notification, size: 24, isCircle: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      notification.appName,
                      style: font.textStyleBuilder(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: colors.activePill,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    notification.timeAgo,
                    style: font.textStyleBuilder(
                      fontSize: 11.0,
                      color: colors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                notification.title,
                style: font.textStyleBuilder(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                notification.content,
                style: font.textStyleBuilder(
                  fontSize: 12.0,
                  color: colors.textSecondary,
                ),
                maxLines: _isExpanded ? null : 1,
                overflow: _isExpanded ? TextOverflow.clip : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        if (widget.groupCount > 1 && widget.isFirstInGroup) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.activePill.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.groupCount}',
              style: font.textStyleBuilder(
                fontSize: 11.0,
                fontWeight: FontWeight.w700,
                color: colors.activePill,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        _buildChevron(colors),
      ],
    );
  }

  // --- 4. HyperOS / Floating Capsule Style ---
  Widget _buildHyperOsContent(NotificationModel notification, ExpressiveThemeColors colors, FontConfig font) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 4.5,
            decoration: BoxDecoration(
              color: colors.activePill,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.activePill.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(notification.appIcon, size: 12, color: colors.activePill),
                          const SizedBox(width: 4),
                          Text(
                            notification.appName,
                            style: font.textStyleBuilder(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: colors.activePill,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      notification.timeAgo,
                      style: font.textStyleBuilder(
                        fontSize: 11.5,
                        color: colors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                    const Spacer(),
                    if (widget.groupCount > 1 && widget.isFirstInGroup) ...[
                      _buildGroupBadge(colors, font),
                      const SizedBox(width: 4),
                    ],
                    _buildChevron(colors),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.title,
                  style: font.textStyleBuilder(
                    fontSize: 14.2,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  notification.content,
                  style: font.textStyleBuilder(
                    fontSize: 12.5,
                    color: colors.textSecondary,
                  ),
                  maxLines: _isExpanded ? null : 2,
                  overflow: _isExpanded ? TextOverflow.clip : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Actions Row for Expanded Notifications ---
  Widget _buildActionsRow(NotificationModel notification, ExpressiveThemeColors colors, FontConfig font) {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: [
        for (final action in notification.actions)
          _buildStyleAdaptiveActionButton(
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
          _buildStyleAdaptiveActionButton(
            'Snooze',
            colors,
            font,
            () {
              HapticFeedback.lightImpact();
              widget.onSnooze!();
            },
          ),
      ],
    );
  }

  Widget _buildStyleAdaptiveActionButton(String label, ExpressiveThemeColors colors, FontConfig font, VoidCallback onTap) {
    switch (widget.style) {
      case NotificationStyle.compact:
        return _buildCompactPillButton(label, colors, font, onTap);

      case NotificationStyle.ios:
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.activePill.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
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

      case NotificationStyle.oneui:
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: colors.inactivePill.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
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

      case NotificationStyle.hyperOS:
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.activePill.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
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

      case NotificationStyle.android17:
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              label,
              style: font.textStyleBuilder(
                fontSize: 12.5,
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

  Widget _buildAppIcon(NotificationModel notification, {required double size, bool isCircle = false, bool isSquircle = false}) {
    final borderRadius = isSquircle ? BorderRadius.circular(size * 0.24) : (isCircle ? BorderRadius.circular(size / 2) : BorderRadius.circular(6));

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: notification.appColor.withValues(alpha: 0.20),
        borderRadius: borderRadius,
      ),
      child: notification.appIconBytes != null
          ? Image.memory(
              notification.appIconBytes!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(notification.appIcon, size: size * 0.55, color: notification.appColor),
              ),
            )
          : Center(
              child: Icon(notification.appIcon, size: size * 0.55, color: notification.appColor),
            ),
    );
  }

  Widget _buildGroupBadge(ExpressiveThemeColors colors, FontConfig font) {
    return Container(
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
    );
  }

  Widget _buildChevron(ExpressiveThemeColors colors) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _isExpanded = !_isExpanded);
      },
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
          size: 19,
          color: colors.textSecondary.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
