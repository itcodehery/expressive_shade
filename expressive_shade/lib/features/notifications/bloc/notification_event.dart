import 'package:equatable/equatable.dart';
import '../../../models/notification_model.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class InitNotificationsEvent extends NotificationEvent {
  const InitNotificationsEvent();
}

class NotificationsUpdatedEvent extends NotificationEvent {
  final List<NotificationModel> notifications;
  const NotificationsUpdatedEvent(this.notifications);

  @override
  List<Object?> get props => [notifications];
}

class DismissNotificationEvent extends NotificationEvent {
  final String id;
  const DismissNotificationEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class DismissAllForAppEvent extends NotificationEvent {
  final String appName;
  const DismissAllForAppEvent(this.appName);

  @override
  List<Object?> get props => [appName];
}

class SetNotificationSilentEvent extends NotificationEvent {
  final NotificationModel notification;
  final bool silent;
  const SetNotificationSilentEvent(this.notification, this.silent);

  @override
  List<Object?> get props => [notification, silent];
}

class SendInlineReplyEvent extends NotificationEvent {
  final NotificationModel notification;
  final NotificationAction action;
  final String replyText;
  const SendInlineReplyEvent(this.notification, this.action, this.replyText);

  @override
  List<Object?> get props => [notification, action, replyText];
}

class ExecuteNotificationActionEvent extends NotificationEvent {
  final NotificationModel notification;
  final NotificationAction action;
  const ExecuteNotificationActionEvent(this.notification, this.action);

  @override
  List<Object?> get props => [notification, action];
}

class SetActiveSettingsCardEvent extends NotificationEvent {
  final String? notificationId;
  const SetActiveSettingsCardEvent(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}
