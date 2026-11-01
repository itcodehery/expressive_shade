import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notification_model.dart';

class SystemNotificationService {
  static const MethodChannel _channel = MethodChannel('com.expressive_shade/notifications');
  static VoidCallback? _onNotificationsChanged;

  static void initialize(VoidCallback onUpdate) {
    _onNotificationsChanged = onUpdate;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNotificationsChanged') {
        _onNotificationsChanged?.call();
      }
    });
  }

  static Future<List<NotificationModel>> getActiveNotifications() async {
    try {
      final List<dynamic>? rawList = await _channel.invokeMethod<List<dynamic>>('getNotifications');
      if (rawList == null || rawList.isEmpty) {
        return [];
      }

      return rawList.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final id = map['id']?.toString() ?? '';
        final packageName = map['packageName']?.toString() ?? '';
        final appName = map['appName']?.toString() ?? packageName;
        final title = map['title']?.toString() ?? '';
        final content = map['content']?.toString() ?? '';
        final timeAgo = map['timestamp']?.toString() ?? 'Now';
        final rawActions = map['actions'] as List<dynamic>? ?? [];
        final actions = rawActions.map((e) => e.toString()).toList();

        final iconAndColor = _resolveAppVisuals(packageName, appName);

        return NotificationModel(
          id: id,
          appName: appName,
          title: title.isNotEmpty ? title : appName,
          content: content,
          timeAgo: timeAgo,
          appIcon: iconAndColor.icon,
          appColor: iconAndColor.color,
          actions: actions,
          isConversation: _isMessagingApp(packageName),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> cancelNotification(String id) async {
    try {
      await _channel.invokeMethod('cancelNotification', {'id': id});
    } catch (_) {}
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _channel.invokeMethod('cancelAllNotifications');
    } catch (_) {}
  }

  static bool _isMessagingApp(String pkg) {
    final lower = pkg.toLowerCase();
    return lower.contains('message') ||
        lower.contains('whatsapp') ||
        lower.contains('telegram') ||
        lower.contains('signal') ||
        lower.contains('discord') ||
        lower.contains('slack');
  }

  static ({IconData icon, Color color}) _resolveAppVisuals(String pkg, String name) {
    final lower = (pkg + name).toLowerCase();
    if (lower.contains('whatsapp')) {
      return (icon: Icons.chat_rounded, color: const Color(0xFF25D366));
    } else if (lower.contains('telegram')) {
      return (icon: Icons.send_rounded, color: const Color(0xFF0088CC));
    } else if (lower.contains('gmail') || lower.contains('mail')) {
      return (icon: Icons.email_rounded, color: const Color(0xFFEA4335));
    } else if (lower.contains('calendar')) {
      return (icon: Icons.calendar_today_rounded, color: const Color(0xFF4285F4));
    } else if (lower.contains('message') || lower.contains('sms')) {
      return (icon: Icons.message_rounded, color: const Color(0xFF1976D2));
    } else if (lower.contains('spotify') || lower.contains('music')) {
      return (icon: Icons.music_note_rounded, color: const Color(0xFF1DB954));
    } else if (lower.contains('youtube')) {
      return (icon: Icons.play_arrow_rounded, color: const Color(0xFFFF0000));
    } else {
      return (icon: Icons.notifications_rounded, color: const Color(0xFF6750A4));
    }
  }
}
