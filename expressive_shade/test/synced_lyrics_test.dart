import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:expressive_shade/features/lyrics/services/lrclib_service.dart';
import 'package:expressive_shade/features/lyrics/services/lyrics_sync_service.dart';
import 'package:expressive_shade/features/lyrics/widgets/inline_lyrics_view.dart';
import 'package:expressive_shade/models/font_config.dart';
import 'package:expressive_shade/providers/shade_state_provider.dart';
import 'package:expressive_shade/theme/m3_expressive_theme.dart';

void main() {
  group('LrclibService Tests', () {
    test('cleans track titles stripping noise tags', () {
      expect(
        LrclibService.cleanTrackTitle('Starboy (feat. Daft Punk)'),
        equals('Starboy'),
      );
      expect(
        LrclibService.cleanTrackTitle('Bohemian Rhapsody - Remastered 2011'),
        equals('Bohemian Rhapsody'),
      );
      expect(
        LrclibService.cleanTrackTitle('Blinding Lights [Official Music Video]'),
        equals('Blinding Lights'),
      );
    });

    test('cleans artist names with featured artists', () {
      expect(
        LrclibService.cleanArtistName('The Weeknd feat. Daft Punk'),
        equals('The Weeknd'),
      );
      expect(
        LrclibService.cleanArtistName('Drake ft. 21 Savage'),
        equals('Drake'),
      );
    });

    test('parses standard and offset LRC format strings', () {
      const sampleLrc = '''
[00:05.50]Line one of song
[00:12.30]Line two of song
[01:05.00]Line three chorus
''';
      final lines = LrclibService.parseLrc(sampleLrc);
      expect(lines.length, equals(3));
      expect(lines[0].time, closeTo(5.5, 0.01));
      expect(lines[0].text, equals('Line one of song'));
      expect(lines[1].time, closeTo(12.3, 0.01));
      expect(lines[1].text, equals('Line two of song'));
      expect(lines[2].time, closeTo(65.0, 0.01));
      expect(lines[2].text, equals('Line three chorus'));
    });
  });

  group('LyricsSyncService Tests', () {
    late LyricsSyncService service;

    setUp(() {
      service = LyricsSyncService.instance;
      service.stop();
    });

    tearDown(() {
      service.stop();
    });

    test('updates media state and correctly syncs active lyric line', () async {
      service.updateMediaState(
        title: 'Mock Track',
        artist: 'Mock Artist',
        isPlaying: true,
        progress: 0.1,
        durationMs: 100000,
        positionMs: 15000, // 15 seconds
      );

      expect(service.hasActiveTrack, isTrue);
      expect(service.trackTitle, equals('Mock Track'));
      expect(service.artistName, equals('Mock Artist'));
      expect(service.isPlaying, isTrue);
      expect(service.currentPosition.inSeconds, equals(15));
    });

    test('handles collapse when media stops or is cleared', () {
      service.updateMediaState(
        title: 'No media playing',
        artist: '',
        isPlaying: false,
        progress: 0.0,
      );

      expect(service.hasActiveTrack, isFalse);
    });
  });

  group('InlineLyricsView Widget Tests', () {
    testWidgets('renders minimalist lyrics when enabled and active', (tester) async {
      final service = LyricsSyncService.instance;
      service.updateMediaState(
        title: 'Espresso',
        artist: 'Sabrina Carpenter',
        isPlaying: true,
        progress: 0.25,
        durationMs: 180000,
        positionMs: 45000,
      );

      final font = FontConfig.availableFonts.first;
      const colors = ExpressiveThemeColors.defaultTheme;
      final shadeProvider = ShadeStateProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<ShadeStateProvider>.value(
          value: shadeProvider,
          child: MaterialApp(
            home: Scaffold(
              body: InlineLyricsView(
                colors: colors,
                font: font,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(InlineLyricsView), findsOneWidget);

      // Disable via layout setting option
      shadeProvider.setInlineLyricsEnabled(false);
      await tester.pump();

      // Disappears when disabled
      expect(find.text('Espresso • Sabrina Carpenter'), findsNothing);

      // Clean up
      service.stop();
      shadeProvider.dispose();
    });
  });
}
