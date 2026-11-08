import 'dart:typed_data';
import 'package:flutter/material.dart';

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
      appIconBytes == other.appIconBytes &&
      actions.length == other.actions.length;
}
