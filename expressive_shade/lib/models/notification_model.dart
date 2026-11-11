import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Smart AI/Heuristic categorization buckets for notifications.
enum NotificationCategory {
  realtime,
  security,
  conversations,
  socials,
  updates,
  promotions,
  silent;

  // Compatibility aliases
  static const NotificationCategory urgent = NotificationCategory.realtime;
  static const NotificationCategory people = NotificationCategory.conversations;
  static const NotificationCategory social = NotificationCategory.socials;
  static const NotificationCategory other = NotificationCategory.silent;

  static NotificationCategory fromString(String? name) {
    if (name == null || name.isEmpty) return NotificationCategory.silent;
    final lower = name.trim().toLowerCase();
    switch (lower) {
      case 'realtime':
      case 'urgent':
        return NotificationCategory.realtime;
      case 'security':
        return NotificationCategory.security;
      case 'conversations':
      case 'conversation':
      case 'people':
      case 'chat':
        return NotificationCategory.conversations;
      case 'socials':
      case 'social':
        return NotificationCategory.socials;
      case 'updates':
      case 'update':
        return NotificationCategory.updates;
      case 'promotions':
      case 'promotion':
      case 'promo':
        return NotificationCategory.promotions;
      case 'silent':
      case 'other':
      default:
        return NotificationCategory.silent;
    }
  }
}

extension NotificationCategoryX on NotificationCategory {
  String get displayName {
    switch (this) {
      case NotificationCategory.realtime:
        return 'Realtime';
      case NotificationCategory.security:
        return 'Security';
      case NotificationCategory.conversations:
        return 'Conversations';
      case NotificationCategory.socials:
        return 'Social';
      case NotificationCategory.updates:
        return 'Updates';
      case NotificationCategory.promotions:
        return 'Promotions';
      case NotificationCategory.silent:
        return 'Silent';
    }
  }

  String get shortLabel {
    switch (this) {
      case NotificationCategory.realtime:
        return 'Live';
      case NotificationCategory.security:
        return 'Security';
      case NotificationCategory.conversations:
        return 'Chat';
      case NotificationCategory.socials:
        return 'Social';
      case NotificationCategory.updates:
        return 'Update';
      case NotificationCategory.promotions:
        return 'Promo';
      case NotificationCategory.silent:
        return 'Silent';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationCategory.realtime:
        return Icons.bolt_rounded;
      case NotificationCategory.security:
        return Icons.shield_rounded;
      case NotificationCategory.conversations:
        return Icons.forum_rounded;
      case NotificationCategory.socials:
        return Icons.group_rounded;
      case NotificationCategory.updates:
        return Icons.local_shipping_rounded;
      case NotificationCategory.promotions:
        return Icons.local_offer_rounded;
      case NotificationCategory.silent:
        return Icons.notifications_paused_rounded;
    }
  }

  /// Lower number = higher priority in the notification shade.
  /// Realtime: 1, Security: 1, Conversations: 2, Socials: 3, Updates: 4, Promotions: 5, Silent: 6
  int get priorityRank {
    switch (this) {
      case NotificationCategory.realtime:
        return 1;
      case NotificationCategory.security:
        return 1;
      case NotificationCategory.conversations:
        return 2;
      case NotificationCategory.socials:
        return 3;
      case NotificationCategory.updates:
        return 4;
      case NotificationCategory.promotions:
        return 5;
      case NotificationCategory.silent:
        return 6;
    }
  }

  bool get isHighPriority =>
      this == NotificationCategory.realtime ||
      this == NotificationCategory.security ||
      this == NotificationCategory.conversations;

  bool get isLowPriorityBundleable =>
      this == NotificationCategory.promotions ||
      this == NotificationCategory.socials ||
      this == NotificationCategory.silent;
}

/// A single actionable button exposed by a notification.
class NotificationAction {
  /// Position of the action in the original notification (used to trigger it natively).
  final int index;
  final String title;

  /// Whether the action accepts inline text (e.g. Reply).
  final bool hasRemoteInput;

  const NotificationAction({
    required this.index,
    required this.title,
    this.hasRemoteInput = false,
  });
}

class NotificationModel {
  final String id;
  final String appName;
  final String packageName;
  final String title;
  final String content;
  final String timeAgo;
  final int? postTime;
  final IconData appIcon;
  final Color appColor;
  final Uint8List? appIconBytes;
  final List<NotificationAction> actions;
  final bool canOpen;
  final bool isOngoing;
  final bool isClearable;
  final bool isConversation;
  final String? senderAvatar;
  final bool isGroupSummary;
  final String? groupKey;
  final String channelId;
  final String androidCategory;
  final NotificationCategory category;
  final double categoryConfidence;
  final String? extractedOtp;
  final bool isUserCategoryOverride;

