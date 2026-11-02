import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/font_config.dart';
import '../models/media_player_style.dart';
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
  static const MethodChannel _overlayEventsChannel = MethodChannel(
    'com.expressive_shade/overlay_events',
  );

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
    _flushSave(all: true);
    notifyListeners();
  }

  void _applySettings(Map<String, dynamic> s) {
    if (s['shadeMode'] != null) {
      final modeStr = s['shadeMode'].toString();
      if (modeStr == 'unified') {
        _shadeMode = ShadeMode.unified;
      } else if (modeStr == 'smart' || modeStr == 'brutalist' || modeStr == 'nothing') {
        _shadeMode = ShadeMode.smart;
      } else {
        _shadeMode = ShadeMode.split;
      }
    }
    if (s['sliderStyle'] != null) {
      final st = s['sliderStyle'].toString();
      _sliderStyle = SliderStyle.values.firstWhere(
        (e) => e.name == st,
        orElse: () => (st == 'continuousPill' || st == 'continuous')
            ? SliderStyle.continuousPill
            : SliderStyle.separatedBar,
      );
    }
    if (s['mediaPlayerStyle'] != null) {
      final ms = s['mediaPlayerStyle'].toString();
      _mediaPlayerStyle = MediaPlayerStyle.values.firstWhere(
        (e) => e.name == ms,
        orElse: () => MediaPlayerStyle.expressiveWave,
      );
    }
    if (s['themeMode'] != null) {
      final modeStr = s['themeMode'].toString();
      if (modeStr == 'light') {
        _themeMode = ThemeMode.light;
      } else if (modeStr == 'system') {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.dark;
      }
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
        (p) =>
            p.id == pId ||
            p.name == pId ||
            p.name.toLowerCase().replaceAll(' ', '_') == pId,
        orElse: () => _selectedPreset,
      );
    }
    if (s['customTheme_primaryColor'] != null) {
      final colorVal = (s['customTheme_primaryColor'] as num).toInt();
      _customTheme = CustomThemeData(
        primaryColor: Color(colorVal),
        isAmoled: s['customTheme_isAmoled'] == true,
        cardOpacity: (s['customTheme_cardOpacity'] as num?)?.toDouble() ?? 0.95,
        blurIntensity:
            (s['customTheme_blurIntensity'] as num?)?.toDouble() ?? 20.0,
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
    if (s['tiles'] != null) {
      try {
        final dynamic raw = s['tiles'];
        final List<dynamic> list = (raw is String)
            ? jsonDecode(raw)
            : (raw as List);
        final loadedTiles = list
            .map(
              (item) =>
                  QsTileModel.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
        if (loadedTiles.isNotEmpty) {
          _tiles.clear();
          _tiles.addAll(loadedTiles);
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Debounced, delta-only settings persistence
  // ---------------------------------------------------------------------------
  static const Duration _saveDebounce = Duration(milliseconds: 300);
  final Set<String> _dirtySettings = {};
  Timer? _saveTimer;

  /// Marks [groups] as changed and writes them once changes settle.
  void _scheduleSave(Set<String> groups) {
    _dirtySettings.addAll(groups);
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, () => _flushSave());
  }

  /// Immediately persists the dirty groups (or everything when [all] is true).
  void flushSave({bool all = false}) => _flushSave(all: all);

  void _flushSave({bool all = false}) {
    _saveTimer?.cancel();
    _saveTimer = null;
    if (all) {
      _dirtySettings.addAll(const {
        'shadeMode',
        'sliderStyle',
        'mediaPlayerStyle',
        'themeMode',
        'themeSource',
        'selectedPreset',
        'customTheme',
        'selectedFont',
        'networkTileStyle',
        'tiles',
      });
    }
    if (_dirtySettings.isEmpty) return;
    final dirty = Set<String>.of(_dirtySettings);
    _dirtySettings.clear();

    final map = <String, dynamic>{};
    if (dirty.contains('shadeMode')) {
      map['shadeMode'] = _shadeMode == ShadeMode.unified
          ? 'unified'
          : (_shadeMode == ShadeMode.smart ? 'smart' : 'split');
    }
    if (dirty.contains('sliderStyle')) {
      map['sliderStyle'] = _sliderStyle.name;
    }
    if (dirty.contains('mediaPlayerStyle')) {
      map['mediaPlayerStyle'] = _mediaPlayerStyle.name;
    }
    if (dirty.contains('themeMode')) {
      map['themeMode'] = _themeMode == ThemeMode.light
          ? 'light'
          : (_themeMode == ThemeMode.system ? 'system' : 'dark');
    }
    if (dirty.contains('themeSource')) {
      map['themeSource'] = _themeSource == ThemeSource.system
          ? 'system'
          : (_themeSource == ThemeSource.custom ? 'custom' : 'preset');
    }
    if (dirty.contains('selectedPreset')) {
      map['selectedPreset'] = _selectedPreset.id;
    }
    if (dirty.contains('customTheme')) {
      map['customTheme_primaryColor'] = _customTheme.primaryColor.toARGB32();
      map['customTheme_isAmoled'] = _customTheme.isAmoled;
      map['customTheme_cardOpacity'] = _customTheme.cardOpacity;
      map['customTheme_blurIntensity'] = _customTheme.blurIntensity;
    }
    if (dirty.contains('selectedFont')) {
      map['selectedFont'] = _selectedFont.id;
    }
    if (dirty.contains('networkTileStyle')) {
      map['networkTileStyle'] = _networkTileStyle == NetworkTileStyle.unified
          ? 'unified'
          : 'separate';
    }
    if (dirty.contains('tiles')) {
      // Only the tiles are re-serialized, and only when they changed.
      map['tiles'] = jsonEncode(_tiles.map((t) => t.toJson()).toList());
    }
    SystemSettingsService.saveSettings(map);
  }

  @override
  void dispose() {
    _flushSave();
    super.dispose();
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

  // Incremented each time the shade is shown so the UI can reset its scroll position.
  int _shadeOpenEpoch = 0;
  int get shadeOpenEpoch => _shadeOpenEpoch;

  void markShadeOpened() {
    _shadeOpenEpoch++;
    notifyListeners();
  }

  // Slider Style
  SliderStyle _sliderStyle = SliderStyle.separatedBar;
  SliderStyle get sliderStyle => _sliderStyle;

  void setSliderStyle(SliderStyle style) {
    _sliderStyle = style;
    _scheduleSave({'sliderStyle'});
    notifyListeners();
  }

  // Media Player Style
  MediaPlayerStyle _mediaPlayerStyle = MediaPlayerStyle.expressiveWave;
  MediaPlayerStyle get mediaPlayerStyle => _mediaPlayerStyle;

  void setMediaPlayerStyle(MediaPlayerStyle style) {
    _mediaPlayerStyle = style;
    _scheduleSave({'mediaPlayerStyle'});
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
      (_permissions['overlay'] ?? false) &&
      (_permissions['accessibility'] ?? false);

  Future<void> refreshPermissions() async {
    _permissions = await SystemPermissionsService.checkPermissions();
    if (!areCorePermissionsGranted) {
      _isServiceEnabled = false;
    } else {
      _isServiceEnabled = await SystemPermissionsService.isServiceRunning();
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
      _updateTile(
        'wifi',
        (t) => t.copyWith(
          isActive: enabled,
          title: connected ? ssid : 'Internet',
          subtitle: connected
              ? 'Connected'
              : (enabled ? 'Not connected' : 'Off'),
        ),
      );
    }

    // 2. Bluetooth
    if (hw['bluetooth'] is Map) {
      final bt = hw['bluetooth'] as Map;
      final enabled = bt['enabled'] == true;
      final connected = bt['connected'] == true;
      final name = (bt['name'] ?? (enabled ? 'On' : 'Off')).toString();
      _updateTile(
        'bluetooth',
        (t) => t.copyWith(
          isActive: enabled,
          subtitle: connected ? name : (enabled ? 'On' : 'Off'),
        ),
      );
    }

    // 3. Flashlight
    if (hw['flashlight'] is bool) {
      final on = hw['flashlight'] as bool;
      _updateTile(
        'flashlight',
        (t) => t.copyWith(isActive: on, subtitle: on ? 'On' : 'Off'),
      );
    }

    // 4. Auto-rotate
    if (hw['autoRotate'] is bool) {
      final on = hw['autoRotate'] as bool;
      _updateTile(
        'autorotate',
        (t) => t.copyWith(isActive: on, subtitle: on ? 'On' : 'Off'),
      );
    }

    // 5. Do Not Disturb
    if (hw['dnd'] is bool) {
      final on = hw['dnd'] as bool;
      _updateTile(
        'dnd',
        (t) => t.copyWith(isActive: on, subtitle: on ? 'On' : 'Off'),
      );
    }

    // 6. Airplane Mode
    if (hw['airplane'] is bool) {
      final on = hw['airplane'] as bool;
      _updateTile(
        'airplane',
        (t) => t.copyWith(isActive: on, subtitle: on ? 'On' : 'Off'),
      );
    }

    // 7. Location (GPS)
    if (hw['location'] is bool) {
      final on = hw['location'] as bool;
      _updateTile(
        'location',
        (t) => t.copyWith(isActive: on, subtitle: on ? 'On' : 'Off'),
      );
    }

    // 8. Battery Saver
    if (hw['batterySaver'] is bool) {
      final on = hw['batterySaver'] as bool;
      _updateTile(
        'battery_saver',
        (t) => t.copyWith(isActive: on, subtitle: on ? 'On' : 'Off'),
      );
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
  ShadeMode _shadeMode =
      ShadeMode.unified; // Default to Android 17 Unified Shade
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

  // Theme Engine & Appearance Mode
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeSource _themeSource = ThemeSource.preset;
  ThemeSource get themeSource => _themeSource;

  ThemePreset _selectedPreset = ThemePreset.presets.firstWhere(
    (p) => p.id == 'forest_green',
    orElse: () => ThemePreset.presets.first,
  );
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
      _scheduleSave({'networkTileStyle', 'tiles'});
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
    if (_notifications.length == liveList.length) {
      var unchanged = true;
      for (var i = 0; i < liveList.length; i++) {
        if (!_notifications[i].hasSameContentAs(liveList[i])) {
          unchanged = false;
          break;
        }
      }
      if (unchanged) return; // nothing visible changed; skip the rebuild
    }
    // Secondary guardrail: never show media notifications or own overlay service notifications
    _notifications = liveList.where((n) {
      final text = '${n.title} ${n.content}'.toLowerCase();
      final isOverlayAlert =
          text.contains('expressiveshade') &&
          (text.contains('displaying over') ||
              text.contains('displayed over') ||
              text.contains('drawing over') ||
              text.contains('active'));
      return !isOverlayAlert;
    }).toList();
    notifyListeners();
  }

  // --- Actions ---

  void setShadeMode(ShadeMode mode) {
    _shadeMode = mode;
    _isUnifiedQsExpanded = false;
    _scheduleSave({'shadeMode'});
    notifyListeners();
  }

  void setSplitTabIndex(int index) {
    _splitTabIndex = index;
    notifyListeners();
  }

  void setFont(FontConfig font) {
    _selectedFont = font;
    _scheduleSave({'selectedFont'});
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _scheduleSave({'themeMode'});
    notifyListeners();
  }

  void toggleDarkLightMode() {
    setThemeMode(
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  void setThemeSource(ThemeSource source) {
    _themeSource = source;
    _scheduleSave({'themeSource'});
    notifyListeners();
  }

  void selectPreset(ThemePreset preset) {
    _selectedPreset = preset;
    _themeSource = ThemeSource.preset;
    _scheduleSave({'selectedPreset', 'themeSource'});
    notifyListeners();
  }

  void updateCustomTheme(CustomThemeData custom) {
    _customTheme = custom;
    _themeSource = ThemeSource.custom;
    _scheduleSave({'customTheme', 'themeSource'});
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
        _tiles[index] = tile.copyWith(
          isActive: newActive,
          subtitle: newActive ? 'On' : 'Off',
        );
        SystemHardwareService.setFlashlight(newActive);
      } else if (id == 'wifi') {
        if (_networkTileStyle == NetworkTileStyle.separate) {
          _tiles[index] = tile.copyWith(
            isActive: newActive,
            subtitle: newActive ? 'Connected' : 'Off',
          );
        }
        SystemHardwareService.toggleWifi();
      } else if (id == 'bluetooth') {
        _tiles[index] = tile.copyWith(
          isActive: newActive,
          subtitle: newActive ? 'On' : 'Off',
        );
        SystemHardwareService.toggleBluetooth();
      } else if (id == 'autorotate') {
        _tiles[index] = tile.copyWith(
          isActive: newActive,
          subtitle: newActive ? 'On' : 'Off',
        );
        SystemHardwareService.toggleAutoRotate();
      } else if (id == 'dnd') {
        _tiles[index] = tile.copyWith(
          isActive: newActive,
          subtitle: newActive ? 'On' : 'Off',
        );
        SystemHardwareService.toggleDnd();
      } else {
        // Direct in-place toggle for all other settings (battery saver, night light, hotspot, etc.)
        // AVOID opening external settings app!
        String? newSubtitle;
        if (id == 'battery_saver') {
          newSubtitle = newActive ? 'Active' : 'Off';
        } else if (id == 'night_light') {
          newSubtitle = newActive ? 'Warm' : 'Off';
        } else if (id == 'hotspot') {
          newSubtitle = newActive ? 'Sharing' : 'Off';
        } else if (id == 'airplane') {
          newSubtitle = newActive ? 'On' : 'Off';
        } else if (id == 'location') {
          newSubtitle = newActive ? 'Precise' : 'Off';
        } else if (id == 'dark_theme') {
          newSubtitle = newActive ? 'Dark' : 'Light';
        } else if (id == 'data_saver') {
          newSubtitle = newActive ? 'On' : 'Off';
        } else if (id == 'vpn') {
          newSubtitle = newActive ? 'Connected' : 'Disconnected';
        } else if (id == 'modes') {
          newSubtitle = newActive ? 'Focus' : 'Normal';
        } else if (id == 'cast') {
          newSubtitle = newActive ? 'Streaming' : 'Off';
        } else if (id == 'extra_dim') {
          newSubtitle = newActive ? 'Dimmed' : 'Off';
        } else if (id == 'screen_record') {
          newSubtitle = newActive ? 'Recording' : 'Record';
        } else if (id == 'camera_privacy') {
          newSubtitle = newActive ? 'Blocked' : 'Unblocked';
        } else if (id == 'mic_privacy') {
          newSubtitle = newActive ? 'Blocked' : 'Unblocked';
        } else if (id == 'sensitive_notifs') {
          newSubtitle = newActive ? 'Visible' : 'Hidden';
        } else if (id == 'device_controls') {
          newSubtitle = newActive ? 'Connected' : 'Home';
        } else if (id == 'one_handed') {
          newSubtitle = newActive ? 'On' : 'Off';
        } else if (id == 'talkback') {
          newSubtitle = newActive ? 'On' : 'Off';
        } else if (id == 'high_contrast') {
          newSubtitle = newActive ? 'On' : 'Off';
        } else if (id == 'magnification') {
          newSubtitle = newActive ? 'On' : 'Off';
        } else if (tile.subtitle != null) {
          newSubtitle = newActive ? 'On' : 'Off';
        }
        _tiles[index] = tile.copyWith(
          isActive: newActive,
          subtitle: newSubtitle,
        );
      }

      _scheduleSave({'tiles'});
      notifyListeners();
    }
  }

  void addTile(QsTileModel tile) {
    if (!_tiles.any((t) => t.id == tile.id)) {
      _tiles.add(tile);
      _scheduleSave({'tiles'});
      notifyListeners();
    }
  }

  void removeTile(String id) {
    if (_tiles.length > 1) {
      _tiles.removeWhere((t) => t.id == id);
      _scheduleSave({'tiles'});
      notifyListeners();
    }
  }

  void resetTiles() {
    _tiles.clear();
    _tiles.addAll(QsTileModel.defaultTiles);
    _configureNetworkTiles(_networkTileStyle);
    _scheduleSave({'tiles'});
    notifyListeners();
  }

  void reorderTile(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _tiles.length) return;
    if (newIndex < 0 || newIndex >= _tiles.length) return;
    final tile = _tiles.removeAt(oldIndex);
    _tiles.insert(newIndex, tile);
    _scheduleSave({'tiles'});
    notifyListeners();
  }

  void moveTile(String fromId, String toId) {
    final oldIndex = _tiles.indexWhere((t) => t.id == fromId);
    final newIndex = _tiles.indexWhere((t) => t.id == toId);
    if (oldIndex != -1 && newIndex != -1 && oldIndex != newIndex) {
      final tile = _tiles.removeAt(oldIndex);
      _tiles.insert(newIndex, tile);
      _scheduleSave({'tiles'});
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
    SystemMediaService.seekTo(_mediaProgress);
    notifyListeners();
  }

  void dismissNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    SystemNotificationService.cancelNotification(id);
    notifyListeners();
  }

  void dismissAllForApp(String appName) {
    final toRemove =
        _notifications.where((n) => n.appName == appName).toList();
    for (final notif in toRemove) {
      _notifications.remove(notif);
      SystemNotificationService.cancelNotification(notif.id);
    }
    notifyListeners();
  }

  final Set<String> _silentApps = {};
  final Set<String> _silentNotificationIds = {};

  bool isNotificationSilent(NotificationModel notif) {
    return _silentNotificationIds.contains(notif.id) ||
        _silentApps.contains(notif.appName) ||
        (notif.packageName.isNotEmpty &&
            _silentApps.contains(notif.packageName));
  }

  void setNotificationSilent(NotificationModel notif, bool silent) {
    if (silent) {
      _silentNotificationIds.add(notif.id);
      _silentApps.add(notif.appName);
      if (notif.packageName.isNotEmpty) {
        _silentApps.add(notif.packageName);
      }
    } else {
      _silentNotificationIds.remove(notif.id);
      _silentApps.remove(notif.appName);
      if (notif.packageName.isNotEmpty) {
        _silentApps.remove(notif.packageName);
      }
    }
    notifyListeners();
  }

  void toggleTileSize(String id) {
    final index = _tiles.indexWhere((t) => t.id == id);
    if (index != -1) {
      final tile = _tiles[index];
      _tiles[index] = tile.copyWith(isWide: !tile.isWide);
      _scheduleSave({'tiles'});
      notifyListeners();
    }
  }

  void setTileSize(String id, bool isWide) {
    final index = _tiles.indexWhere((t) => t.id == id);
    if (index != -1) {
      final tile = _tiles[index];
      if (tile.isWide != isWide) {
        _tiles[index] = tile.copyWith(isWide: isWide);
        _scheduleSave({'tiles'});
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
    _scheduleSave({'tiles'});
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    SystemNotificationService.cancelAllNotifications();
    notifyListeners();
  }

  Future<void> performNotificationAction(
    NotificationModel n,
    NotificationAction action, {
    String? replyText,
  }) async {
    await SystemNotificationService.performAction(
      n.id,
      action.index,
      replyText: replyText,
    );
  }

  Future<bool> openNotification(NotificationModel n) =>
      SystemNotificationService.openNotification(n.id);

  void snoozeNotification(
    String id, {
    Duration duration = const Duration(hours: 1),
  }) {
    _notifications.removeWhere((n) => n.id == id);
    SystemNotificationService.snoozeNotification(id, duration);
    notifyListeners();
  }

  Future<void> openSettings() => SystemHardwareService.openSettings();

  Future<void> openNotificationHistory() =>
      SystemHardwareService.openNotificationHistory();
}

extension on String {
  bool get isNotBlank => trim().isNotEmpty;
}
