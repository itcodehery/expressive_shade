/// Supported shade pull-down modes.
enum ShadeMode {
  /// Split shade: swipe/tap left for Notifications, right for Quick Settings.
  split,

  /// Classic single/unified shade: Quick Settings summary + scrollable Notifications.
  unified,

  /// Compact Matrix: 3-column matrix grid, capsule brightness slider,
  /// categorized Important / Other notifications, and quick actions.
  smart,
}

extension ShadeModeExtension on ShadeMode {
  String get displayName {
    switch (this) {
      case ShadeMode.split:
        return 'Split Shade (Android 17)';
      case ShadeMode.unified:
        return 'Single Shade (Classic)';
      case ShadeMode.smart:
        return 'Compact Matrix';
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
    }
  }
}
