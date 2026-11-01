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

class ShadeStateProvider extends ChangeNotifier {
  static const MethodChannel _overlayEventsChannel = MethodChannel('com.expressive_shade/overlay_events');

  ShadeStateProvider() {
    _loadSystemMonetColor();
    _loadInitialHardwareValues();
    refreshPermissions();
    _initLiveServices();
  }

  void _initLiveServices() {
    // Listen for top pull-down panel gestures from background overlay service
    _overlayEventsChannel.setMethodCallHandler((call) async {
      if (call.method == 'onPanelTriggered') {
        final target = call.arguments?.toString();
        if (target == 'notifications') {
          _splitTabIndex = 0;
        } else if (target == 'quick_settings') {
          _splitTabIndex = 1;
        }
        notifyListeners();
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

  // Slider Style
  SliderStyle _sliderStyle = SliderStyle.separatedBar;
  SliderStyle get sliderStyle => _sliderStyle;

  void setSliderStyle(SliderStyle style) {
    _sliderStyle = style;
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

  // Hardware Initial Values
  Future<void> _loadInitialHardwareValues() async {
    final values = await SystemHardwareService.getInitialValues();
    if (values != null) {
      if (values['brightness'] is num) {
        _brightness = (values['brightness'] as num).toDouble().clamp(0.0, 1.0);
      }
      if (values['volume'] is num) {
        _volume = (values['volume'] as num).toDouble().clamp(0.0, 1.0);
      }
      if (values['autoRotate'] is bool) {
        final autoRotateIndex = _tiles.indexWhere((t) => t.id == 'autorotate');
        if (autoRotateIndex != -1) {
          _tiles[autoRotateIndex] = _tiles[autoRotateIndex].copyWith(isActive: values['autoRotate'] as bool);
        }
      }
      notifyListeners();
    }
  }

  // Shade Mode (Split vs Unified)
  ShadeMode _shadeMode = ShadeMode.split;
  ShadeMode get shadeMode => _shadeMode;

  // Split Panel Tab (0: Notifications, 1: Quick Settings)
  int _splitTabIndex = 1; // Default to Quick Settings in preview
  int get splitTabIndex => _splitTabIndex;

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

  // Media Player State
  bool _isPlaying = true;
  bool get isPlaying => _isPlaying;

  double _mediaProgress = 0.35;
  double get mediaProgress => _mediaProgress;

  String _mediaTitle = 'Sunflower';
  String get mediaTitle => _mediaTitle;

  String _mediaArtist = 'Post Malone, Swae Lee';
  String get mediaArtist => _mediaArtist;

  String _mediaApp = 'Spotify';
  String get mediaApp => _mediaApp;

  Future<void> _loadLiveMedia() async {
    final media = await SystemMediaService.getMediaState();
    if (media != null) {
      _mediaTitle = media.title;
      _mediaArtist = media.artist;
      _mediaApp = media.appName;
      _isPlaying = media.isPlaying;
      _mediaProgress = media.progress;
      notifyListeners();
    }
  }

  // Notifications
  List<NotificationModel> _notifications = List.from(NotificationModel.sampleNotifications);
  List<NotificationModel> get notifications => _notifications;

  Future<void> _loadLiveNotifications() async {
    final liveList = await SystemNotificationService.getActiveNotifications();
    if (liveList.isNotEmpty) {
      _notifications = liveList;
      notifyListeners();
    }
  }

  // --- Actions ---

  void setShadeMode(ShadeMode mode) {
    _shadeMode = mode;
    notifyListeners();
  }

  void setSplitTabIndex(int index) {
    _splitTabIndex = index;
    notifyListeners();
  }

  void setFont(FontConfig font) {
    _selectedFont = font;
    notifyListeners();
  }

  void setThemeSource(ThemeSource source) {
    _themeSource = source;
    notifyListeners();
  }

  void selectPreset(ThemePreset preset) {
    _selectedPreset = preset;
    _themeSource = ThemeSource.preset;
    notifyListeners();
  }

  void updateCustomTheme(CustomThemeData custom) {
    _customTheme = custom;
    _themeSource = ThemeSource.custom;
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
      _tiles[index] = tile.copyWith(isActive: newActive);

      if (id == 'flashlight') {
        SystemHardwareService.setFlashlight(newActive);
      } else if (id == 'wifi') {
        SystemHardwareService.openWifiSettings();
      } else if (id == 'bluetooth') {
        SystemHardwareService.openBluetoothSettings();
      } else if (id == 'autorotate') {
        SystemHardwareService.toggleAutoRotate().then((res) {
          if (res != null) {
            _tiles[index] = tile.copyWith(isActive: res);
            notifyListeners();
          }
        });
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
