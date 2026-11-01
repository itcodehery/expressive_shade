/// Supported shade pull-down modes in Android 17 style.
enum ShadeMode {
  /// Split shade: swipe/tap left for Notifications, right for Quick Settings.
  split,

  /// Classic single/unified shade: Quick Settings summary + scrollable Notifications.
  unified,
}

extension ShadeModeExtension on ShadeMode {
  String get displayName {
    switch (this) {
      case ShadeMode.split:
        return 'Split Shade (Android 17)';
      case ShadeMode.unified:
        return 'Single Shade (Classic)';
    }
  }

  String get description {
    switch (this) {
      case ShadeMode.split:
        return 'Dedicated notifications on left, control center on right';
      case ShadeMode.unified:
        return 'Quick toggles and notifications unified in one scrollable sheet';
    }
  }
}
