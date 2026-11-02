import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/font_config.dart';
import '../models/notification_model.dart';
import '../models/qs_tile_model.dart';
import '../models/shade_mode.dart';
import '../models/shade_theme.dart';
import '../models/slider_style.dart';
import '../services/system_hardware_service.dart';
import '../services/system_media_service.dart';
import '../services/system_monet_service.dart';
import '../services/system_notification_service.dart';
import '../services/system_permissions_service.dart';
import '../services/system_settings_service.dart';

class ShadeStateProvider extends ChangeNotifier {
  static const MethodChannel _overlayEventsChannel = MethodChannel('com.expressive_shade/overlay_events');

  ShadeStateProvider() {
    _loadSystemMonetColor();
    _initSettingsSync();
    _initHardwareSync();
    refreshPermissions();
    _initLiveServices();
  }

  void _initLiveServices() {
    // Listen for top pull-down panel gestures from background overlay service
    _overlayEventsChannel.setMethodCallHandler((call) async {
      if (call.method == 'onPanelTriggered') {
        final target = call.arguments?.toString();
        if (target != null) {
          setTargetPanel(target);
        }
      }
    });

    // Register live notification listener callback
    SystemNotificationService.initialize(() {
      _loadLiveNotifications();
    });

    // Register live media listener callback
    SystemMediaService.initialize(() {
      _loadLiveMedia();
    });
  }

  void _initSettingsSync() {
    SystemSettingsService.initialize((settings) {
      _applySettings(settings);
    });
    loadSavedSettings();
  }

  Future<void> loadSavedSettings() async {
    final saved = await SystemSettingsService.getSettings();
    if (saved != null && saved.isNotEmpty) {
      _applySettings(saved);
    }
  }

  Future<void> applyAndSyncToShade() async {
    _broadcastSettings();
    notifyListeners();
  }

  void _applySettings(Map<String, dynamic> s) {
    if (s['shadeMode'] != null) {
      _shadeMode = (s['shadeMode'].toString() == 'unified') ? ShadeMode.unified : ShadeMode.split;
    }
    if (s['sliderStyle'] != null) {
      final st = s['sliderStyle'].toString();
      _sliderStyle = (st == 'continuousPill' || st == 'continuous')
          ? SliderStyle.continuousPill
          : SliderStyle.separatedBar;
    }
    if (s['themeSource'] != null) {
      final src = s['themeSource'].toString();
      if (src == 'system') {
        _themeSource = ThemeSource.system;
      } else if (src == 'custom') {
        _themeSource = ThemeSource.custom;
      } else {
        _themeSource = ThemeSource.preset;
      }
    }
    if (s['selectedPreset'] != null) {
      final pId = s['selectedPreset'].toString();
      _selectedPreset = ThemePreset.presets.firstWhere(
        (p) => p.id == pId || p.name == pId || p.name.toLowerCase().replaceAll(' ', '_') == pId,
        orElse: () => _selectedPreset,
      );
    }
    if (s['customTheme_primaryColor'] != null) {
      final colorVal = (s['customTheme_primaryColor'] as num).toInt();
      _customTheme = CustomThemeData(
        primaryColor: Color(colorVal),
        isAmoled: s['customTheme_isAmoled'] == true,
        cardOpacity: (s['customTheme_cardOpacity'] as num?)?.toDouble() ?? 0.95,
        blurIntensity: (s['customTheme_blurIntensity'] as num?)?.toDouble() ?? 20.0,
      );
    }
    if (s['selectedFont'] != null) {
      final fontId = s['selectedFont'].toString();
      _selectedFont = FontConfig.availableFonts.firstWhere(
        (f) => f.id == fontId || f.name == fontId,
        orElse: () => _selectedFont,
      );
    }
    if (s['networkTileStyle'] != null) {
      final nStyle = (s['networkTileStyle'].toString() == 'separate')
          ? NetworkTileStyle.separate
          : NetworkTileStyle.unified;
      if (_networkTileStyle != nStyle) {
        _networkTileStyle = nStyle;
        _configureNetworkTiles(nStyle);
      }
    }
    notifyListeners();
  }

