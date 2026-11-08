import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/app_dock_item.dart';
import '../../../../models/font_config.dart';
import '../../../../models/media_player_style.dart';
import '../../../../models/notification_model.dart';
import '../../../../models/notification_style.dart';
import '../../../../models/qs_tile_model.dart';
import '../../../../models/slider_style.dart';
import '../../../../services/system_apps_service.dart';
import '../../../../theme/m3_expressive_theme.dart';
import '../../../../widgets/expressive_media_card.dart';
import '../../../../widgets/expressive_pill.dart';
import '../../../../widgets/expressive_slider.dart';
import '../../notifications/notification_list.dart';
import '../common/shade_tiles_grid.dart';

class SplitShadeView extends StatelessWidget {
  final PageController pageController;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final List<QsTileModel> tiles;
  final double brightness;
  final double volume;
  final SliderStyle sliderStyle;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<String> onToggleTile;
  final ValueChanged<String> onLongPressTile;
  final ValueChanged<String> onResizeTile;
  final ValueNotifier<TileImpulse?>? impulseNotifier;
  final ValueChanged<int> onPageChanged;

  // Media
  final String mediaTitle;
  final String mediaArtist;
  final String mediaApp;
  final bool isPlaying;
  final double mediaProgress;
  final dynamic mediaArtwork;
  final MediaPlayerStyle mediaPlayerStyle;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipNext;
  final VoidCallback onSkipPrevious;
  final ValueChanged<double> onProgressChanged;

  // Notifications
  final List<NotificationModel> notifications;
  final NotificationStyle notificationStyle;
  final ValueChanged<String> onDismissNotification;
  final void Function(NotificationModel, NotificationAction)? onActionTap;
  final void Function(NotificationModel, NotificationAction, String)? onReply;
  final void Function(NotificationModel)? onOpenNotification;
  final void Function(NotificationModel)? onSnoozeNotification;

  // App Dock (Split Shade Mode only)
  final bool appDockEnabled;
  final List<AppDockItem> appDockApps;
  final ValueChanged<String>? onLaunchApp;

  const SplitShadeView({
    super.key,
    required this.pageController,
    required this.colors,
    required this.font,
    required this.tiles,
    required this.brightness,
    required this.volume,
    required this.sliderStyle,
    required this.onBrightnessChanged,
    required this.onVolumeChanged,
    required this.onToggleTile,
    required this.onLongPressTile,
    required this.onResizeTile,
    required this.impulseNotifier,
    required this.onPageChanged,
    required this.mediaTitle,
    required this.mediaArtist,
    required this.mediaApp,
    required this.isPlaying,
    required this.mediaProgress,
    this.mediaArtwork,
    required this.mediaPlayerStyle,
    required this.onPlayPause,
    required this.onSkipNext,
    required this.onSkipPrevious,
    required this.onProgressChanged,
    required this.notifications,
    this.notificationStyle = NotificationStyle.android17,
    required this.onDismissNotification,
    this.onActionTap,
    this.onReply,
    this.onOpenNotification,
    this.onSnoozeNotification,
    this.appDockEnabled = false,
    this.appDockApps = const [],
    this.onLaunchApp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Expanded(
          child: PageView(
            controller: pageController,
            onPageChanged: onPageChanged,
            children: [
              // Page 0: Dedicated Notifications Sheet & Optional App Dock Card
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.notificationContainerBackground,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: colors.isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                            width: 1.0,
                          ),
                        ),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                          children: [
                            NotificationList(
                              notifications: notifications,
                              colors: colors,
                              font: font,
                              style: notificationStyle,
                              onDismiss: onDismissNotification,
                              onActionTap: onActionTap,
                              onReply: onReply,
                              onTap: onOpenNotification,
                              onSnooze: onSnoozeNotification,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (appDockEnabled && appDockApps.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildAppDockCard(context),
                    ],
                  ],
                ),
              ),

              // Page 1: Control Center Panel (Completely Opaque Tiles)
              Container(
                color: colors.background,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                  // Brightness Slider
                  ExpressiveSlider(
                    value: brightness,
                    onChanged: onBrightnessChanged,
                    leadingIcon: Icons.wb_sunny_rounded,
                    trailingIcon: Icons.auto_mode_rounded,
                    onTrailingTap: () => HapticFeedback.lightImpact(),
                    colors: colors,
                    style: sliderStyle,
                  ),
                  const SizedBox(height: 10),

                  // Volume Slider
                  ExpressiveSlider(
                    value: volume,
                    onChanged: onVolumeChanged,
                    leadingIcon: volume == 0
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    trailingIcon: Icons.more_vert_rounded,
                    onTrailingTap: () => HapticFeedback.lightImpact(),
                    colors: colors,
                    style: sliderStyle,
                  ),
                  const SizedBox(height: 16),

                  // Tiles Grid
                  _buildDynamicTilesGrid(),
                  const SizedBox(height: 24),

                  // Media Card
                  ExpressiveMediaCard(
                    title: mediaTitle,
                    artist: mediaArtist,
                    appSource: mediaApp,
                    isPlaying: isPlaying,
                    progress: mediaProgress,
                    artwork: mediaArtwork,
                    colors: colors,
                    font: font,
                    style: mediaPlayerStyle,
                    onPlayPause: onPlayPause,
                    onSkipNext: onSkipNext,
                    onSkipPrevious: onSkipPrevious,
                    onProgressChanged: onProgressChanged,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicTilesGrid() {
    final rows = packTilesIntoRows(tiles);

    if (rows.length <= 5) {
      return _buildTilesGridPage(rows, 0);
    }

    final List<List<List<QsTileModel>>> pages = [];
    for (int i = 0; i < rows.length; i += 5) {
      final end = (i + 5 < rows.length) ? i + 5 : rows.length;
      pages.add(rows.sublist(i, end));
    }

    const double fixedHeight = (5 * 68.0) + (4 * 12.0) + 2.0;

    return PaginatedTilesContainer(
      colors: colors,
      pages: pages,
      fixedHeight: fixedHeight,
      builder: (context, pageIndex) {
        return _buildTilesGridPage(pages[pageIndex], pageIndex * 5);
      },
    );
  }

  Widget _buildTilesGridPage(List<List<QsTileModel>> rows, int baseRowIndex) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 12),
          Row(
            children: [
              for (int t = 0; t < rows[r].length; t++) ...[
                if (t > 0) const SizedBox(width: 10),
                Expanded(
                  flex: rows[r][t].isWide ? 2 : 1,
                  child: ExpressivePill(
                    tile: rows[r][t],
                    colors: colors,
                    font: font,
                    row: baseRowIndex + r,
                    col: t,
                    impulseNotifier: impulseNotifier,
                    onResizeTap: () => onResizeTile(rows[r][t].id),
                    onTap: () => onToggleTile(rows[r][t].id),
                    onLongPress: () => onLongPressTile(rows[r][t].id),
                  ),
                ),
              ],
              if (rowSpan(rows[r]) < 4) Spacer(flex: 4 - rowSpan(rows[r])),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAppDockCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.notificationContainerBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colors.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1.0,
        ),
      ),
      child: _buildAppDockGrid(),
    );
  }

  Widget _buildAppDockGrid() {
    final rows = <List<AppDockItem>>[];
    for (int i = 0; i < appDockApps.length; i += 4) {
      final end = (i + 4 < appDockApps.length) ? i + 4 : appDockApps.length;
      rows.add(appDockApps.sublist(i, end));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 10),
          Row(
            children: [
              for (int c = 0; c < rows[r].length; c++) ...[
                if (c > 0) const SizedBox(width: 8),
                Expanded(
                  child: _AppDockTile(
                    item: rows[r][c],
                    font: font,
                    colors: colors,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onLaunchApp?.call(rows[r][c].packageName);
                    },
                  ),
                ),
              ],
              if (rows[r].length < 4)
                for (int s = 0; s < 4 - rows[r].length; s++) ...[
                  const SizedBox(width: 8),
                  const Spacer(),
                ],
            ],
          ),
        ],
      ],
    );
  }
}

