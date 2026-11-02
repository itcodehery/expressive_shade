import 'package:get_it/get_it.dart';
import '../../services/system_hardware_service.dart';
import '../../services/system_media_service.dart';
import '../../services/system_monet_service.dart';
import '../../services/system_notification_service.dart';
import '../../services/system_permissions_service.dart';
import '../../services/system_settings_service.dart';
import '../../features/hardware/bloc/hardware_bloc.dart';
import '../../features/media/bloc/media_session_bloc.dart';
import '../../features/notifications/bloc/notification_bloc.dart';
import '../../features/shade_modes/bloc/shade_layout_bloc.dart';
import '../../features/theming/bloc/theme_and_font_bloc.dart';

final sl = GetIt.instance;

Future<void> setupLocator() async {
  // 1. Native Platform Services (Singletons)
  if (!sl.isRegistered<SystemHardwareService>()) {
    sl.registerLazySingleton<SystemHardwareService>(() => SystemHardwareService());
  }
  if (!sl.isRegistered<SystemNotificationService>()) {
    sl.registerLazySingleton<SystemNotificationService>(() => SystemNotificationService());
  }
  if (!sl.isRegistered<SystemMediaService>()) {
    sl.registerLazySingleton<SystemMediaService>(() => SystemMediaService());
  }
  if (!sl.isRegistered<SystemMonetService>()) {
    sl.registerLazySingleton<SystemMonetService>(() => SystemMonetService());
  }
  if (!sl.isRegistered<SystemPermissionsService>()) {
    sl.registerLazySingleton<SystemPermissionsService>(() => SystemPermissionsService());
  }
  if (!sl.isRegistered<SystemSettingsService>()) {
    sl.registerLazySingleton<SystemSettingsService>(() => SystemSettingsService());
  }

  // 2. Domain BLoCs (Lazy Singletons / Factories)
  if (!sl.isRegistered<HardwareBloc>()) {
    sl.registerLazySingleton<HardwareBloc>(() => HardwareBloc());
  }
  if (!sl.isRegistered<NotificationBloc>()) {
    sl.registerLazySingleton<NotificationBloc>(() => NotificationBloc());
  }
  if (!sl.isRegistered<MediaSessionBloc>()) {
    sl.registerLazySingleton<MediaSessionBloc>(() => MediaSessionBloc());
  }
  if (!sl.isRegistered<ThemeAndFontBloc>()) {
    sl.registerLazySingleton<ThemeAndFontBloc>(() => ThemeAndFontBloc());
  }
  if (!sl.isRegistered<ShadeLayoutBloc>()) {
    sl.registerLazySingleton<ShadeLayoutBloc>(() => ShadeLayoutBloc());
  }
}
