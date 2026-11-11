import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/font_config.dart';
import '../models/media_player_style.dart';
import '../models/notification_model.dart';
import '../models/notification_style.dart';
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
import '../services/smart_notification_classifier.dart';
import '../features/lyrics/services/lyrics_sync_service.dart';

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

    // Start synced lyrics service
    LyricsSyncService.instance.start();
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
      } else if (modeStr == 'nothingOs5' || modeStr == 'nothing_os_5') {
        _shadeMode = ShadeMode.nothingOs5;
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
    if (s['inlineLyricsEnabled'] != null) {
      _inlineLyricsEnabled = s['inlineLyricsEnabled'] == true;
    }
    if (s['notificationStyle'] != null) {
      final ns = s['notificationStyle'].toString();
      _notificationStyle = NotificationStyle.values.firstWhere(
        (e) => e.name == ns,
        orElse: () => NotificationStyle.android17,
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
        cardOpacity: (s['customTheme_cardOpacity'] as num?)?.toDouble() ?? 1.0,
        blurIntensity:
            (s['customTheme_blurIntensity'] as num?)?.toDouble() ?? 0.0,
        customBackground: s['customTheme_customBackground'] != null
            ? Color((s['customTheme_customBackground'] as num).toInt())
            : null,
        customActivePill: s['customTheme_customActivePill'] != null
            ? Color((s['customTheme_customActivePill'] as num).toInt())
            : null,
        customInactivePill: s['customTheme_customInactivePill'] != null
            ? Color((s['customTheme_customInactivePill'] as num).toInt())
            : null,
        customAccent: s['customTheme_customAccent'] != null
            ? Color((s['customTheme_customAccent'] as num).toInt())
            : null,
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
    for (final mode in ShadeMode.values) {
      final modeKey = 'tiles_${mode.name}';
      if (s[modeKey] != null) {
        try {
          final dynamic raw = s[modeKey];
          final List<dynamic> list =
              (raw is String) ? jsonDecode(raw) : (raw as List);
          final loadedTiles = list
              .map(
                (item) => QsTileModel.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();
          if (loadedTiles.isNotEmpty) {
            final targetList = _tilesByMode[mode]!;
            targetList.clear();
            if (mode == ShadeMode.nothingOs5) {
              targetList.addAll(
                QsTileModel.ensureNothingOsControls(loadedTiles),
              );
            } else {
              targetList.addAll(
                QsTileModel.sanitizeForStandardMode(loadedTiles),
              );
            }
          }
        } catch (_) {}
      }
    }
    if (s['smartClassifierEnabled'] != null) {
      _smartClassifierEnabled = s['smartClassifierEnabled'] == true ||
          s['smartClassifierEnabled'] == 'true';
      SmartNotificationClassifier.isEnabled = _smartClassifierEnabled;
    }
    if (s['notificationCategoryOverrides'] != null) {
      try {
        final dynamic raw = s['notificationCategoryOverrides'];
        final Map<String, dynamic> map = (raw is String)
            ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
            : Map<String, dynamic>.from(raw as Map);
        SmartNotificationClassifier.loadOverrides(map);
        _reclassifyExistingNotifications();
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
      _dirtySettings.addAll({
        'shadeMode',
        'sliderStyle',
        'mediaPlayerStyle',
        'inlineLyricsEnabled',
        'themeMode',
        'themeSource',
        'selectedPreset',
        'customTheme',
        'selectedFont',
        'networkTileStyle',
        for (final mode in ShadeMode.values) 'tiles_${mode.name}',
      });
    }
    if (_dirtySettings.isEmpty) return;
    final dirty = Set<String>.of(_dirtySettings);
    _dirtySettings.clear();

    final map = <String, dynamic>{};
    if (dirty.contains('shadeMode')) {
      map['shadeMode'] = _shadeMode.name;
    }
    if (dirty.contains('sliderStyle')) {
      map['sliderStyle'] = _sliderStyle.name;
    }
    if (dirty.contains('mediaPlayerStyle')) {
      map['mediaPlayerStyle'] = _mediaPlayerStyle.name;
    }
    if (dirty.contains('inlineLyricsEnabled')) {
      map['inlineLyricsEnabled'] = _inlineLyricsEnabled;
    }
    if (dirty.contains('smartClassifierEnabled') || all) {
      map['smartClassifierEnabled'] = _smartClassifierEnabled;
    }
    if (dirty.contains('notificationStyle')) {
      map['notificationStyle'] = _notificationStyle.name;
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
      if (_customTheme.customBackground != null) {
        map['customTheme_customBackground'] =
            _customTheme.customBackground!.toARGB32();
      }
      if (_customTheme.customActivePill != null) {
        map['customTheme_customActivePill'] =
            _customTheme.customActivePill!.toARGB32();
      }
      if (_customTheme.customInactivePill != null) {
        map['customTheme_customInactivePill'] =
            _customTheme.customInactivePill!.toARGB32();
      }
      if (_customTheme.customAccent != null) {
        map['customTheme_customAccent'] =
            _customTheme.customAccent!.toARGB32();
      }
    }
    if (dirty.contains('selectedFont')) {
      map['selectedFont'] = _selectedFont.id;
    }
    if (dirty.contains('networkTileStyle')) {
      map['networkTileStyle'] = _networkTileStyle == NetworkTileStyle.unified
          ? 'unified'
          : 'separate';
    }
    for (final mode in ShadeMode.values) {
      final modeKey = 'tiles_${mode.name}';
      if (dirty.contains(modeKey) || dirty.contains('tiles')) {
        map[modeKey] = jsonEncode(
          _tilesByMode[mode]!.map((t) => t.toJson()).toList(),
        );
      }
    }
    if (dirty.contains('notificationCategoryOverrides')) {
      map['notificationCategoryOverrides'] = jsonEncode(
        SmartNotificationClassifier.exportOverrides(),
      );
    }
    SystemSettingsService.saveSettings(map);
  }

  @override
  void dispose() {
    _flushSave();
    LyricsSyncService.instance.stop();
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
    _loadLiveNotifications();
    _loadInitialHardwareValues();
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

  // Inline Integration (Synced Lyrics)
  bool _inlineLyricsEnabled = true;
  bool get inlineLyricsEnabled => _inlineLyricsEnabled;

  void setInlineLyricsEnabled(bool enabled) {
    if (_inlineLyricsEnabled == enabled) return;
    _inlineLyricsEnabled = enabled;
    _scheduleSave({'inlineLyricsEnabled'});
    notifyListeners();
  }

  // Notification Card Style
  NotificationStyle _notificationStyle = NotificationStyle.android17;
  NotificationStyle get notificationStyle => _notificationStyle;

  void setNotificationStyle(NotificationStyle style) {
    _notificationStyle = style;
    _scheduleSave({'notificationStyle'});
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

  bool _isTriggerBallEnabled = true;
  bool get isTriggerBallEnabled => _isTriggerBallEnabled;

  bool get areCorePermissionsGranted =>
      (_permissions['overlay'] ?? false) &&
      (_permissions['accessibility'] ?? false);

  Future<void> refreshPermissions() async {
    _permissions = await SystemPermissionsService.checkPermissions();
    _isTriggerBallEnabled = await SystemPermissionsService.isTriggerBallEnabled();
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

  Future<void> setTriggerBallEnabled(bool enabled) async {
    _isTriggerBallEnabled = enabled;
    await SystemPermissionsService.setTriggerBallEnabled(enabled);
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
      final rawSsid = wifi['ssid']?.toString() ?? '';
      final validSsid = (rawSsid.isNotEmpty &&
              rawSsid != 'Connected' &&
              rawSsid != '<unknown ssid>' &&
              rawSsid != 'Wi-Fi')
          ? rawSsid
          : null;

      _updateTile(
        'wifi',
        (t) => t.copyWith(
          isActive: enabled,
          title: _networkTileStyle == NetworkTileStyle.separate ? 'Wi-Fi' : 'Internet',
          subtitle: connected
              ? (validSsid ?? 'Connected')
              : (enabled ? 'Not connected' : 'Off'),
        ),
      );
    }

    // 1b. Mobile Data
    if (hw['mobileData'] is Map) {
      final md = hw['mobileData'] as Map;
      final enabled = md['enabled'] == true;
      final connected = md['connected'] == true;
      final carrier = _carrierName.isNotEmpty ? _carrierName : 'Mobile Data';
      _updateTile(
        'mobile_data',
        (t) => t.copyWith(
          isActive: enabled,
          subtitle: enabled ? (connected ? carrier : 'Active') : 'Off',
        ),
      );
    }

    // 1c. Hotspot
    if (hw['hotspot'] is bool) {
      final on = hw['hotspot'] as bool;
      _updateTile(
        'hotspot',
        (t) => t.copyWith(isActive: on, subtitle: on ? 'Sharing' : 'Off'),
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
      // Also update Modes tile state if present
      _updateTile(
        'modes',
        (t) => t.copyWith(isActive: on, subtitle: on ? 'Focus' : 'Normal'),
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
        (t) => t.copyWith(isActive: on, subtitle: on ? 'Active' : 'Off'),
      );
    }

    // 8b. Night Light
    if (hw['nightLight'] is bool) {
      final on = hw['nightLight'] as bool;
      _updateTile(
        'night_light',
        (t) => t.copyWith(isActive: on, subtitle: on ? 'Warm' : 'Off'),
      );
    }

    // 8c. Extra Dim
    if (hw['extraDim'] is bool) {
      final on = hw['extraDim'] as bool;
      _updateTile(
        'extra_dim',
        (t) => t.copyWith(isActive: on, subtitle: on ? 'Dimmed' : 'Off'),
      );
    }

    // 8d. NFC
    if (hw['nfc'] is bool) {
      final on = hw['nfc'] as bool;
      _updateTile(
        'nfc',
        (t) => t.copyWith(isActive: on, subtitle: on ? 'On' : 'Off'),
      );
    }

    // 8e. Data Saver
    if (hw['dataSaver'] is bool) {
      final on = hw['dataSaver'] as bool;
      _updateTile(
        'data_saver',
        (t) => t.copyWith(isActive: on, subtitle: on ? 'On' : 'Off'),
      );
    }

    // 9. Brightness, Volume & Ringer Mode
    if (hw['brightness'] is num) {
      _brightness = (hw['brightness'] as num).toDouble().clamp(0.0, 1.0);
    }
    if (hw['volume'] is num) {
      _volume = (hw['volume'] as num).toDouble().clamp(0.0, 1.0);
    }
    if (hw['ringerMode'] is num) {
      _ringerMode = (hw['ringerMode'] as num).toInt().clamp(0, 2);
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
    for (final modeTiles in _tilesByMode.values) {
      final idx = modeTiles.indexWhere((t) => t.id == id);
      if (idx != -1) {
        modeTiles[idx] = updater(modeTiles[idx]);
      }
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

  // Per-ShadeMode Independent Tile Layouts
  final Map<ShadeMode, List<QsTileModel>> _tilesByMode = {
    for (final mode in ShadeMode.values)
      mode: QsTileModel.defaultTilesForMode(mode),
  };

  List<QsTileModel> get _tiles => _tilesByMode[_shadeMode]!;
  List<QsTileModel> get tiles => _tilesByMode[_shadeMode]!;
  List<QsTileModel> tilesForMode(ShadeMode mode) => _tilesByMode[mode]!;

  String get _currentModeTilesKey => 'tiles_${_shadeMode.name}';

  // Network Tile Style: Unified Internet vs Separate Wi-Fi & Mobile Data
  NetworkTileStyle _networkTileStyle = NetworkTileStyle.unified;
  NetworkTileStyle get networkTileStyle => _networkTileStyle;

  void setNetworkTileStyle(NetworkTileStyle style) {
    if (_networkTileStyle != style) {
      _networkTileStyle = style;
      _configureNetworkTiles(style);
      _scheduleSave({
        'networkTileStyle',
        for (final mode in ShadeMode.values) 'tiles_${mode.name}',
      });
      notifyListeners();
    }
  }

  void _configureNetworkTiles(NetworkTileStyle style) {
    for (final modeTiles in _tilesByMode.values) {
      final wifiIdx = modeTiles.indexWhere((t) => t.id == 'wifi');
      final mobileIdx = modeTiles.indexWhere((t) => t.id == 'mobile_data');

      if (style == NetworkTileStyle.separate) {
        // 1. Wi-Fi becomes dedicated Wi-Fi tile
        if (wifiIdx != -1) {
          modeTiles[wifiIdx] = modeTiles[wifiIdx].copyWith(
            title: 'Wi-Fi',
            subtitle: modeTiles[wifiIdx].isActive ? 'Connected' : 'Off',
            hasDetails: false,
          );
        }
        // 2. Add Mobile Data tile if not present
        if (mobileIdx == -1) {
          final insertPos = (wifiIdx != -1) ? wifiIdx + 1 : 0;
          modeTiles.insert(
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
          modeTiles[wifiIdx] = modeTiles[wifiIdx].copyWith(
            title: 'Internet',
            subtitle: modeTiles[wifiIdx].isActive ? 'Wi-Fi' : 'Off',
            hasDetails: true,
          );
        }
        // 2. Remove separate Mobile Data tile
        if (mobileIdx != -1) {
          modeTiles.removeAt(mobileIdx);
        }
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
      LyricsSyncService.instance.updateMediaState(
        title: media.title,
        artist: media.artist,
        album: media.album,
        isPlaying: media.isPlaying,
        progress: media.progress,
        durationMs: media.durationMs,
        positionMs: media.positionMs,
      );
      notifyListeners();
    }
  }

  // Real Notifications (no mock data on startup)
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;
  final Set<String> _locallyDismissedIds = {};

  Future<void> _loadLiveNotifications() async {
    final liveList = await SystemNotificationService.getActiveNotifications();
    // Prune locally dismissed IDs that Android has now successfully removed
    _locallyDismissedIds.removeWhere((id) => !liveList.any((n) => n.id == id));

    // Secondary guardrail: filter locally dismissed, ongoing notifications, and own overlay alert
    final filtered = liveList.where((n) {
      if (_locallyDismissedIds.contains(n.id)) return false;
      final text = '${n.title} ${n.content}'.toLowerCase();
      final isOverlayAlert =
          text.contains('expressiveshade') &&
          (text.contains('displaying over') ||
              text.contains('displayed over') ||
              text.contains('drawing over') ||
              text.contains('active'));
      return !isOverlayAlert;
    }).toList();

    if (_notifications.length == filtered.length) {
      var unchanged = true;
      for (var i = 0; i < filtered.length; i++) {
        if (!_notifications[i].hasSameContentAs(filtered[i])) {
          unchanged = false;
          break;
        }
      }
      if (unchanged) return; // nothing visible changed; skip the rebuild
    }

    _notifications = filtered;
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

  int _lastBrightnessIpc = 0;
  void setBrightness(double val) {
    _brightness = val.clamp(0.0, 1.0);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastBrightnessIpc > 30) {
      _lastBrightnessIpc = now;
      SystemHardwareService.setBrightness(_brightness);
    }
    notifyListeners();
  }

  int _lastVolumeIpc = 0;
  void setVolume(double val) {
    _volume = val.clamp(0.0, 1.0);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastVolumeIpc > 30) {
      _lastVolumeIpc = now;
      SystemHardwareService.setVolume(_volume);
    }
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
        _tiles[index] = tile.copyWith(
          isActive: newActive,
          title: _networkTileStyle == NetworkTileStyle.separate ? 'Wi-Fi' : 'Internet',
          subtitle: newActive ? 'Connected' : 'Off',
        );
        SystemHardwareService.toggleWifi();
      } else if (id == 'mobile_data') {
        _tiles[index] = tile.copyWith(
          isActive: newActive,
          subtitle: newActive ? (_carrierName.isNotEmpty ? _carrierName : 'Active') : 'Off',
        );
        SystemHardwareService.toggleMobileData();
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
        SystemHardwareService.toggleAutoRotate().then((res) {
          if (res != null) {
            _updateTile('autorotate', (t) => t.copyWith(isActive: res, subtitle: res ? 'On' : 'Off'));
            notifyListeners();
          }
        });
      } else if (id == 'dnd') {
        _tiles[index] = tile.copyWith(
          isActive: newActive,
          subtitle: newActive ? 'On' : 'Off',
        );
        SystemHardwareService.toggleDnd().then((res) {
          if (res != null) {
            _updateTile('dnd', (t) => t.copyWith(isActive: res, subtitle: res ? 'On' : 'Off'));
            _updateTile('modes', (t) => t.copyWith(isActive: res, subtitle: res ? 'Focus' : 'Normal'));
            notifyListeners();
          }
        });
      } else if (id == 'battery_saver') {
        _tiles[index] = tile.copyWith(
          isActive: newActive,
          subtitle: newActive ? 'Active' : 'Off',
        );
        SystemHardwareService.toggleBatterySaver().then((res) {
          if (res != null) {
            _updateTile('battery_saver', (t) => t.copyWith(isActive: res, subtitle: res ? 'Active' : 'Off'));
            notifyListeners();
          }
        });
      } else if (id == 'airplane') {
        _tiles[index] = tile.copyWith(
          isActive: newActive,
          subtitle: newActive ? 'On' : 'Off',
        );
        SystemHardwareService.toggleAirplane().then((res) {
          if (res != null) {
            _updateTile('airplane', (t) => t.copyWith(isActive: res, subtitle: res ? 'On' : 'Off'));
            notifyListeners();
          }
        });
      } else if (id == 'hotspot') {
        _tiles[index] = tile.copyWith(
          isActive: newActive,
          subtitle: newActive ? 'Sharing' : 'Off',
        );
        SystemHardwareService.toggleHotspot().then((res) {
          if (res != null) {
            _updateTile('hotspot', (t) => t.copyWith(isActive: res, subtitle: res ? 'Sharing' : 'Off'));
            notifyListeners();
          }
        });
      } else if (id == 'modes') {
        _tiles[index] = tile.copyWith(
          isActive: newActive,
          subtitle: newActive ? 'Focus' : 'Normal',
        );
        if (newActive) {
          SystemHardwareService.setZenMode('focus').then((res) {
            if (res == true) {
              _updateTile('modes', (t) => t.copyWith(isActive: true, subtitle: 'Focus'));
              _updateTile('dnd', (t) => t.copyWith(isActive: true, subtitle: 'On'));
              notifyListeners();
            }
          });
        } else {
          SystemHardwareService.setZenMode('normal').then((res) {
            if (res == true) {
              _updateTile('modes', (t) => t.copyWith(isActive: false, subtitle: 'Normal'));
              _updateTile('dnd', (t) => t.copyWith(isActive: false, subtitle: 'Off'));
              notifyListeners();
            }
          });
        }
      } else if (id == 'night_light') {
        _tiles[index] = tile.copyWith(
          isActive: newActive,
          subtitle: newActive ? 'Warm' : 'Off',
        );
        SystemHardwareService.toggleNightLight().then((res) {
          if (res != null) {
            _updateTile('night_light', (t) => t.copyWith(isActive: res, subtitle: res ? 'Warm' : 'Off'));
            notifyListeners();
          }
        });
      } else if (id == 'cast') {
        _tiles[index] = tile.copyWith(
          isActive: newActive,
          subtitle: newActive ? 'Streaming' : 'Off',
        );
        SystemHardwareService.triggerCast();
      } else if (id == 'data_saver') {
        _tiles[index] = tile.copyWith(
          isActive: newActive,
          subtitle: newActive ? 'On' : 'Off',
        );
        SystemHardwareService.toggleDataSaver();
      } else if (id == 'extra_dim') {
        _tiles[index] = tile.copyWith(
          isActive: newActive,
          subtitle: newActive ? 'Dimmed' : 'Off',
        );
        SystemHardwareService.toggleExtraDim();
      } else if (id == 'qr_scanner') {
        SystemHardwareService.openQrScanner();
      } else if (id == 'location') {
        _tiles[index] = tile.copyWith(
          isActive: newActive,
          subtitle: newActive ? 'Precise' : 'Off',
        );
        SystemHardwareService.toggleLocation();
      } else if (id == 'nfc') {
        _tiles[index] = tile.copyWith(
          isActive: newActive,
          subtitle: newActive ? 'On' : 'Off',
        );
        SystemHardwareService.toggleNfc();
      } else if (id == 'calculator') {
        SystemHardwareService.openCalculator();
      } else if (id == 'alarm' || id == 'timer' || id == 'stopwatch') {
        SystemHardwareService.openAlarm();
      } else if (id == 'dark_theme') {
        final newMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
        setThemeMode(newMode);
        _tiles[index] = tile.copyWith(
          isActive: newMode == ThemeMode.dark,
          subtitle: newMode == ThemeMode.dark ? 'Dark' : 'Light',
        );
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

      final updatedTile = _tiles[index];
      _updateTile(
        id,
        (t) => t.copyWith(
          isActive: updatedTile.isActive,
          subtitle: updatedTile.subtitle,
        ),
      );

      _scheduleSave({_currentModeTilesKey});
      notifyListeners();
    }
  }

  void addTile(QsTileModel tile) {
    if (!_tiles.any((t) => t.id == tile.id)) {
      final sanitized = (_shadeMode != ShadeMode.nothingOs5 &&
              tile.tileSize == TileSize.size2x2)
          ? tile.copyWith(tileSize: TileSize.size1x2)
          : tile;
      _tiles.add(sanitized);
      _scheduleSave({_currentModeTilesKey});
      notifyListeners();
    }
  }

  void removeTile(String id) {
    if (_tiles.length > 1) {
      _tiles.removeWhere((t) => t.id == id);
      _scheduleSave({_currentModeTilesKey});
      notifyListeners();
    }
  }

  void resetTiles() {
    _tiles.clear();
    _tiles.addAll(QsTileModel.defaultTilesForMode(_shadeMode));
    _configureNetworkTiles(_networkTileStyle);
    _scheduleSave({_currentModeTilesKey});
    notifyListeners();
  }

  void reorderTile(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _tiles.length) return;
    if (newIndex < 0 || newIndex >= _tiles.length) return;
    final tile = _tiles.removeAt(oldIndex);
    _tiles.insert(newIndex, tile);
    _scheduleSave({_currentModeTilesKey});
    notifyListeners();
  }

  void moveTile(String fromId, String toId) {
    final oldIndex = _tiles.indexWhere((t) => t.id == fromId);
    final newIndex = _tiles.indexWhere((t) => t.id == toId);
    if (oldIndex != -1 && newIndex != -1 && oldIndex != newIndex) {
      final tile = _tiles.removeAt(oldIndex);
      _tiles.insert(newIndex, tile);
      _scheduleSave({_currentModeTilesKey});
      notifyListeners();
    }
  }

  void _scheduleMediaRefreshBurst() {
    Future.delayed(const Duration(milliseconds: 200), _loadLiveMedia);
    Future.delayed(const Duration(milliseconds: 500), _loadLiveMedia);
    Future.delayed(const Duration(milliseconds: 900), _loadLiveMedia);
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    SystemMediaService.controlMedia('toggle');
    notifyListeners();
    _scheduleMediaRefreshBurst();
  }

  void skipNextMedia() {
    SystemMediaService.controlMedia('next');
    _scheduleMediaRefreshBurst();
  }

  void skipPreviousMedia() {
    SystemMediaService.controlMedia('prev');
    _scheduleMediaRefreshBurst();
  }

  void setMediaProgress(double val) {
    _mediaProgress = val.clamp(0.0, 1.0);
    SystemMediaService.seekTo(_mediaProgress);
    notifyListeners();
  }

  void dismissNotification(String id) {
    _locallyDismissedIds.add(id);
    _notifications.removeWhere((n) => n.id == id);
    SystemNotificationService.cancelNotification(id);
    notifyListeners();
  }

  void dismissAllForApp(String appName) {
    final toRemove =
        _notifications.where((n) => n.appName == appName && n.isClearable).toList();
    for (final notif in toRemove) {
      _locallyDismissedIds.add(notif.id);
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

  void setNotificationCategoryOverride(
    NotificationModel notif,
    NotificationCategory category,
  ) {
    final pkg =
        notif.packageName.isNotEmpty ? notif.packageName : notif.appName;
    SmartNotificationClassifier.setUserOverride(
      packageName: pkg,
      channelId: notif.channelId,
      category: category,
    );
    _reclassifyExistingNotifications();
    _scheduleSave({'notificationCategoryOverrides'});
    notifyListeners();
  }

  bool _smartClassifierEnabled = true;
  bool get isSmartClassifierEnabled => _smartClassifierEnabled;

  void setSmartClassifierEnabled(bool enabled) {
    if (_smartClassifierEnabled == enabled) return;
    _smartClassifierEnabled = enabled;
    SmartNotificationClassifier.isEnabled = enabled;
    _reclassifyExistingNotifications();
    _scheduleSave({'smartClassifierEnabled'});
    notifyListeners();
  }

  void _reclassifyExistingNotifications() {
    if (_notifications.isEmpty) return;
    _notifications = _notifications.map((n) {
      if (!_smartClassifierEnabled) {
        return n.copyWith(
          category: NotificationCategory.silent,
          categoryConfidence: 0.0,
          extractedOtp: null,
        );
      }
      final pkg = n.packageName.isNotEmpty ? n.packageName : n.appName;
      final res = SmartNotificationClassifier.classify(
        appName: n.appName,
        packageName: pkg,
        title: n.title,
        content: n.content,
        channelId: n.channelId,
        androidCategory: n.androidCategory,
        isConversation: n.isConversation,
        hasReplyAction: n.actions.any((a) => a.hasRemoteInput),
      );
      return n.copyWith(
        category: res.category,
        categoryConfidence: res.confidence,
        extractedOtp: res.extractedOtp,
        isUserCategoryOverride: res.isUserOverride,
      );
    }).toList();
  }

  // Ringer Mode for NothingOS 5 3-dot pill (0: Silent, 1: Vibrate, 2: Ring)
  int _ringerMode = 2;
  int get ringerMode => _ringerMode;

  void setRingerMode(int mode) {
    final clamped = mode.clamp(0, 2);
    _ringerMode = clamped;
    SystemHardwareService.setRingerMode(clamped);
    notifyListeners();
  }

  void cycleRingerMode() {
    setRingerMode((_ringerMode + 1) % 3);
  }

  void toggleTileSize(String id) {
    final index = _tiles.indexWhere((t) => t.id == id);
    if (index != -1) {
      final tile = _tiles[index];
      final nextSize = _shadeMode == ShadeMode.nothingOs5
          ? tile.tileSize.next
          : (tile.isWide ? TileSize.size1x1 : TileSize.size1x2);
      _tiles[index] = tile.copyWith(tileSize: nextSize);
      _scheduleSave({_currentModeTilesKey});
      notifyListeners();
    }
  }

  void cycleTileSize(String id) {
    final index = _tiles.indexWhere((t) => t.id == id);
    if (index != -1) {
      final tile = _tiles[index];
      final nextSize = _shadeMode == ShadeMode.nothingOs5
          ? tile.tileSize.next
          : (tile.isWide ? TileSize.size1x1 : TileSize.size1x2);
      _tiles[index] = tile.copyWith(tileSize: nextSize);
      _scheduleSave({_currentModeTilesKey});
      notifyListeners();
    }
  }

  void setTileExactSize(String id, TileSize size) {
    final index = _tiles.indexWhere((t) => t.id == id);
    if (index != -1) {
      final tile = _tiles[index];
      final resolvedSize = (_shadeMode != ShadeMode.nothingOs5 &&
              size == TileSize.size2x2)
          ? TileSize.size1x2
          : size;
      if (tile.tileSize != resolvedSize) {
        _tiles[index] = tile.copyWith(tileSize: resolvedSize);
        _scheduleSave({_currentModeTilesKey});
        notifyListeners();
      }
    }
  }

  void setTileSize(String id, bool isWide) {
    setTileExactSize(id, isWide ? TileSize.size1x2 : TileSize.size1x1);
  }

  void resetTileSizes() {
    final defaults = QsTileModel.defaultTilesForMode(_shadeMode);
    for (int i = 0; i < _tiles.length; i++) {
      final defaultTile = defaults.firstWhere(
        (dt) => dt.id == _tiles[i].id,
        orElse: () => _tiles[i],
      );
      _tiles[i] = _tiles[i].copyWith(tileSize: defaultTile.tileSize);
    }
    _scheduleSave({_currentModeTilesKey});
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

  Future<void> openShadeApp() => SystemHardwareService.openShadeApp();

  Future<void> openNotificationHistory() =>
      SystemHardwareService.openNotificationHistory();

  Future<void> openAppNotificationSettings([String? packageName]) =>
      SystemHardwareService.openAppNotificationSettings(packageName);
}

extension on String {
  bool get isNotBlank => trim().isNotEmpty;
}