  void _broadcastSettings() {
    final map = <String, dynamic>{
      'shadeMode': _shadeMode == ShadeMode.unified ? 'unified' : 'split',
      'sliderStyle': _sliderStyle == SliderStyle.continuousPill ? 'continuousPill' : 'separatedBar',
      'themeSource': _themeSource == ThemeSource.system ? 'system' : (_themeSource == ThemeSource.custom ? 'custom' : 'preset'),
      'selectedPreset': _selectedPreset.id,
      'customTheme_primaryColor': _customTheme.primaryColor.toARGB32(),
      'customTheme_isAmoled': _customTheme.isAmoled,
      'customTheme_cardOpacity': _customTheme.cardOpacity,
      'customTheme_blurIntensity': _customTheme.blurIntensity,
      'selectedFont': _selectedFont.id,
      'networkTileStyle': _networkTileStyle == NetworkTileStyle.unified ? 'unified' : 'separate',
    };
    SystemSettingsService.saveSettings(map);
  }

  void _initHardwareSync() {
    SystemHardwareService.init();
    SystemHardwareService.onHardwareStateChanged = (hw) {
      _applyHardwareState(hw);
    };
    _loadInitialHardwareValues();
  }

  // Target Panel Trigger ('notifications' vs 'quick_settings')
  String _targetPanel = 'quick_settings';
  String get targetPanel => _targetPanel;

  void setTargetPanel(String target) {
    _targetPanel = target;
    if (target == 'notifications') {
      _splitTabIndex = 0;
    } else {
      _splitTabIndex = 1;
    }
    _isUnifiedQsExpanded = false;
    notifyListeners();
  }

  // Slider Style
  SliderStyle _sliderStyle = SliderStyle.separatedBar;
  SliderStyle get sliderStyle => _sliderStyle;

  void setSliderStyle(SliderStyle style) {
    _sliderStyle = style;
    _broadcastSettings();
    notifyListeners();
  }

  // System Permissions
  Map<String, bool> _permissions = {
    'overlay': false,
    'accessibility': false,
    'notification': false,
    'writeSettings': false,
  };
  Map<String, bool> get permissions => _permissions;

  bool _isServiceEnabled = false;
  bool get isServiceEnabled => _isServiceEnabled;

  bool get areCorePermissionsGranted =>
      (_permissions['overlay'] ?? false) && (_permissions['accessibility'] ?? false);

  Future<void> refreshPermissions() async {
    _permissions = await SystemPermissionsService.checkPermissions();
    if (!areCorePermissionsGranted) {
      _isServiceEnabled = false;
    } else {
      final running = await SystemPermissionsService.isServiceRunning();
      if (running) {
        _isServiceEnabled = true;
      }
    }
    if (_permissions['notification'] == true) {
      _loadLiveNotifications();
      _loadLiveMedia();
    }
    notifyListeners();
  }

  Future<void> setServiceEnabled(bool enabled) async {
    _isServiceEnabled = enabled;
    if (enabled) {
      await SystemPermissionsService.startOverlayService();
    } else {
      await SystemPermissionsService.stopOverlayService();
    }
    notifyListeners();
  }

  // System Monet Accent
  Color? _systemMonetColor;
  Color? get systemMonetColor => _systemMonetColor;

  Future<void> _loadSystemMonetColor() async {
    final color = await SystemMonetService.getSystemAccentColor();
    if (color != null) {
      _systemMonetColor = color;
      notifyListeners();
    }
  }

  // Carrier & Battery Real Hardware Info
  String _carrierName = 'Mobile';
  String get carrierName => _carrierName;

  int _batteryLevel = 100;
  int get batteryLevel => _batteryLevel;

  bool _isCharging = false;
  bool get isCharging => _isCharging;

  // Hardware Initial Values
  Future<void> _loadInitialHardwareValues() async {
    final values = await SystemHardwareService.getSystemHardwareState();
    if (values != null) {
      _applyHardwareState(values);
    }
  }

