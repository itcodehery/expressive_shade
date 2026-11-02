import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/system_notification_service.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc() : super(const NotificationState()) {
    on<InitNotificationsEvent>(_onInit);
    on<NotificationsUpdatedEvent>(_onNotificationsUpdated);
    on<DismissNotificationEvent>(_onDismissNotification);
    on<DismissAllForAppEvent>(_onDismissAllForApp);
    on<SetNotificationSilentEvent>(_onSetNotificationSilent);
    on<SendInlineReplyEvent>(_onSendInlineReply);
    on<ExecuteNotificationActionEvent>(_onExecuteNotificationAction);
    on<SetActiveSettingsCardEvent>(_onSetActiveSettingsCard);

    add(const InitNotificationsEvent());
  }

  void _onInit(InitNotificationsEvent event, Emitter<NotificationState> emit) {
    SystemNotificationService.initialize(() {
      _loadLiveNotifications();
    });
    _loadLiveNotifications();
  }

  Future<void> _loadLiveNotifications() async {
    final liveList = await SystemNotificationService.getActiveNotifications();
    if (state.notifications.length == liveList.length) {
      var unchanged = true;
      for (var i = 0; i < liveList.length; i++) {
        if (!state.notifications[i].hasSameContentAs(liveList[i])) {
          unchanged = false;
          break;
        }
      }
      if (unchanged) return;
    }

    final filtered = liveList.where((n) {
      final text = '${n.title} ${n.content}'.toLowerCase();
      final isOverlayAlert = text.contains('expressiveshade') &&
          (text.contains('displaying over') ||
              text.contains('displayed over') ||
              text.contains('drawing over') ||
              text.contains('active'));
      return !isOverlayAlert;
    }).toList();

    add(NotificationsUpdatedEvent(filtered));
  }

  void _onNotificationsUpdated(
    NotificationsUpdatedEvent event,
    Emitter<NotificationState> emit,
  ) {
    emit(state.copyWith(notifications: event.notifications));
  }

  void _onDismissNotification(
    DismissNotificationEvent event,
    Emitter<NotificationState> emit,
  ) {
    final updated = state.notifications.where((n) => n.id != event.id).toList();
    SystemNotificationService.cancelNotification(event.id);
    emit(state.copyWith(notifications: updated));
  }

  void _onDismissAllForApp(
    DismissAllForAppEvent event,
    Emitter<NotificationState> emit,
  ) {
    final toRemove =
        state.notifications.where((n) => n.appName == event.appName).toList();
    for (final notif in toRemove) {
      SystemNotificationService.cancelNotification(notif.id);
    }
    final updated =
        state.notifications.where((n) => n.appName != event.appName).toList();
    emit(state.copyWith(notifications: updated));
  }

  void _onSetNotificationSilent(
    SetNotificationSilentEvent event,
    Emitter<NotificationState> emit,
  ) {
    final notif = event.notification;
    final ids = Set<String>.from(state.silentNotificationIds);
    final apps = Set<String>.from(state.silentApps);

    if (event.silent) {
      ids.add(notif.id);
      apps.add(notif.appName);
      if (notif.packageName.isNotEmpty) {
        apps.add(notif.packageName);
      }
    } else {
      ids.remove(notif.id);
      apps.remove(notif.appName);
      if (notif.packageName.isNotEmpty) {
        apps.remove(notif.packageName);
      }
    }

    emit(state.copyWith(
      silentNotificationIds: ids,
      silentApps: apps,
    ));
  }

  Future<void> _onSendInlineReply(
    SendInlineReplyEvent event,
    Emitter<NotificationState> emit,
  ) async {
    await SystemNotificationService.performAction(
      event.notification.id,
      event.action.index,
      replyText: event.replyText,
    );
    _loadLiveNotifications();
  }

  Future<void> _onExecuteNotificationAction(
    ExecuteNotificationActionEvent event,
    Emitter<NotificationState> emit,
  ) async {
    await SystemNotificationService.performAction(
      event.notification.id,
      event.action.index,
    );
    _loadLiveNotifications();
  }

  void _onSetActiveSettingsCard(
    SetActiveSettingsCardEvent event,
    Emitter<NotificationState> emit,
  ) {
    emit(state.copyWith(
      activeSettingsNotifId: event.notificationId,
      clearActiveSettingsCard: event.notificationId == null,
    ));
  }
}
