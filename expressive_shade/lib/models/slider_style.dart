/// Visual styles for Quick Settings brightness & volume sliders.
enum SliderStyle {
  /// Continuous filled capsule where the thumb is the smooth rounded end of the fill.
  continuousPill,

  /// Active fill with a distinct separated vertical line indicator at the thumb position.
  separatedBar,
}

extension SliderStyleExtension on SliderStyle {
  String get displayName {
    switch (this) {
      case SliderStyle.continuousPill:
        return 'Continuous Pill';
      case SliderStyle.separatedBar:
        return 'Separated Bar Indicator';
    }
  }

  String get description {
    switch (this) {
      case SliderStyle.continuousPill:
        return 'Seamless smooth capsule fill';
      case SliderStyle.separatedBar:
        return 'Tactile fill with separated vertical line indicator';
    }
  }
}
