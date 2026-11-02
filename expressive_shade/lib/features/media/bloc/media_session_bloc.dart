import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/system_media_service.dart';
import 'media_session_event.dart';
import 'media_session_state.dart';

class MediaSessionBloc extends Bloc<MediaSessionEvent, MediaSessionState> {
  MediaSessionBloc() : super(const MediaSessionState()) {
    on<InitMediaSessionEvent>(_onInit);
    on<MediaStateUpdatedEvent>(_onMediaStateUpdated);
    on<TogglePlayPauseEvent>(_onTogglePlayPause);
    on<SkipNextMediaEvent>(_onSkipNextMedia);
    on<SkipPreviousMediaEvent>(_onSkipPreviousMedia);
    on<SeekMediaEvent>(_onSeekMedia);
    on<SetMediaPlayerStyleEvent>(_onSetMediaPlayerStyle);

    add(const InitMediaSessionEvent());
  }

  void _onInit(InitMediaSessionEvent event, Emitter<MediaSessionState> emit) {
    SystemMediaService.initialize(() {
      _loadLiveMedia();
    });
    _loadLiveMedia();
  }

  Future<void> _loadLiveMedia() async {
    final media = await SystemMediaService.getMediaState();
    if (media != null && media.title.isNotEmpty) {
      add(MediaStateUpdatedEvent(
        title: media.title,
        artist: media.artist,
        appName: media.appName,
        isPlaying: media.isPlaying,
        progress: media.progress,
        artwork: media.artwork,
      ));
    }
  }

  void _onMediaStateUpdated(
    MediaStateUpdatedEvent event,
    Emitter<MediaSessionState> emit,
  ) {
    emit(state.copyWith(
      mediaTitle: event.title,
      mediaArtist: event.artist,
      mediaApp: event.appName,
      isPlaying: event.isPlaying,
      mediaProgress: event.progress,
      mediaArtwork: event.artwork,
    ));
  }

  void _onTogglePlayPause(
    TogglePlayPauseEvent event,
    Emitter<MediaSessionState> emit,
  ) {
    final newPlaying = !state.isPlaying;
    SystemMediaService.controlMedia('toggle');
    emit(state.copyWith(isPlaying: newPlaying));
  }

  void _onSkipNextMedia(
    SkipNextMediaEvent event,
    Emitter<MediaSessionState> emit,
  ) {
    SystemMediaService.controlMedia('next');
  }

  void _onSkipPreviousMedia(
    SkipPreviousMediaEvent event,
    Emitter<MediaSessionState> emit,
  ) {
    SystemMediaService.controlMedia('prev');
  }

  void _onSeekMedia(
    SeekMediaEvent event,
    Emitter<MediaSessionState> emit,
  ) {
    final clamped = event.progress.clamp(0.0, 1.0);
    SystemMediaService.seekTo(clamped);
    emit(state.copyWith(mediaProgress: clamped));
  }

  void _onSetMediaPlayerStyle(
    SetMediaPlayerStyleEvent event,
    Emitter<MediaSessionState> emit,
  ) {
    emit(state.copyWith(mediaPlayerStyle: event.style));
  }
}
