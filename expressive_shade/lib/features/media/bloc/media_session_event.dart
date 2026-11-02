import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../../models/media_player_style.dart';

abstract class MediaSessionEvent extends Equatable {
  const MediaSessionEvent();

  @override
  List<Object?> get props => [];
}

class InitMediaSessionEvent extends MediaSessionEvent {
  const InitMediaSessionEvent();
}

class MediaStateUpdatedEvent extends MediaSessionEvent {
  final String title;
  final String artist;
  final String appName;
  final bool isPlaying;
  final double progress;
  final Uint8List? artwork;

  const MediaStateUpdatedEvent({
    required this.title,
    required this.artist,
    required this.appName,
    required this.isPlaying,
    required this.progress,
    this.artwork,
  });

  @override
  List<Object?> get props => [title, artist, appName, isPlaying, progress, artwork];
}

class TogglePlayPauseEvent extends MediaSessionEvent {
  const TogglePlayPauseEvent();
}

class SkipNextMediaEvent extends MediaSessionEvent {
  const SkipNextMediaEvent();
}

class SkipPreviousMediaEvent extends MediaSessionEvent {
  const SkipPreviousMediaEvent();
}

class SeekMediaEvent extends MediaSessionEvent {
  final double progress;
  const SeekMediaEvent(this.progress);

  @override
  List<Object?> get props => [progress];
}

class SetMediaPlayerStyleEvent extends MediaSessionEvent {
  final MediaPlayerStyle style;
  const SetMediaPlayerStyleEvent(this.style);

  @override
  List<Object?> get props => [style];
}
