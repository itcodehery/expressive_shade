import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/shade_state_provider.dart';
import 'screens/home_screen.dart';
import 'screens/shade_overlay_screen.dart';
import 'theme/m3_expressive_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExpressiveShadeApp());
}

class ExpressiveShadeApp extends StatelessWidget {
  const ExpressiveShadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ShadeStateProvider(),
      child: Consumer<ShadeStateProvider>(
        builder: (context, state, _) {
          final isPlatformDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

          final themeColors = ExpressiveThemeColors.fromSettings(
            source: state.themeSource,
            preset: state.selectedPreset,
            custom: state.customTheme,
            systemMonetColor: state.systemMonetColor,
            isSystemDark: isPlatformDark,
          );

          return MaterialApp(
            title: 'ExpressiveShade',
            debugShowCheckedModeBanner: false,
            theme: themeColors.toThemeData(state.selectedFont),
            onGenerateRoute: (settings) {
              final uri = Uri.parse(settings.name ?? '/');
              if (uri.path == '/overlay') {
                final target = uri.queryParameters['target'] ?? 'quick_settings';
                return MaterialPageRoute(
                  builder: (_) => ShadeOverlayScreen(initialTarget: target),
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
    );
  }
}
