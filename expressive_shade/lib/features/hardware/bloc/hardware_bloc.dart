import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/qs_tile_model.dart';
import '../../../services/system_hardware_service.dart';
import '../../../services/system_settings_service.dart';
import 'hardware_event.dart';
import 'hardware_state.dart';

class HardwareBloc extends Bloc<HardwareEvent, HardwareState> {
  HardwareBloc()
      : super(HardwareState(tiles: List.from(QsTileModel.defaultTiles))) {
    on<InitHardwareEvent>(_onInit);
    on<HardwareStateUpdatedEvent>(_onHardwareStateUpdated);
    on<ToggleTileEvent>(_onToggleTile);
    on<ToggleTileSizeEvent>(_onToggleTileSize);
    on<SetBrightnessEvent>(_onSetBrightness);
    on<SetVolumeEvent>(_onSetVolume);
    on<ReorderTilesEvent>(_onReorderTiles);
    on<SetNetworkTileStyleEvent>(_onSetNetworkTileStyle);
    on<UpdateTilesListEvent>(_onUpdateTilesList);

    add(const InitHardwareEvent());
  }

  void _onInit(InitHardwareEvent event, Emitter<HardwareState> emit) {
    SystemHardwareService.init();
    SystemHardwareService.onHardwareStateChanged = (rawState) {
      add(HardwareStateUpdatedEvent(rawState));
    };

    SystemHardwareService.getSystemHardwareState().then((res) {
      if (res != null) {
        add(HardwareStateUpdatedEvent(res));
      }
    });
  }

  void _onHardwareStateUpdated(
    HardwareStateUpdatedEvent event,
    Emitter<HardwareState> emit,
  ) {
    final s = event.rawState;
    final wifi = s['wifiEnabled'] as bool? ?? state.wifiEnabled;
    final bt = s['bluetoothEnabled'] as bool? ?? state.bluetoothEnabled;
    final torch = s['flashlightEnabled'] as bool? ?? state.flashlightEnabled;
    final rotate = s['autoRotateEnabled'] as bool? ?? state.autoRotateEnabled;
    final dnd = s['dndEnabled'] as bool? ?? state.dndEnabled;
    final hotspot = s['hotspotEnabled'] as bool? ?? state.hotspotEnabled;
    final mobile = s['mobileDataEnabled'] as bool? ?? state.mobileDataEnabled;
    final carrier = (s['carrierName'] as String?) ?? state.carrierName;

    double? bright = state.brightness;
    if (s['brightness'] != null) {
      bright = ((s['brightness'] as num).toDouble() / 255.0).clamp(0.0, 1.0);
    }
    double? vol = state.volume;
    if (s['volume'] != null) {
      vol = (s['volume'] as num).toDouble().clamp(0.0, 1.0);
    }

    // Sync active flags to corresponding tiles
    final updatedTiles = state.tiles.map((t) {
      if (t.id == 'wifi') {
        return t.copyWith(
          isActive: wifi,
          subtitle: wifi ? 'Connected' : 'Off',
        );
      } else if (t.id == 'bluetooth') {
        return t.copyWith(
          isActive: bt,
          subtitle: bt ? 'On' : 'Off',
        );
      } else if (t.id == 'flashlight') {
        return t.copyWith(
          isActive: torch,
          subtitle: torch ? 'On' : 'Off',
        );
      } else if (t.id == 'autorotate') {
        return t.copyWith(
          isActive: rotate,
          subtitle: rotate ? 'On' : 'Off',
        );
      } else if (t.id == 'dnd') {
        return t.copyWith(
          isActive: dnd,
          subtitle: dnd ? 'On' : 'Off',
        );
      } else if (t.id == 'hotspot') {
        return t.copyWith(
          isActive: hotspot,
          subtitle: hotspot ? 'Sharing' : 'Off',
        );
      } else if (t.id == 'mobile_data') {
        return t.copyWith(
          isActive: mobile,
          subtitle: carrier.isNotEmpty ? carrier : 'Mobile',
        );
      }
      return t;
    }).toList();

    emit(state.copyWith(
      tiles: updatedTiles,
      brightness: bright,
      volume: vol,
      wifiEnabled: wifi,
      bluetoothEnabled: bt,
      flashlightEnabled: torch,
      autoRotateEnabled: rotate,
      dndEnabled: dnd,
      hotspotEnabled: hotspot,
      mobileDataEnabled: mobile,
      carrierName: carrier,
    ));
  }

