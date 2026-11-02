import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../../models/media_player_style.dart';

class MediaSessionState extends Equatable {
  final bool isPlaying;
  final double mediaProgress;
  final String mediaTitle;
  final String mediaArtist;
  final String mediaApp;
  final Uint8List? mediaArtwork;
  final MediaPlayerStyle mediaPlayerStyle;

  const MediaSessionState({
    this.isPlaying = false,
    this.mediaProgress = 0.0,
    this.mediaTitle = 'No media playing',
    this.mediaArtist = 'Tap to open media player',
    this.mediaApp = '',
    this.mediaArtwork,
    this.mediaPlayerStyle = MediaPlayerStyle.expressiveWave,
  });

  bool get hasActiveMedia =>
      mediaTitle.isNotEmpty && mediaTitle != 'No media playing';

  MediaSessionState copyWith({
    bool? isPlaying,
    double? mediaProgress,
    String? mediaTitle,
    String? mediaArtist,
    String? mediaApp,
    Uint8List? mediaArtwork,
    bool clearArtwork = false,
    MediaPlayerStyle? mediaPlayerStyle,
  }) {
    return MediaSessionState(
      isPlaying: isPlaying ?? this.isPlaying,
      mediaProgress: mediaProgress ?? this.mediaProgress,
      mediaTitle: mediaTitle ?? this.mediaTitle,
      mediaArtist: mediaArtist ?? this.mediaArtist,
      mediaApp: mediaApp ?? this.mediaApp,
      mediaArtwork: clearArtwork ? null : (mediaArtwork ?? this.mediaArtwork),
      mediaPlayerStyle: mediaPlayerStyle ?? this.mediaPlayerStyle,
    );
  }

  @override
  List<Object?> get props => [
        isPlaying,
        mediaProgress,
        mediaTitle,
        mediaArtist,
        mediaApp,
        mediaArtwork,
        mediaPlayerStyle,
      ];
}
