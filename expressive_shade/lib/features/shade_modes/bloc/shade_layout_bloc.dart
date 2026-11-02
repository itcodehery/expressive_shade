import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/system_settings_service.dart';
import 'shade_layout_event.dart';
import 'shade_layout_state.dart';

class ShadeLayoutBloc extends Bloc<ShadeLayoutEvent, ShadeLayoutState> {
  ShadeLayoutBloc() : super(const ShadeLayoutState()) {
    on<SetShadeModeEvent>(_onSetShadeMode);
    on<SetSliderStyleEvent>(_onSetSliderStyle);
    on<SetSplitTabIndexEvent>(_onSetSplitTabIndex);
    on<SetUnifiedQsExpandedEvent>(_onSetUnifiedQsExpanded);
    on<ToggleUnifiedQsExpandedEvent>(_onToggleUnifiedQsExpanded);
    on<SetEditModeEvent>(_onSetEditMode);
    on<SelectEditTileEvent>(_onSelectEditTile);
    on<SetSmartUnorganizedEvent>(_onSetSmartUnorganizedEvent);
    on<MarkShadeOpenedEvent>(_onMarkShadeOpened);
  }

  void _onSetShadeMode(
    SetShadeModeEvent event,
    Emitter<ShadeLayoutState> emit,
  ) {
    emit(state.copyWith(
      shadeMode: event.mode,
      isUnifiedQsExpanded: false,
    ));
    SystemSettingsService.saveSettings({'shadeMode': event.mode.name});
  }

  void _onSetSliderStyle(
    SetSliderStyleEvent event,
    Emitter<ShadeLayoutState> emit,
  ) {
    emit(state.copyWith(sliderStyle: event.style));
    SystemSettingsService.saveSettings({'sliderStyle': event.style.name});
  }

  void _onSetSplitTabIndex(
    SetSplitTabIndexEvent event,
    Emitter<ShadeLayoutState> emit,
  ) {
    emit(state.copyWith(splitTabIndex: event.index));
  }

  void _onSetUnifiedQsExpanded(
    SetUnifiedQsExpandedEvent event,
    Emitter<ShadeLayoutState> emit,
  ) {
    emit(state.copyWith(isUnifiedQsExpanded: event.isExpanded));
  }

  void _onToggleUnifiedQsExpanded(
    ToggleUnifiedQsExpandedEvent event,
    Emitter<ShadeLayoutState> emit,
  ) {
    emit(state.copyWith(isUnifiedQsExpanded: !state.isUnifiedQsExpanded));
  }

  void _onSetEditMode(
    SetEditModeEvent event,
    Emitter<ShadeLayoutState> emit,
  ) {
    emit(state.copyWith(
      isEditMode: event.isEditing,
      selectedTileId: event.selectedTileId,
      clearSelectedTileId: event.selectedTileId == null,
    ));
  }

  void _onSelectEditTile(
    SelectEditTileEvent event,
    Emitter<ShadeLayoutState> emit,
  ) {
    emit(state.copyWith(selectedTileId: event.tileId));
  }

  void _onSetSmartUnorganizedEvent(
    SetSmartUnorganizedEvent event,
    Emitter<ShadeLayoutState> emit,
  ) {
    emit(state.copyWith(isSmartUnorganized: event.isUnorganized));
  }

  void _onMarkShadeOpened(
    MarkShadeOpenedEvent event,
    Emitter<ShadeLayoutState> emit,
  ) {
    emit(state.copyWith(
      shadeOpenEpoch: DateTime.now().millisecondsSinceEpoch,
    ));
  }
}
