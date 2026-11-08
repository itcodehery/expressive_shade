import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../services/system_media_service.dart';
import '../models/lyric_model.dart';
import 'lrclib_service.dart';

class LyricsSyncService extends ChangeNotifier {
  static final LyricsSyncService _instance = LyricsSyncService._internal();
  factory LyricsSyncService() => _instance;
  static LyricsSyncService get instance => _instance;

  LyricsSyncService._internal();

  // Playback state
  String? _trackTitle;
  String? _artistName;
  String? _albumName;
  Duration _trackDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;
  bool _isLoadingLyrics = false;
  bool _isVisible = true;
  bool _isExpanded = false;

  SongLyrics? _currentLyrics;
  int _currentLyricIndex = -1;
  Timer? _positionTimer;
  DateTime? _lastSyncTimestamp;

  // In-memory cache for fast lookups
  final Map<String, SongLyrics> _lyricsCache = {};

  // Getters
  String? get trackTitle => _trackTitle;
  String? get artistName => _artistName;
  String? get albumName => _albumName;
  Duration get trackDuration => _trackDuration;
  Duration get currentPosition => _currentPosition;
  bool get isPlaying => _isPlaying;
  bool get isLoadingLyrics => _isLoadingLyrics;
  bool get isVisible => _isVisible;
  bool get isExpanded => _isExpanded;
  SongLyrics? get currentLyrics => _currentLyrics;
  int get currentLyricIndex => _currentLyricIndex;

  bool get hasActiveTrack =>
      _trackTitle != null &&
      _trackTitle!.trim().isNotEmpty &&
      _trackTitle != 'No media playing' &&
      _trackTitle != 'Unknown Title';

  bool get hasLyrics => _currentLyrics != null;
  bool get isSynced => _currentLyrics?.isSynced ?? false;

  String get currentLyricText {
    if (_currentLyrics == null) {
      if (_isLoadingLyrics) return 'Loading lyrics...';
      return _trackTitle != null ? '$_trackTitle • $_artistName' : 'No track playing';
    }
    if (!_currentLyrics!.isSynced) {
      return _currentLyrics!.rawPlainLyrics?.split('\n').firstWhere(
                (l) => l.trim().isNotEmpty,
                orElse: () => 'Lyrics available (unsynced)',
              ) ??
          'Lyrics available (unsynced)';
    }
    if (_currentLyricIndex >= 0 && _currentLyricIndex < _currentLyrics!.lines.length) {
      final text = _currentLyrics!.lines[_currentLyricIndex].text.trim();
      return text.isEmpty ? '♪ ♪ ♪' : text;
    }
    return '♪ ♪ ♪';
  }

  String get nextLyricText {
    if (_currentLyrics != null &&
        _currentLyrics!.isSynced &&
        _currentLyricIndex + 1 < _currentLyrics!.lines.length) {
      final next = _currentLyrics!.lines[_currentLyricIndex + 1].text.trim();
      return next.isEmpty ? '...' : next;
    }
    return '';
  }

  void setVisible(bool visible) {
    _isVisible = visible;
    notifyListeners();
  }