  void _onToggleTile(ToggleTileEvent event, Emitter<HardwareState> emit) {
    final index = state.tiles.indexWhere((t) => t.id == event.tileId);
    if (index == -1) return;

    final tile = state.tiles[index];
    final newActive = !tile.isActive;
    final updated = List<QsTileModel>.from(state.tiles);

    if (tile.id == 'flashlight') {
      updated[index] = tile.copyWith(
        isActive: newActive,
        subtitle: newActive ? 'On' : 'Off',
      );
      SystemHardwareService.setFlashlight(newActive);
    } else if (tile.id == 'wifi') {
      updated[index] = tile.copyWith(
        isActive: newActive,
        subtitle: newActive ? 'Connected' : 'Off',
      );
      SystemHardwareService.toggleWifi();
    } else if (tile.id == 'bluetooth') {
      updated[index] = tile.copyWith(
        isActive: newActive,
        subtitle: newActive ? 'On' : 'Off',
      );
      SystemHardwareService.toggleBluetooth();
    } else if (tile.id == 'autorotate') {
      updated[index] = tile.copyWith(
        isActive: newActive,
        subtitle: newActive ? 'On' : 'Off',
      );
      SystemHardwareService.toggleAutoRotate();
    } else if (tile.id == 'dnd') {
      updated[index] = tile.copyWith(
        isActive: newActive,
        subtitle: newActive ? 'On' : 'Off',
      );
      SystemHardwareService.toggleDnd();
    } else if (tile.id == 'battery_saver') {
      updated[index] = tile.copyWith(isActive: newActive, subtitle: newActive ? 'Active' : 'Off');
      SystemHardwareService.toggleBatterySaver();
    } else if (tile.id == 'airplane') {
      updated[index] = tile.copyWith(isActive: newActive, subtitle: newActive ? 'On' : 'Off');
      SystemHardwareService.toggleAirplane();
    } else if (tile.id == 'hotspot') {
      updated[index] = tile.copyWith(isActive: newActive, subtitle: newActive ? 'Sharing' : 'Off');
      SystemHardwareService.toggleHotspot();
    } else if (tile.id == 'cast') {
      updated[index] = tile.copyWith(isActive: newActive, subtitle: newActive ? 'Streaming' : 'Off');
      SystemHardwareService.triggerCast();
    } else if (tile.id == 'data_saver') {
      updated[index] = tile.copyWith(isActive: newActive, subtitle: newActive ? 'On' : 'Off');
      SystemHardwareService.toggleDataSaver();
    } else if (tile.id == 'extra_dim') {
      updated[index] = tile.copyWith(isActive: newActive, subtitle: newActive ? 'Dimmed' : 'Off');
      SystemHardwareService.toggleExtraDim();
    } else if (tile.id == 'qr_scanner') {
      SystemHardwareService.openQrScanner();
    } else if (tile.id == 'location') {
      updated[index] = tile.copyWith(isActive: newActive, subtitle: newActive ? 'Precise' : 'Off');
      SystemHardwareService.toggleLocation();
    } else if (tile.id == 'night_light') {
      updated[index] = tile.copyWith(isActive: newActive, subtitle: newActive ? 'Warm' : 'Off');
      SystemHardwareService.toggleNightLight();
    } else if (tile.id == 'modes') {
      updated[index] = tile.copyWith(isActive: newActive, subtitle: newActive ? 'Focus' : 'Normal');
      if (newActive) {
        SystemHardwareService.setZenMode('focus');
      } else {
        SystemHardwareService.setZenMode('normal');
      }
    } else if (tile.id == 'nfc') {
      updated[index] = tile.copyWith(isActive: newActive, subtitle: newActive ? 'On' : 'Off');
      SystemHardwareService.openNfcSettings();
    } else if (tile.id == 'calculator') {
      SystemHardwareService.openCalculator();
    } else if (tile.id == 'alarm' || tile.id == 'timer' || tile.id == 'stopwatch') {
      SystemHardwareService.openAlarm();
    } else {
      String? newSubtitle = newActive ? 'On' : 'Off';
      if (tile.id == 'vpn') {
        newSubtitle = newActive ? 'Connected' : 'Disconnected';
      } else if (tile.id == 'modes') {
        newSubtitle = newActive ? 'Focus' : 'Normal';
      } else if (tile.id == 'cast') {
        newSubtitle = newActive ? 'Streaming' : 'Off';
      } else if (tile.id == 'extra_dim') {
        newSubtitle = newActive ? 'Dimmed' : 'Off';
      } else if (tile.id == 'screen_record') {
        newSubtitle = newActive ? 'Recording' : 'Record';
      } else if (tile.id == 'camera_privacy') {
        newSubtitle = newActive ? 'Blocked' : 'Unblocked';
      } else if (tile.id == 'mic_privacy') {
        newSubtitle = newActive ? 'Blocked' : 'Unblocked';
      } else if (tile.id == 'sensitive_notifs') {
        newSubtitle = newActive ? 'Visible' : 'Hidden';
      } else if (tile.id == 'device_controls') {
        newSubtitle = newActive ? 'Connected' : 'Home';
      } else if (tile.id == 'one_handed') {
        newSubtitle = newActive ? 'On' : 'Off';
      } else if (tile.id == 'talkback') {
        newSubtitle = newActive ? 'On' : 'Off';
      } else if (tile.id == 'high_contrast') {
        newSubtitle = newActive ? 'On' : 'Off';
      } else if (tile.id == 'magnification') {
        newSubtitle = newActive ? 'On' : 'Off';
      }

      updated[index] = tile.copyWith(
        isActive: newActive,
        subtitle: newSubtitle,
      );
    }

    emit(state.copyWith(tiles: updated));
  }

