import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/font_config.dart';
import '../../models/notification_model.dart';
import '../../models/notification_style.dart';
import '../../services/smart_notification_classifier.dart';
import '../../theme/m3_expressive_theme.dart';
import 'notification_card.dart';
import 'notification_group_card.dart';

class NotificationList extends StatefulWidget {
  final List<NotificationModel> notifications;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final void Function(String id) onDismiss;
  final void Function(NotificationModel notification, NotificationAction action)?
      onActionTap;
  final void Function(
    NotificationModel notification,
    NotificationAction action,
    String text,
  )? onReply;
  final void Function(NotificationModel notification)? onTap;
  final void Function(NotificationModel notification)? onSnooze;
  final NotificationStyle style;

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
    this.style = NotificationStyle.android17,
  });

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  NotificationCategory? _selectedCategory;
  bool _lowPriorityBundleExpanded = false;
  final ScrollController _chipsScrollController = ScrollController();
  final Map<NotificationCategory?, GlobalKey> _chipKeys = {};

  @override
  void dispose() {
    _chipsScrollController.dispose();
    super.dispose();
  }

  void _handleCategoryDragSelect(
    Offset globalPos,
    List<NotificationCategory?> categories,
  ) {
    for (final cat in categories) {
      final key = _chipKeys[cat];
      final renderBox = key?.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final localPos = renderBox.globalToLocal(globalPos);
        final size = renderBox.size;
        // Expand the touch target by an extra 10px on all sides for effortless swipe selection
        const margin = 10.0;
        final isHit = localPos.dx >= -margin &&
            localPos.dx <= size.width + margin &&
            localPos.dy >= -margin &&
            localPos.dy <= size.height + margin;

        if (isHit) {
          if (_selectedCategory != cat) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedCategory = cat;
            });
            // Ensure newly swiped chip stays visible in scroll view
            final ctx = key?.currentContext;
            if (ctx != null) {
              Scrollable.ensureVisible(
                ctx,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: 0.5,
              );
            }
          }
          break;
        }
      }
    }
  }

  List<NotificationModel> _ensureClassified(List<NotificationModel> input) {
    if (!SmartNotificationClassifier.isEnabled) {
      return input;
    }
    return input.map((n) {
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
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final font = widget.font;

    final classified = _ensureClassified(
      widget.notifications.where((n) => !n.isGroupSummary).toList(),
    );

    if (classified.isEmpty) {
      return _buildEmptyState(colors, font);
    }

    if (!SmartNotificationClassifier.isEnabled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildGroupedCards(classified),
      );
    }

    // Sort by smart priority rank (Urgent -> People -> Updates -> Other -> Social -> Promotions)
    classified.sort(
      (a, b) => a.category.priorityRank.compareTo(b.category.priorityRank),
    );

    // Count notifications per category
    final counts = <NotificationCategory, int>{};
    for (final n in classified) {
      counts[n.category] = (counts[n.category] ?? 0) + 1;
    }

    // Reset filter if the selected category no longer has notifications
    final activeFilter =
        (_selectedCategory != null && (counts[_selectedCategory] ?? 0) > 0)
            ? _selectedCategory
            : null;

    final visibleNotifs = activeFilter == null
        ? classified
        : classified.where((n) => n.category == activeFilter).toList();

    // Separate primary notifications from low-priority bundleable ones when in "All" view
    final List<NotificationModel> primaryNotifs;
    final List<NotificationModel> bundledLowPriority;

    if (activeFilter == null) {
      final low = visibleNotifs
          .where((n) => n.category.isLowPriorityBundleable)
          .toList();
      final high = visibleNotifs
          .where((n) => !n.category.isLowPriorityBundleable)
          .toList();
      if (low.length >= 2 && high.isNotEmpty) {
        primaryNotifs = high;
        bundledLowPriority = low;
      } else {
        primaryNotifs = visibleNotifs;
        bundledLowPriority = const [];
      }
    } else {
      primaryNotifs = visibleNotifs;
      bundledLowPriority = const [];
    }

    final children = <Widget>[];

    // Show smart category filter pills whenever notifications are present
    if (counts.isNotEmpty) {
      children.add(
        _buildCategoryFilterRow(
          counts: counts,
          totalCount: classified.length,
          activeFilter: activeFilter,
          colors: colors,
          font: font,
        ),
      );
      children.add(const SizedBox(height: 10));
    }

    children.addAll(_buildGroupedCards(primaryNotifs));

    // Render auto-collapsed Promotions & Social Smart Digest Bundle at the bottom
    if (bundledLowPriority.isNotEmpty) {
      children.add(
        _buildLowPriorityDigestBundle(
          bundledLowPriority,
          colors,
          font,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  List<Widget> _buildGroupedCards(List<NotificationModel> list) {
    final grouped = <String, List<NotificationModel>>{};
    for (final notif in list) {
      final key = notif.groupKey != null && notif.groupKey!.isNotEmpty
          ? '${notif.packageName}_${notif.groupKey}'
          : (notif.packageName.isNotEmpty ? notif.packageName : notif.appName);
      grouped.putIfAbsent(key, () => []).add(notif);
    }

    final cards = <Widget>[];
    for (final entry in grouped.entries) {
      final appNotifs = entry.value;
      if (appNotifs.length > 1) {
        cards.add(
          NotificationGroupCard(
            key: ValueKey('group_${entry.key}'),
            notifications: appNotifs,
            colors: widget.colors,
            font: widget.font,
            style: widget.style,
            onDismiss: widget.onDismiss,
            onActionTap: widget.onActionTap,
            onReply: widget.onReply,
            onTap: widget.onTap,
            onSnooze: widget.onSnooze,
          ),
        );
      } else {
        final notif = appNotifs.first;
        cards.add(
          NotificationCard(
            key: ValueKey(notif.id),
            notification: notif,
            colors: widget.colors,
            font: widget.font,
            style: widget.style,
            isFirstInGroup: true,
            isLastInGroup: true,
            groupCount: 1,
            onDismiss: () => widget.onDismiss(notif.id),
            onActionTap: widget.onActionTap != null
                ? (a) => widget.onActionTap!(notif, a)
                : null,
            onReply: widget.onReply != null
                ? (a, text) => widget.onReply!(notif, a, text)
                : null,
            onTap: widget.onTap != null ? () => widget.onTap!(notif) : null,
            onSnooze:
                widget.onSnooze != null ? () => widget.onSnooze!(notif) : null,
          ),
        );
      }
    }
    return cards;
  }

  Widget _buildCategoryFilterRow({
    required Map<NotificationCategory, int> counts,
    required int totalCount,
    required NotificationCategory? activeFilter,
    required ExpressiveThemeColors colors,
    required FontConfig font,
  }) {
    final orderedCategories = [
      NotificationCategory.realtime,
      NotificationCategory.security,
      NotificationCategory.conversations,
      NotificationCategory.socials,
      NotificationCategory.updates,
      NotificationCategory.promotions,
      NotificationCategory.silent,
    ].where((c) => (counts[c] ?? 0) > 0).toList();

    // All category options in render order (null represents 'All')
    final allCategoryOptions = <NotificationCategory?>[
      null,
      ...orderedCategories,
    ];

    // Ensure GlobalKey exists for each category chip to enable hit detection during swipe gestures
    for (final cat in allCategoryOptions) {
      _chipKeys.putIfAbsent(cat, () => GlobalKey());
    }

    return Listener(
      onPointerDown: (event) {
        // Immediate selection on pointer down or drag start
        _handleCategoryDragSelect(event.position, allCategoryOptions);
      },
      onPointerMove: (event) {
        // Immediately move to that category as the user swipes over each chip without waiting to release
        _handleCategoryDragSelect(event.position, allCategoryOptions);
      },
      child: SingleChildScrollView(
        controller: _chipsScrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterChip(
              key: _chipKeys[null],
              label: 'All',
              count: totalCount,
              icon: Icons.auto_awesome_rounded,
              isSelected: activeFilter == null,
              colors: colors,
              font: font,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategory = null);
              },
            ),
            for (final cat in orderedCategories) ...[
              const SizedBox(width: 8),
              _buildFilterChip(
                key: _chipKeys[cat],
                label: cat.displayName,
                count: counts[cat]!,
                icon: cat.icon,
                isSelected: activeFilter == cat,
                colors: colors,
                font: font,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    Key? key,
    required String label,
    required int count,
    required IconData icon,
    required bool isSelected,
    required ExpressiveThemeColors colors,
    required FontConfig font,
    required VoidCallback onTap,
  }) {
    final bgColor = isSelected
        ? colors.activePill
        : colors.notificationCardBackground;
    final fgColor = isSelected ? colors.onActivePill : colors.textPrimary;

    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: M3Motion.emphasized,
          // Generous padding and minimum height for comfortable touch targets
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
          constraints: const BoxConstraints(minHeight: 38),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: colors.activePill.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14.5, color: fgColor),
              const SizedBox(width: 6.5),
              Text(
                '$label $count',
                style: font.textStyleBuilder(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLowPriorityDigestBundle(
    List<NotificationModel> bundled,
    ExpressiveThemeColors colors,
    FontConfig font,
  ) {
    final appNames = bundled.map((n) => n.appName).toSet().take(3).join(', ');
    final hasPromo =
        bundled.any((n) => n.category == NotificationCategory.promotions);
    final hasSocial =
        bundled.any((n) => n.category == NotificationCategory.socials);
    final bundleTitle = (hasPromo && hasSocial)
        ? 'Promotions & Social'
        : (hasPromo ? 'Promotions' : 'Social Updates');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(
              () => _lowPriorityBundleExpanded = !_lowPriorityBundleExpanded,
            );
          },
          child: Container(
            margin: EdgeInsets.only(bottom: _lowPriorityBundleExpanded ? 6 : 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.notificationCardBackground,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.activePill.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      hasPromo
                          ? Icons.local_offer_rounded
                          : Icons.group_rounded,
                      size: 16,
                      color: colors.activePill,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bundleTitle,
                        style: font.textStyleBuilder(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        appNames,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: font.textStyleBuilder(
                          fontSize: 12.0,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.activePill.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${bundled.length}',
                    style: font.textStyleBuilder(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: colors.activePill,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_lowPriorityBundleExpanded) ..._buildGroupedCards(bundled),
      ],
    );
  }

  Widget _buildEmptyState(ExpressiveThemeColors colors, FontConfig font) {
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
}
