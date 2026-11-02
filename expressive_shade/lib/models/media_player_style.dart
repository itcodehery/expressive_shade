/// Visual styles for the Quick Settings Media Player card.
enum MediaPlayerStyle {
  /// Android 13/14/15/16/17 Squircle with prominent album art, leading play/pause on title, & squiggly waveform seeker.
  expressiveWave,

  /// Compact Pill: Minimalist horizontal capsule with vinyl disc rotation and sleek track info.
  compactPill,

  /// Vinyl Turntable: Retro vinyl record sleeve with spinning vinyl disc protruding.
  vinylTurntable,

  /// Minimal Cyber Modern Card: Clean typography, dual-pill controls, and edge progress ring.
  cyberCard,
}

extension MediaPlayerStyleExtension on MediaPlayerStyle {
  String get displayName {
    switch (this) {
      case MediaPlayerStyle.expressiveWave:
        return 'Expressive Waveform';
      case MediaPlayerStyle.compactPill:
        return 'Compact Pill Capsule';
      case MediaPlayerStyle.vinylTurntable:
        return 'Vinyl Turntable Pro';
      case MediaPlayerStyle.cyberCard:
        return 'Cyber Modern Card';
    }
  }

  String get description {
    switch (this) {
      case MediaPlayerStyle.expressiveWave:
        return 'Signature Android Expressive card with prominent album art, spring play/pause button, & squiggly waveform';
      case MediaPlayerStyle.compactPill:
        return 'Sleek space-saving capsule with spinning mini vinyl badge & inline controls';
      case MediaPlayerStyle.vinylTurntable:
        return 'Grooved vinyl record protruding from the album sleeve with turntable arm vibe';
      case MediaPlayerStyle.cyberCard:
        return 'High-contrast modern dashboard card with rounded pill buttons and clean typography';
    }
  }
}
