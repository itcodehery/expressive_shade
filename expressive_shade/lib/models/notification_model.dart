import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Smart AI/Heuristic categorization buckets for notifications.
enum NotificationCategory {
  urgent,
  people,
  updates,
  social,
  promotions,
  other,
}

extension NotificationCategoryX on NotificationCategory {
  String get displayName {
    switch (this) {
      case NotificationCategory.urgent:
        return 'Priority';
      case NotificationCategory.people:
        return 'People';
      case NotificationCategory.updates:
        return 'Updates';
      case NotificationCategory.social:
        return 'Social';
      case NotificationCategory.promotions:
        return 'Promotions';
      case NotificationCategory.other:
        return 'Other';
    }
  }

  String get shortLabel {
    switch (this) {
      case NotificationCategory.urgent:
        return 'Urgent';
      case NotificationCategory.people:
        return 'Chat';
      case NotificationCategory.updates:
        return 'Update';
      case NotificationCategory.social:
        return 'Social';
      case NotificationCategory.promotions:
        return 'Promo';
      case NotificationCategory.other:
        return 'General';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationCategory.urgent:
        return Icons.bolt_rounded;
      case NotificationCategory.people:
        return Icons.forum_rounded;
      case NotificationCategory.updates:
        return Icons.local_shipping_rounded;
      case NotificationCategory.social:
        return Icons.group_rounded;
      case NotificationCategory.promotions:
        return Icons.local_offer_rounded;
      case NotificationCategory.other:
        return Icons.notifications_rounded;
    }
  }

  /// Lower number = higher priority in the notification shade.
  int get priorityRank {
    switch (this) {
      case NotificationCategory.urgent:
        return 0;
      case NotificationCategory.people:
        return 1;
      case NotificationCategory.updates:
        return 2;
      case NotificationCategory.other:
        return 3;
      case NotificationCategory.social:
        return 4;
      case NotificationCategory.promotions:
        return 5;
    }
  }

  bool get isHighPriority =>
      this == NotificationCategory.urgent ||
      this == NotificationCategory.people;

  bool get isLowPriorityBundleable =>
      this == NotificationCategory.promotions ||
      this == NotificationCategory.social;
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
    this.category = NotificationCategory.other,
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