  const NotificationModel({
    required this.id,
    required this.appName,
    this.packageName = '',
    required this.title,
    required this.content,
    required this.timeAgo,
    this.postTime,
    required this.appIcon,
    required this.appColor,
    this.appIconBytes,
    this.actions = const [],
    this.canOpen = false,
    this.isOngoing = false,
    this.isClearable = true,
    this.isConversation = false,
    this.senderAvatar,
    this.isGroupSummary = false,
    this.groupKey,
    this.channelId = '',
    this.androidCategory = '',
    this.category = NotificationCategory.silent,
    this.categoryConfidence = 0.5,
    this.extractedOtp,
    this.isUserCategoryOverride = false,
  });

  NotificationModel copyWith({
    String? id,
    String? appName,
    String? packageName,
    String? title,
    String? content,
    String? timeAgo,
    int? postTime,
    IconData? appIcon,
    Color? appColor,
    Uint8List? appIconBytes,
    List<NotificationAction>? actions,
    bool? canOpen,
    bool? isOngoing,
    bool? isClearable,
    bool? isConversation,
    String? senderAvatar,
    bool? isGroupSummary,
    String? groupKey,
    String? channelId,
    String? androidCategory,
    NotificationCategory? category,
    double? categoryConfidence,
    String? extractedOtp,
    bool? isUserCategoryOverride,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      title: title ?? this.title,
      content: content ?? this.content,
      timeAgo: timeAgo ?? this.timeAgo,
      postTime: postTime ?? this.postTime,
      appIcon: appIcon ?? this.appIcon,
      appColor: appColor ?? this.appColor,
      appIconBytes: appIconBytes ?? this.appIconBytes,
      actions: actions ?? this.actions,
      canOpen: canOpen ?? this.canOpen,
      isOngoing: isOngoing ?? this.isOngoing,
      isClearable: isClearable ?? this.isClearable,
      isConversation: isConversation ?? this.isConversation,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      isGroupSummary: isGroupSummary ?? this.isGroupSummary,
      groupKey: groupKey ?? this.groupKey,
      channelId: channelId ?? this.channelId,
      androidCategory: androidCategory ?? this.androidCategory,
      category: category ?? this.category,
      categoryConfidence: categoryConfidence ?? this.categoryConfidence,
      extractedOtp: extractedOtp ?? this.extractedOtp,
      isUserCategoryOverride:
          isUserCategoryOverride ?? this.isUserCategoryOverride,
    );
  }

  /// Relative iOS-style timestamp: "now", "3m ago", "4m ago", "1h ago", "2d ago".
  String get relativeTime {
    if (postTime != null && postTime! > 0) {
      final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(postTime!));
      if (diff.inSeconds < 60) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    }
    final lower = timeAgo.toLowerCase().trim();
    if (lower == 'now' || lower == 'just now') return 'now';
    if (lower.endsWith('m ago') || lower.endsWith('h ago') || lower.endsWith('d ago')) return timeAgo;
    if (lower.contains('m') && lower.contains('ago')) {
      final mMatch = RegExp(r'(\d+)\s*m').firstMatch(lower);
      if (mMatch != null) return '${mMatch.group(1)}m ago';
    }
    // If it's a clock time like 10:32, compare with current time
    final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timeAgo);
    if (timeMatch != null) {
      final h = int.tryParse(timeMatch.group(1)!) ?? 0;
      final m = int.tryParse(timeMatch.group(2)!) ?? 0;
      final now = DateTime.now();
      var notifTime = DateTime(now.year, now.month, now.day, h, m);
      if (notifTime.isAfter(now)) {
        notifTime = notifTime.subtract(const Duration(days: 1));
      }
      final diff = now.difference(notifTime);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }
    return timeAgo;
  }

  /// Clock 24h timestamp for Joined style: "17:46", "13:12", "11:11".
  String get clockTime {
    if (postTime != null && postTime! > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(postTime!);
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    final timeMatch = RegExp(r'(\d{1,2}:\d{2})').firstMatch(timeAgo);
    if (timeMatch != null) return timeMatch.group(1)!;
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  /// Cheap value comparison used to skip UI rebuilds when a refresh brought no changes.
  bool hasSameContentAs(NotificationModel other) =>
      id == other.id &&
      title == other.title &&
      content == other.content &&
      timeAgo == other.timeAgo &&
      isOngoing == other.isOngoing &&
      isClearable == other.isClearable &&
      isGroupSummary == other.isGroupSummary &&
      category == other.category &&
      extractedOtp == other.extractedOtp &&
      isUserCategoryOverride == other.isUserCategoryOverride &&
      appIconBytes == other.appIconBytes &&
      actions.length == other.actions.length;
}