  void toggleExpanded() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }

  void setExpanded(bool expanded) {
    _isExpanded = expanded;
    notifyListeners();
  }

  void start() {
    refreshFromSystem();
  }

  void stop() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Future<void> refreshFromSystem() async {
    final media = await SystemMediaService.getMediaState();
    if (media != null) {
      updateMediaState(
        title: media.title,
        artist: media.artist,
        album: media.album,
        isPlaying: media.isPlaying,
        progress: media.progress,
        durationMs: media.durationMs,
        positionMs: media.positionMs,
      );
    }
  }

  void updateMediaState({
    required String title,
    required String artist,
    String album = '',
    required bool isPlaying,
    required double progress,
    int durationMs = 0,
    int positionMs = 0,
  }) {
    final cleanTitle = title.trim();
    final cleanArtist = artist.trim().isNotEmpty ? artist.trim() : 'Unknown Artist';

    if (cleanTitle.isEmpty || cleanTitle == 'No media playing') {
      _trackTitle = null;
      _artistName = null;
      _isPlaying = false;
      _currentLyrics = null;
      _currentLyricIndex = -1;
      stop();
      notifyListeners();
      return;
    }

    final isNewTrack = (cleanTitle != _trackTitle || cleanArtist != _artistName);

    _trackTitle = cleanTitle;
    _artistName = cleanArtist;
    _albumName = album;
    _isPlaying = isPlaying;

    if (_isPlaying) {
      _startPositionTicker();
    } else {
      stop();
    }

    if (durationMs > 0) {
      _trackDuration = Duration(milliseconds: durationMs);
    } else if (progress > 0 && _trackDuration > Duration.zero) {
      // keep duration
    }

    if (positionMs > 0) {
      _currentPosition = Duration(milliseconds: positionMs);
      _lastSyncTimestamp = DateTime.now();
    } else if (progress > 0 && _trackDuration > Duration.zero) {
      _currentPosition = Duration(milliseconds: (_trackDuration.inMilliseconds * progress).toInt());
      _lastSyncTimestamp = DateTime.now();
    }

    if (isNewTrack) {
      _fetchLyricsForTrack(cleanTitle, cleanArtist, _trackDuration);
    } else {
      _syncLyricIndex();
      notifyListeners();
    }
  }

  Future<void> _fetchLyricsForTrack(String title, String artist, Duration duration) async {
    final cacheKey = '$title::$artist'.toLowerCase();
    if (_lyricsCache.containsKey(cacheKey)) {
      _currentLyrics = _lyricsCache[cacheKey];
      _isLoadingLyrics = false;
      _syncLyricIndex();
      notifyListeners();
      return;
    }

    _isLoadingLyrics = true;
    _currentLyrics = null;
    _currentLyricIndex = -1;
    notifyListeners();

    final durSec = duration.inSeconds > 0 ? duration.inSeconds.toDouble() : null;
    final lyrics = await LrclibService.fetchLyrics(
      trackName: title,
      artistName: artist,
      durationSeconds: durSec,
    );

    if (_trackTitle == title) {
      _currentLyrics = lyrics;
      _isLoadingLyrics = false;
      if (lyrics != null) {
        _lyricsCache[cacheKey] = lyrics;
      }
      _syncLyricIndex();
      notifyListeners();
    }
  }

  void _startPositionTicker() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!_isPlaying) return;

      if (_lastSyncTimestamp != null) {
        final elapsed = DateTime.now().difference(_lastSyncTimestamp!);
        if (elapsed.inSeconds > 8) {
          _currentPosition += const Duration(milliseconds: 250);
        } else {
          _currentPosition += const Duration(milliseconds: 250);
        }
      } else {
        _currentPosition += const Duration(milliseconds: 250);
      }

      if (_trackDuration > Duration.zero && _currentPosition > _trackDuration) {
        _currentPosition = _trackDuration;
      }

      _syncLyricIndex();
    });
  }

  void _syncLyricIndex() {
    if (_currentLyrics == null || !_currentLyrics!.isSynced || _currentLyrics!.lines.isEmpty) {
      if (_currentLyricIndex != -1) {
        _currentLyricIndex = -1;
        notifyListeners();
      }
      return;
    }

    final curSeconds = _currentPosition.inMilliseconds / 1000.0;
    final lines = _currentLyrics!.lines;

    int newIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      if (curSeconds >= lines[i].time) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _currentLyricIndex) {
      _currentLyricIndex = newIndex;
      notifyListeners();
    }
  }

  Future<void> seekToLine(LyricLine line) async {
    final targetPosition = Duration(milliseconds: (line.time * 1000).toInt());
    _currentPosition = targetPosition;
    _lastSyncTimestamp = DateTime.now();
    _syncLyricIndex();
    notifyListeners();

    await SystemMediaService.seekToMs((line.time * 1000).toInt());
  }

  Future<void> seekToProgress(double progress) async {
    if (_trackDuration > Duration.zero) {
      final targetMs = (_trackDuration.inMilliseconds * progress.clamp(0.0, 1.0)).toInt();
      _currentPosition = Duration(milliseconds: targetMs);
      _lastSyncTimestamp = DateTime.now();
      _syncLyricIndex();
      notifyListeners();
      await SystemMediaService.seekToMs(targetMs);
    } else {
      await SystemMediaService.seekTo(progress);
    }
  }

  void _scheduleRefreshBurst() {
    Future.delayed(const Duration(milliseconds: 200), refreshFromSystem);
    Future.delayed(const Duration(milliseconds: 500), refreshFromSystem);
    Future.delayed(const Duration(milliseconds: 900), refreshFromSystem);
  }

  Future<void> togglePlayPause() async {
    _isPlaying = !_isPlaying;
    notifyListeners();
    await SystemMediaService.controlMedia('toggle');
    _scheduleRefreshBurst();
  }

  Future<void> skipNext() async {
    await SystemMediaService.controlMedia('next');
    _scheduleRefreshBurst();
  }

  Future<void> skipPrevious() async {
    await SystemMediaService.controlMedia('prev');
    _scheduleRefreshBurst();
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    super.dispose();
  }
}
