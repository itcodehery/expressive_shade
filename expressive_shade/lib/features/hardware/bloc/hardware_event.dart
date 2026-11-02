import 'package:equatable/equatable.dart';
import '../../../models/qs_tile_model.dart';

abstract class HardwareEvent extends Equatable {
  const HardwareEvent();

  @override
  List<Object?> get props => [];
}

class InitHardwareEvent extends HardwareEvent {
  const InitHardwareEvent();
}

class HardwareStateUpdatedEvent extends HardwareEvent {
  final Map<String, dynamic> rawState;
  const HardwareStateUpdatedEvent(this.rawState);

  @override
  List<Object?> get props => [rawState];
}

class ToggleTileEvent extends HardwareEvent {
  final String tileId;
  const ToggleTileEvent(this.tileId);

  @override
  List<Object?> get props => [tileId];
}

class ToggleTileSizeEvent extends HardwareEvent {
  final String tileId;
  const ToggleTileSizeEvent(this.tileId);

  @override
  List<Object?> get props => [tileId];
}

class SetBrightnessEvent extends HardwareEvent {
  final double brightness;
  const SetBrightnessEvent(this.brightness);

  @override
  List<Object?> get props => [brightness];
}

class SetVolumeEvent extends HardwareEvent {
  final double volume;
  const SetVolumeEvent(this.volume);

  @override
  List<Object?> get props => [volume];
}

class ReorderTilesEvent extends HardwareEvent {
  final int oldIndex;
  final int newIndex;
  const ReorderTilesEvent(this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class SetNetworkTileStyleEvent extends HardwareEvent {
  final NetworkTileStyle style;
  const SetNetworkTileStyleEvent(this.style);

  @override
  List<Object?> get props => [style];
}

class UpdateTilesListEvent extends HardwareEvent {
  final List<QsTileModel> tiles;
  const UpdateTilesListEvent(this.tiles);

  @override
  List<Object?> get props => [tiles];
}
