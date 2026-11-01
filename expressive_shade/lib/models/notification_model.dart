import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String appName;
  final String title;
  final String content;
  final String timeAgo;
  final IconData appIcon;
  final Color appColor;
  final List<String> actions;
  final bool isConversation;
  final String? senderAvatar;

  const NotificationModel({
    required this.id,
    required this.appName,
    required this.title,
    required this.content,
    required this.timeAgo,
    required this.appIcon,
    required this.appColor,
    this.actions = const [],
    this.isConversation = false,
    this.senderAvatar,
  });

  static List<NotificationModel> get sampleNotifications => [
    const NotificationModel(
      id: 'notif_1',
      appName: 'Messages',
      title: 'Matt',
      content: 'Hey! Are we still down for meeting up on Saturday? I think Tyler wanted to as well.',
      timeAgo: 'now',
      appIcon: Icons.message_rounded,
      appColor: Color(0xFF1976D2),
      actions: ['Mark as read', 'Reply'],
      isConversation: true,
    ),
    const NotificationModel(
      id: 'notif_2',
      appName: 'Messages',
      title: 'Rebecca',
      content: 'Are you coming over? I\'m making a bunch of pasta for dinner tonight!',
      timeAgo: '5m',
      appIcon: Icons.message_rounded,
      appColor: Color(0xFF1976D2),
      actions: ['Reply'],
      isConversation: true,
    ),
    const NotificationModel(
      id: 'notif_3',
      appName: 'Calendar',
      title: 'Team Standup & M3 Sprint Review',
      content: 'Starts in 15 minutes in room 4B or Google Meet',
      timeAgo: '12m',
      appIcon: Icons.calendar_today_rounded,
      appColor: Color(0xFF0F9D58),
      actions: ['Join Call', 'Snooze'],
      isConversation: false,
    ),
  ];
}
