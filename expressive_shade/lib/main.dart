import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'core/di/injection.dart';
import 'features/hardware/bloc/hardware_bloc.dart';
import 'features/media/bloc/media_session_bloc.dart';
import 'features/notifications/bloc/notification_bloc.dart';
import 'features/shade_modes/bloc/shade_layout_bloc.dart';
import 'features/theming/bloc/theme_and_font_bloc.dart';
import 'providers/shade_state_provider.dart';
import 'screens/home_screen.dart';
import 'screens/shade_overlay_screen.dart';
import 'theme/m3_expressive_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  runApp(const ExpressiveShadeApp());
}

class ExpressiveShadeApp extends StatelessWidget {
  const ExpressiveShadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HardwareBloc>(create: (_) => sl<HardwareBloc>()),
        BlocProvider<NotificationBloc>(create: (_) => sl<NotificationBloc>()),
        BlocProvider<MediaSessionBloc>(create: (_) => sl<MediaSessionBloc>()),
        BlocProvider<ThemeAndFontBloc>(create: (_) => sl<ThemeAndFontBloc>()),
        BlocProvider<ShadeLayoutBloc>(create: (_) => sl<ShadeLayoutBloc>()),
      ],
      child: ChangeNotifierProvider(
        create: (_) => ShadeStateProvider(),
        child: Selector<ShadeStateProvider, ThemeData>(
          selector: (_, state) {
            final themeColors = ExpressiveThemeColors.fromSettings(
              source: state.themeSource,
              preset: state.selectedPreset,
              custom: state.customTheme,
              systemMonetColor: state.systemMonetColor,
            );
            return themeColors.toThemeData(state.selectedFont);
          },
          builder: (context, themeData, _) {
            return MaterialApp(
              title: 'ExpressiveShade',
              debugShowCheckedModeBanner: false,
              theme: themeData,
              onGenerateRoute: (settings) {
                final uri = Uri.parse(settings.name ?? '/');
                if (uri.path == '/overlay') {
                  final target =
                      uri.queryParameters['target'] ?? 'quick_settings';
                  return PageRouteBuilder(
                    opaque: false,
                    barrierColor: Colors.transparent,
                    pageBuilder: (_, __, ___) =>
                        ShadeOverlayScreen(initialTarget: target),
                    settings: settings,
                  );
                }
                return MaterialPageRoute(
                  builder: (_) => const HomeScreen(),
                  settings: settings,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
