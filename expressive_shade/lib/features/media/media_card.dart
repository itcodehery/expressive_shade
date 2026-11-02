import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/font_config.dart';
import '../../models/media_player_style.dart';
import '../../theme/m3_expressive_theme.dart';
import 'styles/compact_pill_style.dart';
import 'styles/cyber_card_style.dart';
import 'styles/expressive_wave_style.dart';
import 'styles/vinyl_turntable_style.dart';

class MediaCard extends StatelessWidget {
  final String title;
  final String artist;
  final String appSource;
  final bool isPlaying;
  final double progress;
  final Uint8List? artwork;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final MediaPlayerStyle style;
  final VoidCallback onPlayPause;
  final VoidCallback? onSkipNext;
  final VoidCallback? onSkipPrevious;
  final ValueChanged<double> onProgressChanged;

  const MediaCard({
    super.key,
    required this.title,
    required this.artist,
    required this.appSource,
    required this.isPlaying,
    required this.progress,
    this.artwork,
    required this.colors,
    required this.font,
    this.style = MediaPlayerStyle.expressiveWave,
    required this.onPlayPause,
    this.onSkipNext,
    this.onSkipPrevious,
    required this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasMedia = isPlaying ||
        (title.isNotEmpty &&
            title != 'No media playing' &&
            title != 'Lord I Know');

    final displayTitle = hasMedia ? title : 'No media playing';
    final displayArtist = hasMedia
        ? (artist.isNotEmpty &&
                artist != 'Tap to open media player' &&
                artist != 'Kid Cudi'
            ? artist
            : '')
        : '';
    final displaySource = appSource.isNotEmpty
        ? appSource
        : (hasMedia ? 'Media Player' : 'Media');

    switch (style) {
      case MediaPlayerStyle.compactPill:
        return CompactPillStyle(
          title: displayTitle,
          artist: displayArtist,
          source: displaySource,
          isPlaying: isPlaying,
          progress: progress,
          artwork: artwork,
          colors: colors,
          font: font,
          onPlayPause: onPlayPause,
          onSkipNext: onSkipNext,
          onSkipPrevious: onSkipPrevious,
          onProgressChanged: onProgressChanged,
        );
      case MediaPlayerStyle.vinylTurntable:
        return VinylTurntableStyle(
          title: displayTitle,
          artist: displayArtist,
          source: displaySource,
          isPlaying: isPlaying,
          progress: progress,
          artwork: artwork,
          colors: colors,
          font: font,
          onPlayPause: onPlayPause,
          onSkipNext: onSkipNext,
          onSkipPrevious: onSkipPrevious,
          onProgressChanged: onProgressChanged,
        );
      case MediaPlayerStyle.cyberCard:
        return CyberCardStyle(
          title: displayTitle,
          artist: displayArtist,
          source: displaySource,
          isPlaying: isPlaying,
          progress: progress,
          artwork: artwork,
          colors: colors,
          font: font,
          onPlayPause: onPlayPause,
          onSkipNext: onSkipNext,
          onSkipPrevious: onSkipPrevious,
          onProgressChanged: onProgressChanged,
        );
      case MediaPlayerStyle.expressiveWave:
        return ExpressiveWaveStyle(
          title: displayTitle,
          artist: displayArtist,
          source: displaySource,
          isPlaying: isPlaying,
          progress: progress,
          artwork: artwork,
          colors: colors,
          font: font,
          onPlayPause: onPlayPause,
          onSkipNext: onSkipNext,
          onSkipPrevious: onSkipPrevious,
          onProgressChanged: onProgressChanged,
        );
    }
  }
}
