import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expressive_shade/models/app_dock_item.dart';
import 'package:expressive_shade/models/font_config.dart';
import 'package:expressive_shade/models/media_player_style.dart';
import 'package:expressive_shade/models/notification_model.dart';
import 'package:expressive_shade/models/notification_style.dart';
import 'package:expressive_shade/models/slider_style.dart';
import 'package:expressive_shade/providers/shade_state_provider.dart';
import 'package:expressive_shade/theme/m3_expressive_theme.dart';
import 'package:expressive_shade/features/shade_modes/split/split_shade_view.dart';

void main() {
  group('AppDockItem Model Tests', () {
    test('serializes and deserializes correctly', () {
      const item = AppDockItem(
        packageName: 'com.android.chrome',
        appName: 'Chrome',
        colorValue: 0xFF1E88E5,
      );

      final json = item.toJson();
      expect(json['packageName'], 'com.android.chrome');
      expect(json['appName'], 'Chrome');
      expect(json['colorValue'], 0xFF1E88E5);

      final fromJson = AppDockItem.fromJson(json);
      expect(fromJson, equals(item));
      expect(fromJson.color, const Color(0xFF1E88E5));
    });

    test('copyWith works properly', () {
      const item = AppDockItem(
        packageName: 'com.android.chrome',
        appName: 'Chrome',
        colorValue: 0xFF1E88E5,
      );

      final modified = item.copyWith(colorValue: 0xFFE53935);
      expect(modified.packageName, 'com.android.chrome');
      expect(modified.colorValue, 0xFFE53935);
      expect(item.colorValue, 0xFF1E88E5);
    });
  });

  group('ShadeStateProvider App Dock State Tests', () {
    test('defaults to disabled with empty dock apps list', () {
      final state = ShadeStateProvider();
      expect(state.appDockEnabled, isFalse);
      expect(state.appDockApps, isEmpty);
    });

    test('can enable dock and add up to 8 apps', () {
      final state = ShadeStateProvider();
      state.setAppDockEnabled(true);
      expect(state.appDockEnabled, isTrue);

      for (int i = 0; i < 10; i++) {
        state.addAppDockItem(AppDockItem(
          packageName: 'com.test.app$i',
          appName: 'App $i',
          colorValue: 0xFF00897B,
        ));
      }

      // Max 8 apps limit
      expect(state.appDockApps.length, 8);
      expect(state.appDockApps.first.packageName, 'com.test.app0');
      expect(state.appDockApps.last.packageName, 'com.test.app7');
    });

    test('can update tile color and remove apps', () {
      final state = ShadeStateProvider();
      state.addAppDockItem(const AppDockItem(
        packageName: 'com.test.target',
        appName: 'Target',
        colorValue: 0xFF1E88E5,
      ));

      expect(state.appDockApps.first.colorValue, 0xFF1E88E5);
      state.updateAppDockItemColor('com.test.target', 0xFFFF5722);
      expect(state.appDockApps.first.colorValue, 0xFFFF5722);

      state.removeAppDockItem('com.test.target');
      expect(state.appDockApps, isEmpty);
    });
  });

  group('SplitShadeView App Dock Widget Tests', () {
    const colors = ExpressiveThemeColors(
      background: Color(0xFF101418),
      surface: Color(0xFF1A1C1E),
      textPrimary: Colors.white,
      textSecondary: Colors.white70,
      activePill: Color(0xFF90CAF9),
      inactivePill: Color(0xFF37474F),
      onActivePill: Color(0xFF003258),
      onInactivePill: Colors.white,
      sliderTrack: Color(0xFF263238),
      sliderProgress: Color(0xFF90CAF9),
      isDark: true,
    );
    final font = FontConfig.defaultFont;

    testWidgets('App Dock does not appear when disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitShadeView(
              pageController: PageController(),
              colors: colors,
              font: font,
              tiles: const [],
              brightness: 0.5,
              volume: 0.5,
              sliderStyle: SliderStyle.separatedBar,
              onBrightnessChanged: (_) {},
              onVolumeChanged: (_) {},
              onToggleTile: (_) {},
              onLongPressTile: (_) {},
              onResizeTile: (_) {},
              impulseNotifier: null,
              onPageChanged: (_) {},
              mediaTitle: 'Test',
              mediaArtist: 'Artist',
              mediaApp: 'App',
              isPlaying: false,
              mediaProgress: 0.0,
              mediaPlayerStyle: MediaPlayerStyle.expressiveWave,
              onPlayPause: () {},
              onSkipNext: () {},
              onSkipPrevious: () {},
              onProgressChanged: (_) {},
              notifications: const [],
              notificationStyle: NotificationStyle.android17,
              onDismissNotification: (_) {},
              appDockEnabled: false,
              appDockApps: const [
                AppDockItem(
                  packageName: 'com.android.chrome',
                  appName: 'Chrome',
                  colorValue: 0xFF1E88E5,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('App Dock'), findsNothing);
      expect(find.text('Chrome'), findsNothing);
    });

    testWidgets('App Dock displays apps and tapping launches app', (tester) async {
      String? launchedPackage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitShadeView(
              pageController: PageController(),
              colors: colors,
              font: font,
              tiles: const [],
              brightness: 0.5,
              volume: 0.5,
              sliderStyle: SliderStyle.separatedBar,
              onBrightnessChanged: (_) {},
              onVolumeChanged: (_) {},
              onToggleTile: (_) {},
              onLongPressTile: (_) {},
              onResizeTile: (_) {},
              impulseNotifier: null,
              onPageChanged: (_) {},
              mediaTitle: 'Test',
              mediaArtist: 'Artist',
              mediaApp: 'App',
              isPlaying: false,
              mediaProgress: 0.0,
              mediaPlayerStyle: MediaPlayerStyle.expressiveWave,
              onPlayPause: () {},
              onSkipNext: () {},
              onSkipPrevious: () {},
              onProgressChanged: (_) {},
              notifications: const [
                NotificationModel(
                  id: 'notif_1',
                  appName: 'Messages',
                  title: 'Hello',
                  content: 'Test content',
                  timeAgo: 'Now',
                  appIcon: Icons.message,
                  appColor: Colors.blue,
                ),
              ],
              notificationStyle: NotificationStyle.android17,
              onDismissNotification: (_) {},
              appDockEnabled: true,
              appDockApps: const [
                AppDockItem(
                  packageName: 'com.android.chrome',
                  appName: 'Chrome',
                  colorValue: 0xFF1E88E5,
                ),
                AppDockItem(
                  packageName: 'com.spotify.music',
                  appName: 'Spotify',
                  colorValue: 0xFF2E7D32,
                ),
              ],
              onLaunchApp: (pkg) {
                launchedPackage = pkg;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Apps are shown directly as tiles without a separate tile/header saying "App Dock"
      expect(find.text('App Dock'), findsNothing);
      expect(find.text('Chrome'), findsOneWidget);
      expect(find.text('Spotify'), findsOneWidget);

      // Tap Chrome to launch
      await tester.tap(find.text('Chrome'));
      await tester.pumpAndSettle();

      expect(launchedPackage, 'com.android.chrome');
    });
  });
}