class _AppDockTile extends StatefulWidget {
  final AppDockItem item;
  final FontConfig font;
  final ExpressiveThemeColors colors;
  final VoidCallback onTap;

  const _AppDockTile({
    required this.item,
    required this.font,
    required this.colors,
    required this.onTap,
  });

  @override
  State<_AppDockTile> createState() => _AppDockTileState();
}

class _AppDockTileState extends State<_AppDockTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  Uint8List? _iconBytes;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutQuad,
        reverseCurve: Curves.easeOutBack,
      ),
    );
    _loadIcon();
  }

  Future<void> _loadIcon() async {
    final bytes = await SystemAppsService.getAppIcon(widget.item.packageName);
    if (mounted && bytes != null) {
      setState(() => _iconBytes = bytes);
    }
  }

  @override
  void didUpdateWidget(covariant _AppDockTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.packageName != widget.item.packageName) {
      _loadIcon();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tileColor = widget.item.color;
    final isDarkBg =
        ThemeData.estimateBrightnessForColor(tileColor) == Brightness.dark;
    final fgColor = isDarkBg ? Colors.white : Colors.black87;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _animController.forward(),
      onTapUp: (_) {
        _animController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _animController.reverse(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
            child: Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: tileColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: _iconBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _iconBytes!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                        ),
                      )
                    : Icon(
                        _getFallbackAppIcon(
                          widget.item.packageName,
                          widget.item.appName,
                        ),
                        size: 26,
                        color: fgColor,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.item.appName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: widget.font.textStyleBuilder(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _getFallbackAppIcon(String packageName, String appName) {
    final p = packageName.toLowerCase();
    final n = appName.toLowerCase();
    if (p.contains('camera') || n.contains('camera')) return Icons.camera_alt_rounded;
    if (p.contains('dialer') || p.contains('phone') || n.contains('phone') || n.contains('call')) {
      return Icons.phone_rounded;
    }
    if (p.contains('message') || p.contains('sms') || n.contains('message') || n.contains('chat')) {
      return Icons.chat_bubble_rounded;
    }
    if (p.contains('chrome') || p.contains('browser') || n.contains('browser') || n.contains('web')) {
      return Icons.language_rounded;
    }
    if (p.contains('music') || p.contains('spotify') || n.contains('music') || n.contains('audio')) {
      return Icons.music_note_rounded;
    }
    if (p.contains('gallery') || p.contains('photo') || n.contains('photo') || n.contains('image')) {
      return Icons.photo_library_rounded;
    }
    if (p.contains('clock') || p.contains('alarm') || n.contains('clock') || n.contains('alarm')) {
      return Icons.access_time_rounded;
    }
    if (p.contains('settings') || n.contains('settings')) return Icons.settings_rounded;
    if (p.contains('mail') || p.contains('gmail') || n.contains('mail')) return Icons.mail_rounded;
    if (p.contains('map') || n.contains('map')) return Icons.map_rounded;
    if (p.contains('calc') || n.contains('calc')) return Icons.calculate_rounded;
    if (p.contains('calendar') || n.contains('calendar')) return Icons.calendar_month_rounded;
    if (p.contains('video') || p.contains('youtube') || n.contains('video') || n.contains('youtube')) {
      return Icons.play_arrow_rounded;
    }
    return Icons.apps_rounded;
  }
}
