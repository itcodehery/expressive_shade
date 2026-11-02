import 'package:equatable/equatable.dart';
import '../../../models/shade_mode.dart';
import '../../../models/slider_style.dart';

abstract class ShadeLayoutEvent extends Equatable {
  const ShadeLayoutEvent();

  @override
  List<Object?> get props => [];
}

class SetShadeModeEvent extends ShadeLayoutEvent {
  final ShadeMode mode;
  const SetShadeModeEvent(this.mode);

  @override
  List<Object?> get props => [mode];
}

class SetSliderStyleEvent extends ShadeLayoutEvent {
  final SliderStyle style;
  const SetSliderStyleEvent(this.style);

  @override
  List<Object?> get props => [style];
}

class SetSplitTabIndexEvent extends ShadeLayoutEvent {
  final int index;
  const SetSplitTabIndexEvent(this.index);

  @override
  List<Object?> get props => [index];
}

class SetUnifiedQsExpandedEvent extends ShadeLayoutEvent {
  final bool isExpanded;
  const SetUnifiedQsExpandedEvent(this.isExpanded);

  @override
  List<Object?> get props => [isExpanded];
}

class ToggleUnifiedQsExpandedEvent extends ShadeLayoutEvent {
  const ToggleUnifiedQsExpandedEvent();
}

class SetEditModeEvent extends ShadeLayoutEvent {
  final bool isEditing;
  final String? selectedTileId;
  const SetEditModeEvent(this.isEditing, {this.selectedTileId});

  @override
  List<Object?> get props => [isEditing, selectedTileId];
}

class SelectEditTileEvent extends ShadeLayoutEvent {
  final String tileId;
  const SelectEditTileEvent(this.tileId);

  @override
  List<Object?> get props => [tileId];
}

class SetSmartUnorganizedEvent extends ShadeLayoutEvent {
  final bool isUnorganized;
  const SetSmartUnorganizedEvent(this.isUnorganized);

  @override
  List<Object?> get props => [isUnorganized];
}

class MarkShadeOpenedEvent extends ShadeLayoutEvent {
  const MarkShadeOpenedEvent();
}
