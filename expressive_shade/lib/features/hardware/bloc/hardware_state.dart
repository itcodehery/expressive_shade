import 'package:equatable/equatable.dart';
import '../../../models/qs_tile_model.dart';

class HardwareState extends Equatable {
  final List<QsTileModel> tiles;
  final double brightness;
  final double volume;
  final bool wifiEnabled;
  final bool bluetoothEnabled;
  final bool flashlightEnabled;
  final bool autoRotateEnabled;
  final bool dndEnabled;
  final bool hotspotEnabled;
  final bool mobileDataEnabled;
  final String carrierName;
  final NetworkTileStyle networkTileStyle;

  const HardwareState({
    required this.tiles,
    this.brightness = 0.65,
    this.volume = 0.40,
    this.wifiEnabled = false,
    this.bluetoothEnabled = false,
    this.flashlightEnabled = false,
    this.autoRotateEnabled = false,
    this.dndEnabled = false,
    this.hotspotEnabled = false,
    this.mobileDataEnabled = false,
    this.carrierName = '',
    this.networkTileStyle = NetworkTileStyle.unified,
  });

  HardwareState copyWith({
    List<QsTileModel>? tiles,
    double? brightness,
    double? volume,
    bool? wifiEnabled,
    bool? bluetoothEnabled,
    bool? flashlightEnabled,
    bool? autoRotateEnabled,
    bool? dndEnabled,
    bool? hotspotEnabled,
    bool? mobileDataEnabled,
    String? carrierName,
    NetworkTileStyle? networkTileStyle,
  }) {
    return HardwareState(
      tiles: tiles ?? this.tiles,
      brightness: brightness ?? this.brightness,
      volume: volume ?? this.volume,
      wifiEnabled: wifiEnabled ?? this.wifiEnabled,
      bluetoothEnabled: bluetoothEnabled ?? this.bluetoothEnabled,
      flashlightEnabled: flashlightEnabled ?? this.flashlightEnabled,
      autoRotateEnabled: autoRotateEnabled ?? this.autoRotateEnabled,
      dndEnabled: dndEnabled ?? this.dndEnabled,
      hotspotEnabled: hotspotEnabled ?? this.hotspotEnabled,
      mobileDataEnabled: mobileDataEnabled ?? this.mobileDataEnabled,
      carrierName: carrierName ?? this.carrierName,
      networkTileStyle: networkTileStyle ?? this.networkTileStyle,
    );
  }

  @override
  List<Object?> get props => [
        tiles,
        brightness,
        volume,
        wifiEnabled,
        bluetoothEnabled,
        flashlightEnabled,
        autoRotateEnabled,
        dndEnabled,
        hotspotEnabled,
        mobileDataEnabled,
        carrierName,
        networkTileStyle,
      ];
}
