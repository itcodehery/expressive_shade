import 'package:equatable/equatable.dart';
import '../../../models/notification_model.dart';

class NotificationState extends Equatable {
  final List<NotificationModel> notifications;
  final Set<String> silentNotificationIds;
  final Set<String> silentApps;
  final String? activeSettingsNotifId;

  const NotificationState({
    this.notifications = const [],
    this.silentNotificationIds = const {},
    this.silentApps = const {},
    this.activeSettingsNotifId,
  });

  bool isSilent(NotificationModel notif) {
    return silentNotificationIds.contains(notif.id) ||
        silentApps.contains(notif.appName) ||
        (notif.packageName.isNotEmpty && silentApps.contains(notif.packageName));
  }

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    Set<String>? silentNotificationIds,
    Set<String>? silentApps,
    String? activeSettingsNotifId,
    bool clearActiveSettingsCard = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      silentNotificationIds: silentNotificationIds ?? this.silentNotificationIds,
      silentApps: silentApps ?? this.silentApps,
      activeSettingsNotifId: clearActiveSettingsCard
          ? null
          : (activeSettingsNotifId ?? this.activeSettingsNotifId),
    );
  }

  @override
  List<Object?> get props => [
        notifications,
        silentNotificationIds,
        silentApps,
        activeSettingsNotifId,
      ];
}
