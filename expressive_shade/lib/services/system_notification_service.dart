import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notification_model.dart';
import 'smart_notification_classifier.dart';

class SystemNotificationService {
  static const MethodChannel _channel = MethodChannel('com.expressive_shade/notifications');
  static final Set<VoidCallback> _listeners = {};

  static void initialize(VoidCallback onUpdate) {
    _listeners.add(onUpdate);
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNotificationsChanged') {
        for (final listener in Set<VoidCallback>.from(_listeners)) {
          try {
            listener();
          } catch (_) {}
        }
      }
    });
  }

  /// App icons by package name (null = package has no retrievable icon).
  static final Map<String, Uint8List?> _iconCache = {};

  static Future<void> _loadIcon(String packageName) async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('getAppIcon', {'packageName': packageName});
      _iconCache[packageName] = raw is Uint8List
          ? raw
          : (raw is List ? Uint8List.fromList(raw.cast<int>()) : null);
    } catch (_) {
      _iconCache[packageName] = null;
    }
  }

  static Future<List<NotificationModel>> getActiveNotifications() async {
    try {
      final List<dynamic>? rawList = await _channel.invokeMethod<List<dynamic>>('getNotifications');
      if (rawList == null || rawList.isEmpty) {
        return [];
      }

      final maps = rawList.map((item) => Map<String, dynamic>.from(item as Map)).toList();

      // Fetch icons only for packages we have not seen yet; they are cached afterwards.
      final missing = maps
          .map((m) => m['packageName']?.toString() ?? '')
          .where((pkg) => pkg.isNotEmpty && !_iconCache.containsKey(pkg))
          .toSet();
      if (missing.isNotEmpty) {
        await Future.wait(missing.map(_loadIcon));
      }

      return maps.map((map) {
        final id = map['id']?.toString() ?? '';
        final packageName = map['packageName']?.toString() ?? '';
        final appName = map['appName']?.toString() ?? packageName;
        final title = map['title']?.toString() ?? '';
        final content = map['content']?.toString() ?? '';
        final timeAgo = map['timestamp']?.toString() ?? 'Now';
        final postTime = (map['postTime'] as num?)?.toInt();
        final rawActions = map['actions'] as List<dynamic>? ?? [];
        final actions = rawActions.whereType<Map>().map((e) {
          final a = Map<String, dynamic>.from(e);
          return NotificationAction(
            index: (a['index'] as num?)?.toInt() ?? 0,
            title: a['title']?.toString() ?? '',
            hasRemoteInput: a['hasRemoteInput'] == true,
          );
        }).toList();

        final Uint8List? appIconBytes = _iconCache[packageName];

        final iconAndColor = _resolveAppVisuals(packageName, appName);
        final channelId = map['channelId']?.toString() ?? '';
        final androidCategory = map['androidCategory']?.toString() ?? '';
        final isMessagingStyle = map['isMessagingStyle'] == true;
        final isConversation = isMessagingStyle || _isMessagingApp(packageName);
        final hasReplyAction = actions.any((a) => a.hasRemoteInput);
        final resolvedTitle = title.isNotEmpty ? title : appName;

        final classification = SmartNotificationClassifier.classify(
          appName: appName,
          packageName: packageName,
          title: resolvedTitle,
          content: content,
          channelId: channelId,
          androidCategory: androidCategory,
          isConversation: isConversation,
          isMessagingStyle: isMessagingStyle,
          hasReplyAction: hasReplyAction,
        );

        return NotificationModel(
          id: id,
          appName: appName,
          packageName: packageName,
          title: resolvedTitle,
          content: content,
          timeAgo: timeAgo,
          postTime: postTime,
          appIcon: iconAndColor.icon,
          appColor: iconAndColor.color,
          appIconBytes: appIconBytes,
          actions: actions,
          canOpen: map['canOpen'] == true,
          isOngoing: map['isOngoing'] == true,
          isClearable: map['isClearable'] == true || (map['isClearable'] == null && map['isOngoing'] != true),
          isConversation: isConversation,
          isGroupSummary: map['isGroupSummary'] == true,
          groupKey: map['groupKey']?.toString(),
          channelId: channelId,
          androidCategory: androidCategory,
          category: classification.category,
          categoryConfidence: classification.confidence,
          extractedOtp: classification.extractedOtp,
          isUserCategoryOverride: classification.isUserOverride,
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

  static Future<bool> performAction(String id, int index, {String? replyText}) async {
    try {
      return await _channel.invokeMethod<bool>('performNotificationAction', {
            'id': id,
            'index': index,
            'replyText': replyText,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openNotification(String id) async {
    try {
      return await _channel.invokeMethod<bool>('openNotification', {'id': id}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> snoozeNotification(String id, Duration duration) async {
    try {
      return await _channel.invokeMethod<bool>('snoozeNotification', {
            'id': id,
            'durationMs': duration.inMilliseconds,
          }) ??
          false;
    } catch (_) {
      return false;
    }
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