  void _applyHardwareState(Map<String, dynamic> hw) {
    // 1. Wi-Fi
    if (hw['wifi'] is Map) {
      final wifi = hw['wifi'] as Map;
      final enabled = wifi['enabled'] == true;
      final connected = wifi['connected'] == true;
      final ssid = (wifi['ssid'] ?? (enabled ? 'Wi-Fi' : 'Off')).toString();
      _updateTile('wifi', (t) => t.copyWith(
        isActive: enabled,
        title: connected ? ssid : 'Internet',
        subtitle: connected ? 'Connected' : (enabled ? 'Not connected' : 'Off'),
      ));
    }

    // 2. Bluetooth
    if (hw['bluetooth'] is Map) {
      final bt = hw['bluetooth'] as Map;
      final enabled = bt['enabled'] == true;
      final connected = bt['connected'] == true;
      final name = (bt['name'] ?? (enabled ? 'On' : 'Off')).toString();
      _updateTile('bluetooth', (t) => t.copyWith(
        isActive: enabled,
        subtitle: connected ? name : (enabled ? 'On' : 'Off'),
      ));
    }

    // 3. Flashlight
    if (hw['flashlight'] is bool) {
      final on = hw['flashlight'] as bool;
      _updateTile('flashlight', (t) => t.copyWith(
        isActive: on,
        subtitle: on ? 'On' : 'Off',
      ));
    }

    // 4. Auto-rotate
    if (hw['autoRotate'] is bool) {
      final on = hw['autoRotate'] as bool;
      _updateTile('autorotate', (t) => t.copyWith(
        isActive: on,
        subtitle: on ? 'On' : 'Off',
      ));
    }

    // 5. Do Not Disturb
    if (hw['dnd'] is bool) {
      final on = hw['dnd'] as bool;
      _updateTile('dnd', (t) => t.copyWith(
        isActive: on,
        subtitle: on ? 'On' : 'Off',
      ));
    }

    // 6. Airplane Mode
    if (hw['airplane'] is bool) {
      final on = hw['airplane'] as bool;
      _updateTile('airplane', (t) => t.copyWith(
        isActive: on,
        subtitle: on ? 'On' : 'Off',
      ));
    }

    // 7. Location (GPS)
    if (hw['location'] is bool) {
      final on = hw['location'] as bool;
      _updateTile('location', (t) => t.copyWith(
        isActive: on,
        subtitle: on ? 'On' : 'Off',
      ));
    }

    // 8. Battery Saver
    if (hw['batterySaver'] is bool) {
      final on = hw['batterySaver'] as bool;
      _updateTile('battery_saver', (t) => t.copyWith(
        isActive: on,
        subtitle: on ? 'On' : 'Off',
      ));
    }

    // 9. Brightness & Volume
    if (hw['brightness'] is num) {
      _brightness = (hw['brightness'] as num).toDouble().clamp(0.0, 1.0);
    }
    if (hw['volume'] is num) {
      _volume = (hw['volume'] as num).toDouble().clamp(0.0, 1.0);
    }

    // 10. Carrier & Battery
    if (hw['carrier'] is String && (hw['carrier'] as String).isNotBlank) {
      _carrierName = hw['carrier'] as String;
    }
    if (hw['battery'] is Map) {
      final b = hw['battery'] as Map;
      _batteryLevel = (b['level'] as num?)?.toInt() ?? _batteryLevel;
      _isCharging = b['isCharging'] == true;
    }

    notifyListeners();
  }

