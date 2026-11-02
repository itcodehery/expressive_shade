import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../models/font_config.dart';
import '../../../models/shade_theme.dart';

abstract class ThemeAndFontEvent extends Equatable {
  const ThemeAndFontEvent();

  @override
  List<Object?> get props => [];
}

class InitThemeAndFontEvent extends ThemeAndFontEvent {
  const InitThemeAndFontEvent();
}

class SetThemeModeEvent extends ThemeAndFontEvent {
  final ThemeMode mode;
  const SetThemeModeEvent(this.mode);

  @override
  List<Object?> get props => [mode];
}

class ToggleThemeModeEvent extends ThemeAndFontEvent {
  const ToggleThemeModeEvent();
}

class SetThemeSourceEvent extends ThemeAndFontEvent {
  final ThemeSource source;
  const SetThemeSourceEvent(this.source);

  @override
  List<Object?> get props => [source];
}

class SelectPresetEvent extends ThemeAndFontEvent {
  final ThemePreset preset;
  const SelectPresetEvent(this.preset);

  @override
  List<Object?> get props => [preset];
}

class UpdateCustomThemeEvent extends ThemeAndFontEvent {
  final CustomThemeData customTheme;
  const UpdateCustomThemeEvent(this.customTheme);

  @override
  List<Object?> get props => [customTheme];
}

class SetFontConfigEvent extends ThemeAndFontEvent {
  final FontConfig font;
  const SetFontConfigEvent(this.font);

  @override
  List<Object?> get props => [font];
}

class SystemMonetColorChangedEvent extends ThemeAndFontEvent {
  final Color? color;
  const SystemMonetColorChangedEvent(this.color);

  @override
  List<Object?> get props => [color];
}