  void _onToggleTileSize(ToggleTileSizeEvent event, Emitter<HardwareState> emit) {
    final index = state.tiles.indexWhere((t) => t.id == event.tileId);
    if (index == -1) return;

    final tile = state.tiles[index];
    final updated = List<QsTileModel>.from(state.tiles);
    updated[index] = tile.copyWith(isWide: !tile.isWide);
    SystemSettingsService.saveSettings({
      'tiles': jsonEncode(updated.map((t) => t.toJson()).toList()),
    });
    emit(state.copyWith(tiles: updated));
  }

  void _onSetBrightness(SetBrightnessEvent event, Emitter<HardwareState> emit) {
    final clamped = event.brightness.clamp(0.0, 1.0);
    SystemHardwareService.setBrightness(clamped);
    emit(state.copyWith(brightness: clamped));
  }

  void _onSetVolume(SetVolumeEvent event, Emitter<HardwareState> emit) {
    final clamped = event.volume.clamp(0.0, 1.0);
    SystemHardwareService.setVolume(clamped);
    emit(state.copyWith(volume: clamped));
  }

  void _onReorderTiles(ReorderTilesEvent event, Emitter<HardwareState> emit) {
    if (event.oldIndex < 0 ||
        event.oldIndex >= state.tiles.length ||
        event.newIndex < 0 ||
        event.newIndex > state.tiles.length) {
      return;
    }
    final updated = List<QsTileModel>.from(state.tiles);
    int newIdx = event.newIndex;
    if (event.oldIndex < newIdx) {
      newIdx -= 1;
    }
    final tile = updated.removeAt(event.oldIndex);
    updated.insert(newIdx, tile);
    emit(state.copyWith(tiles: updated));
  }

  void _onSetNetworkTileStyle(
    SetNetworkTileStyleEvent event,
    Emitter<HardwareState> emit,
  ) {
    final style = event.style;
    final updated = List<QsTileModel>.from(state.tiles);
    final wifiIdx = updated.indexWhere((t) => t.id == 'wifi');
    final mobileIdx = updated.indexWhere((t) => t.id == 'mobile_data');

    if (style == NetworkTileStyle.separate) {
      if (wifiIdx != -1) {
        updated[wifiIdx] = updated[wifiIdx].copyWith(
          title: 'Wi-Fi',
          subtitle: updated[wifiIdx].isActive ? 'Connected' : 'Off',
          hasDetails: false,
        );
      }
      if (mobileIdx == -1) {
        final insertPos = (wifiIdx != -1) ? wifiIdx + 1 : 0;
        updated.insert(
          insertPos,
          QsTileModel(
            id: 'mobile_data',
            title: 'Mobile Data',
            subtitle: state.carrierName.isNotEmpty ? state.carrierName : 'Mobile',
            icon: Icons.signal_cellular_alt_rounded,
            isWide: true,
            isActive: true,
            hasDetails: false,
          ),
        );
      }
    } else {
      if (wifiIdx != -1) {
        updated[wifiIdx] = updated[wifiIdx].copyWith(
          title: 'Internet',
          subtitle: updated[wifiIdx].isActive ? 'Wi-Fi' : 'Off',
          hasDetails: true,
        );
      }
      if (mobileIdx != -1) {
        updated.removeAt(mobileIdx);
      }
    }

    emit(state.copyWith(tiles: updated, networkTileStyle: style));
  }

  void _onUpdateTilesList(UpdateTilesListEvent event, Emitter<HardwareState> emit) {
    emit(state.copyWith(tiles: event.tiles));
  }
}