  void _updateTile(String id, QsTileModel Function(QsTileModel) updater) {
    final idx = _tiles.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tiles[idx] = updater(_tiles[idx]);
    }
  }

  // Shade Mode (Split vs Unified)
  ShadeMode _shadeMode = ShadeMode.unified; // Default to Android 17 Unified Shade
  ShadeMode get shadeMode => _shadeMode;

  // Split Panel Tab (0: Notifications, 1: Quick Settings)
  int _splitTabIndex = 1;
  int get splitTabIndex => _splitTabIndex;

  // Unified Mode 2-State (Compact vs Expanded)
  bool _isUnifiedQsExpanded = false;
  bool get isUnifiedQsExpanded => _isUnifiedQsExpanded;

  void toggleUnifiedQsExpanded() {
    _isUnifiedQsExpanded = !_isUnifiedQsExpanded;
    notifyListeners();
  }

  void setUnifiedQsExpanded(bool expanded) {
    if (_isUnifiedQsExpanded != expanded) {
      _isUnifiedQsExpanded = expanded;
      notifyListeners();
    }
  }

  // Font Configuration
  FontConfig _selectedFont = FontConfig.defaultFont;
  FontConfig get selectedFont => _selectedFont;

  // Theme Engine
  ThemeSource _themeSource = ThemeSource.preset;
  ThemeSource get themeSource => _themeSource;

  ThemePreset _selectedPreset = ThemePreset.presets.first; // Forest Green (Android 17)
  ThemePreset get selectedPreset => _selectedPreset;

  CustomThemeData _customTheme = const CustomThemeData();
  CustomThemeData get customTheme => _customTheme;

  // Sliders
  double _brightness = 0.65;
  double get brightness => _brightness;

  double _volume = 0.40;
  double get volume => _volume;

  // Tiles
  final List<QsTileModel> _tiles = List.from(QsTileModel.defaultTiles);
  List<QsTileModel> get tiles => _tiles;

  // Network Tile Style: Unified Internet vs Separate Wi-Fi & Mobile Data
  NetworkTileStyle _networkTileStyle = NetworkTileStyle.unified;
  NetworkTileStyle get networkTileStyle => _networkTileStyle;

  void setNetworkTileStyle(NetworkTileStyle style) {
    if (_networkTileStyle != style) {
      _networkTileStyle = style;
      _configureNetworkTiles(style);
      _broadcastSettings();
      notifyListeners();
    }
  }

  void _configureNetworkTiles(NetworkTileStyle style) {
    final wifiIdx = _tiles.indexWhere((t) => t.id == 'wifi');
    final mobileIdx = _tiles.indexWhere((t) => t.id == 'mobile_data');

    if (style == NetworkTileStyle.separate) {
      // 1. Wi-Fi becomes dedicated Wi-Fi tile
      if (wifiIdx != -1) {
        _tiles[wifiIdx] = _tiles[wifiIdx].copyWith(
          title: 'Wi-Fi',
          subtitle: _tiles[wifiIdx].isActive ? 'Connected' : 'Off',
          hasDetails: false,
        );
      }
      // 2. Add Mobile Data tile if not present
      if (mobileIdx == -1) {
        final insertPos = (wifiIdx != -1) ? wifiIdx + 1 : 0;
        _tiles.insert(
          insertPos,
          QsTileModel(
            id: 'mobile_data',
            title: 'Mobile Data',
            subtitle: _carrierName.isNotEmpty ? _carrierName : 'Mobile',
            icon: Icons.signal_cellular_alt_rounded,
            isWide: true,
            isActive: true,
            hasDetails: false,
          ),
        );
      }
    } else {
      // 1. Revert to Unified "Internet" tile
      if (wifiIdx != -1) {
        _tiles[wifiIdx] = _tiles[wifiIdx].copyWith(
          title: 'Internet',
          subtitle: _tiles[wifiIdx].isActive ? 'Wi-Fi' : 'Off',
          hasDetails: true,
        );
      }
      // 2. Remove separate Mobile Data tile
      if (mobileIdx != -1) {
        _tiles.removeAt(mobileIdx);
      }
    }
  }

  // Media Player State
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  double _mediaProgress = 0.0;
  double get mediaProgress => _mediaProgress;

  String _mediaTitle = 'No media playing';
  String get mediaTitle => _mediaTitle;

  String _mediaArtist = 'Tap to open media player';
  String get mediaArtist => _mediaArtist;

  String _mediaApp = '';
  String get mediaApp => _mediaApp;

  Uint8List? _mediaArtwork;
  Uint8List? get mediaArtwork => _mediaArtwork;

  Future<void> _loadLiveMedia() async {
    final media = await SystemMediaService.getMediaState();
    if (media != null && media.title.isNotEmpty) {
      _mediaTitle = media.title;
      _mediaArtist = media.artist;
      _mediaApp = media.appName;
      _isPlaying = media.isPlaying;
      _mediaProgress = media.progress;
      _mediaArtwork = media.artwork;
      notifyListeners();
    }
  }

  // Real Notifications (no mock data on startup)
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  Future<void> _loadLiveNotifications() async {
    final liveList = await SystemNotificationService.getActiveNotifications();
    _notifications = liveList;
    notifyListeners();
  }

  // --- Actions ---

  void setShadeMode(ShadeMode mode) {
    _shadeMode = mode;
    _isUnifiedQsExpanded = false;
    _broadcastSettings();
    notifyListeners();
  }

  void setSplitTabIndex(int index) {
    _splitTabIndex = index;
    notifyListeners();
  }

  void setFont(FontConfig font) {
    _selectedFont = font;
    _broadcastSettings();
    notifyListeners();
  }

  void setThemeSource(ThemeSource source) {
    _themeSource = source;
    _broadcastSettings();
    notifyListeners();
  }

  void selectPreset(ThemePreset preset) {
    _selectedPreset = preset;
    _themeSource = ThemeSource.preset;
    _broadcastSettings();
    notifyListeners();
  }

  void updateCustomTheme(CustomThemeData custom) {
    _customTheme = custom;
    _themeSource = ThemeSource.custom;
    _broadcastSettings();
    notifyListeners();
  }

  void setBrightness(double val) {
    _brightness = val.clamp(0.0, 1.0);
    SystemHardwareService.setBrightness(_brightness);
    notifyListeners();
  }

  void setVolume(double val) {
    _volume = val.clamp(0.0, 1.0);
    SystemHardwareService.setVolume(_volume);
    notifyListeners();
  }

  void toggleTile(String id) {
    final index = _tiles.indexWhere((t) => t.id == id);
    if (index != -1) {
      final tile = _tiles[index];
      final newActive = !tile.isActive;

      if (id == 'flashlight') {
        _tiles[index] = tile.copyWith(isActive: newActive, subtitle: newActive ? 'On' : 'Off');
        SystemHardwareService.setFlashlight(newActive);
      } else if (id == 'wifi') {
        SystemHardwareService.toggleWifi();
      } else if (id == 'mobile_data') {
        _tiles[index] = tile.copyWith(isActive: newActive);
        SystemHardwareService.openMobileDataSettings();
      } else if (id == 'bluetooth') {
        SystemHardwareService.toggleBluetooth();
      } else if (id == 'autorotate') {
        SystemHardwareService.toggleAutoRotate();
      } else if (id == 'dnd') {
        SystemHardwareService.toggleDnd();
      } else if (id == 'airplane') {
        SystemHardwareService.openAirplaneSettings();
      } else if (id == 'location') {
        SystemHardwareService.openLocationSettings();
      } else if (id == 'battery_saver') {
        SystemHardwareService.openBatterySaverSettings();
      } else if (id == 'hotspot') {
        SystemHardwareService.openHotspotSettings();
      } else if (id == 'night_light') {
        SystemHardwareService.openNightLightSettings();
      } else {
        _tiles[index] = tile.copyWith(isActive: newActive);
      }

      notifyListeners();
    }
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    SystemMediaService.controlMedia('toggle');
    notifyListeners();
  }

  void skipNextMedia() {
    SystemMediaService.controlMedia('next');
  }

  void skipPreviousMedia() {
    SystemMediaService.controlMedia('prev');
  }

  void setMediaProgress(double val) {
    _mediaProgress = val.clamp(0.0, 1.0);
    notifyListeners();
  }

  void dismissNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    SystemNotificationService.cancelNotification(id);
    notifyListeners();
  }

  void toggleTileSize(String id) {
    final index = _tiles.indexWhere((t) => t.id == id);
    if (index != -1) {
      final tile = _tiles[index];
      _tiles[index] = tile.copyWith(isWide: !tile.isWide);
      notifyListeners();
    }
  }

  void setTileSize(String id, bool isWide) {
    final index = _tiles.indexWhere((t) => t.id == id);
    if (index != -1) {
      final tile = _tiles[index];
      if (tile.isWide != isWide) {
        _tiles[index] = tile.copyWith(isWide: isWide);
        notifyListeners();
      }
    }
  }

  void resetTileSizes() {
    for (int i = 0; i < _tiles.length; i++) {
      final defaultTile = QsTileModel.defaultTiles.firstWhere(
        (dt) => dt.id == _tiles[i].id,
        orElse: () => _tiles[i],
      );
      _tiles[i] = _tiles[i].copyWith(isWide: defaultTile.isWide);
    }
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    SystemNotificationService.cancelAllNotifications();
    notifyListeners();
  }

  void restoreSampleNotifications() {
    _notifications = List.from(NotificationModel.sampleNotifications);
    notifyListeners();
  }
}

extension on String {
  bool get isNotBlank => trim().isNotEmpty;
}
