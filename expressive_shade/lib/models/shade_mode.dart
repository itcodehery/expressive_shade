/// Supported shade pull-down modes.
enum ShadeMode {
  /// Split shade: swipe/tap left for Notifications, right for Quick Settings.
  split,

  /// Classic single/unified shade: Quick Settings summary + scrollable Notifications.
  unified,

  /// Compact Matrix: 3-column matrix grid, capsule brightness slider,
  /// categorized Important / Other notifications, and quick actions.
  smart,

  /// NothingOS 5: Modular Bento split shade with 1x1, 1x2, and 2x2 tiles,
  /// vertical sliders, ringer mode pill, and dual media players.
  nothingOs5,
}

extension ShadeModeExtension on ShadeMode {
  bool get isSplitLike =>
      this == ShadeMode.split || this == ShadeMode.nothingOs5;

  String get displayName {
    switch (this) {
      case ShadeMode.split:
        return 'Split Shade (Android 17)';
      case ShadeMode.unified:
        return 'Single Shade (Classic)';
      case ShadeMode.smart:
        return 'Compact Matrix';
      case ShadeMode.nothingOs5:
        return 'NothingOS 5';
    }
  }

  String get description {
    switch (this) {
      case ShadeMode.split:
        return 'Dedicated notifications on left, control center on right';
      case ShadeMode.unified:
        return 'Quick toggles and notifications unified in one scrollable sheet';
      case ShadeMode.smart:
        return '3-column matrix grid, capsule slider, and categorized smart notifications';
      case ShadeMode.nothingOs5:
        return 'Modular Bento split shade with 1×1, 1×2 & 2×2 tiles, vertical sliders, and dual media cards';
    }
  }
}
