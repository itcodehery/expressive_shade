import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/shade_theme.dart';
import '../../../services/system_monet_service.dart';
import 'theme_and_font_event.dart';
import 'theme_and_font_state.dart';

class ThemeAndFontBloc extends Bloc<ThemeAndFontEvent, ThemeAndFontState> {
  ThemeAndFontBloc()
      : super(ThemeAndFontState(
          selectedPreset: ThemePreset.presets.firstWhere(
            (p) => p.id == 'forest_green',
            orElse: () => ThemePreset.presets.first,
          ),
        )) {
    on<InitThemeAndFontEvent>(_onInit);
    on<SetThemeModeEvent>(_onSetThemeMode);
    on<ToggleThemeModeEvent>(_onToggleThemeMode);
    on<SetThemeSourceEvent>(_onSetThemeSource);
    on<SelectPresetEvent>(_onSelectPreset);
    on<UpdateCustomThemeEvent>(_onUpdateCustomTheme);
    on<SetFontConfigEvent>(_onSetFontConfig);
    on<SystemMonetColorChangedEvent>(_onSystemMonetColorChanged);

    add(const InitThemeAndFontEvent());
  }

  void _onInit(InitThemeAndFontEvent event, Emitter<ThemeAndFontState> emit) {
    SystemMonetService.getSystemAccentColor().then((color) {
      if (color != null) {
        add(SystemMonetColorChangedEvent(color));
      }
    });
  }

  void _onSetThemeMode(
    SetThemeModeEvent event,
    Emitter<ThemeAndFontState> emit,
  ) {
    emit(state.copyWith(themeMode: event.mode));
  }

  void _onToggleThemeMode(
    ToggleThemeModeEvent event,
    Emitter<ThemeAndFontState> emit,
  ) {
    final nextMode =
        state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    emit(state.copyWith(themeMode: nextMode));
  }

  void _onSetThemeSource(
    SetThemeSourceEvent event,
    Emitter<ThemeAndFontState> emit,
  ) {
    emit(state.copyWith(themeSource: event.source));
  }

  void _onSelectPreset(
    SelectPresetEvent event,
    Emitter<ThemeAndFontState> emit,
  ) {
    emit(state.copyWith(
      selectedPreset: event.preset,
      themeSource: ThemeSource.preset,
    ));
  }

  void _onUpdateCustomTheme(
    UpdateCustomThemeEvent event,
    Emitter<ThemeAndFontState> emit,
  ) {
    emit(state.copyWith(
      customTheme: event.customTheme,
      themeSource: ThemeSource.custom,
    ));
  }

  void _onSetFontConfig(
    SetFontConfigEvent event,
    Emitter<ThemeAndFontState> emit,
  ) {
    emit(state.copyWith(selectedFont: event.font));
  }

  void _onSystemMonetColorChanged(
    SystemMonetColorChangedEvent event,
    Emitter<ThemeAndFontState> emit,
  ) {
    emit(state.copyWith(systemMonetColor: event.color));
  }
}
