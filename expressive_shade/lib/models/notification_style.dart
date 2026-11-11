/// Visual styles for Notification cards in Expressive Shade.
enum NotificationStyle {
  /// Android 17 / modern M3 Expressive style: soft nested curves, circular avatar/app glyph, bold sender, clean text actions.
  android17,

  /// iOS style: sleek squircle app icon, bold header, timestamp on right, subtle glassmorphic surface, and rounded capsule actions.
  ios,

  /// Samsung OneUI style: signature stadium pill capsule card shape, prominent circular app avatar on left, count badge on right, pill chips.
  oneui,

  /// Compact Mode: ultra-compact pill cards with inline primary action; swipe right to reveal actions tray or swipe fully to dismiss.
  compact,

  /// HyperOS / Dynamic Island: vertical left accent bar, mini capsule app badge, floating pill chip actions.
  hyperOS,

  /// Joined Style: Two-column layout with left-aligned time and source column, joined rounded containers, and status badges.
  joined,
}

extension NotificationStyleExtension on NotificationStyle {
  String get displayName {
    switch (this) {
      case NotificationStyle.android17:
        return 'Android 17 Expressive';
      case NotificationStyle.ios:
        return 'iOS Notification Center';
      case NotificationStyle.oneui:
        return 'Samsung OneUI Stadium';
      case NotificationStyle.compact:
        return 'Compact Mode';
      case NotificationStyle.hyperOS:
        return 'HyperOS Floating Pill';
      case NotificationStyle.joined:
        return 'Joined';
    }
  }

  String get description {
    switch (this) {
      case NotificationStyle.android17:
        return 'Modern M3 Expressive container with soft curves, avatar badge, and clean text actions';
      case NotificationStyle.ios:
        return 'Signature iOS squircle app icon, bold header, top-right timestamp, and rounded glass cards';
      case NotificationStyle.oneui:
        return 'Samsung OneUI stadium capsule cards with circular avatar disc and stadium pill buttons';
      case NotificationStyle.compact:
        return 'Ultra-compact cards with inline action; swipe right to reveal actions tray or swipe fully to dismiss';
      case NotificationStyle.hyperOS:
        return 'HyperOS floating capsule with vertical color accent bar, micro-capsule tag, and pill chips';
      case NotificationStyle.joined:
        return 'Two-column layout with left-aligned time & app label, joined card containers, and status badges';
    }
  }
}
