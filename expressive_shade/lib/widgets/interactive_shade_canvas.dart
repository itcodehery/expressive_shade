import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/font_config.dart';
import '../models/qs_tile_model.dart';
import '../models/shade_mode.dart';
import '../providers/shade_state_provider.dart';
import '../services/system_hardware_service.dart';
import '../theme/m3_expressive_theme.dart';
import 'expressive_media_card.dart';
import 'expressive_notification_card.dart';
import 'expressive_pill.dart';
import 'expressive_power_menu_dialog.dart';
import 'expressive_slider.dart';

class InteractiveShadeCanvas extends StatefulWidget {
  final ExpressiveThemeColors colors;

  const InteractiveShadeCanvas({super.key, required this.colors});

  @override
  State<InteractiveShadeCanvas> createState() => _InteractiveShadeCanvasState();
}

class _InteractiveShadeCanvasState extends State<InteractiveShadeCanvas>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  bool _isEditMode = false;
  String? _selectedTileId;

  @override
  void initState() {
    super.initState();
    final initialPage = context.read<ShadeStateProvider>().splitTabIndex;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShadeStateProvider>();
    final colors = widget.colors;

    return Container(
      color: colors.background,
      child: SafeArea(
        child: Column(
          children: [
            // Status Bar & System Header
            _buildStatusBar(state, colors),

            // Secondary Quick Actions Header or Edit Tiles Header
            if (_isEditMode)
              _buildEditHeaderControls(state, colors)
            else
              _buildHeaderControls(state, colors),

            // In Split Mode: Segmented View Selector (Notifications vs Quick Settings)
            if (state.shadeMode == ShadeMode.split && !_isEditMode) ...[
              const SizedBox(height: 12),
              _buildSplitModeSegmentedTabs(state, colors),
            ],

            const SizedBox(height: 14),

            // Main Content Area
            Expanded(
              child: state.shadeMode == ShadeMode.split
                  ? _buildSplitShadePageView(state, colors)
                  : _buildUnifiedShadeView(state, colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(ShadeStateProvider state, ExpressiveThemeColors colors) {
    final font = state.selectedFont;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Clock & Date
          Row(
            children: [
              Text(
                '10:29',
                style: font.textStyleBuilder(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tue, Jan 13',
                style: font.textStyleBuilder(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),

          // Status Icons
          Row(
            children: [
              Icon(Icons.wifi_rounded, size: 16, color: colors.textPrimary),
              const SizedBox(width: 6),
              Icon(Icons.signal_cellular_4_bar_rounded, size: 16, color: colors.textPrimary),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.activePill.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      '100%',
                      style: font.textStyleBuilder(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: colors.activePill,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.battery_full_rounded, size: 14, color: colors.activePill),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderControls(ShadeStateProvider state, ExpressiveThemeColors colors) {
    final font = state.selectedFont;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          // Carrier Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sim_card_rounded, size: 14, color: colors.activePill),
                const SizedBox(width: 6),
                Text(
                  'Google Fi 5G',
                  style: font.textStyleBuilder(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Edit Tiles Pencil Button
          _buildCircleHeaderBtn(Icons.edit_outlined, colors, () {
            HapticFeedback.lightImpact();
            setState(() {
              _isEditMode = true;
              _selectedTileId = state.tiles.firstOrNull?.id;
              if (state.shadeMode == ShadeMode.split && state.splitTabIndex == 0) {
                state.setSplitTabIndex(1);
                _pageController.jumpToPage(1);
              }
            });
          }),
          const SizedBox(width: 8),

          // Settings Gear
          _buildCircleHeaderBtn(Icons.settings_outlined, colors, () {
            HapticFeedback.lightImpact();
          }),
          const SizedBox(width: 8),

          // Power Button
          _buildCircleHeaderBtn(Icons.power_settings_new_rounded, colors, () {
            HapticFeedback.lightImpact();
            ExpressivePowerMenuDialog.show(context, colors, font);
          }),
        ],
      ),
    );
  }

  Widget _buildEditHeaderControls(ShadeStateProvider state, ExpressiveThemeColors colors) {
    final font = state.selectedFont;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary, size: 24),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isEditMode = false;
                _selectedTileId = null;
              });
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit tiles',
                  style: font.textStyleBuilder(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  'Drag indicator to resize between 1x1 & 1x2',
                  style: font.textStyleBuilder(
                    fontSize: 12.0,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Reset / Undo
          IconButton(
            tooltip: 'Reset tile sizes',
            icon: Icon(Icons.replay_rounded, color: colors.textSecondary, size: 22),
            onPressed: () {
              HapticFeedback.mediumImpact();
              state.resetTileSizes();
            },
          ),
          const SizedBox(width: 4),
          // Done Button
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isEditMode = false;
                _selectedTileId = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.activePill,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Done',
                style: font.textStyleBuilder(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  color: colors.onActivePill,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleHeaderBtn(IconData icon, ExpressiveThemeColors colors, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, size: 19, color: colors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildSplitModeSegmentedTabs(ShadeStateProvider state, ExpressiveThemeColors colors) {
    final font = state.selectedFont;
    final currentTab = state.splitTabIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildSegmentButton(
                title: 'Notifications',
                badgeCount: state.notifications.length,
                isSelected: currentTab == 0,
                colors: colors,
                font: font,
                onTap: () {
                  HapticFeedback.selectionClick();
                  state.setSplitTabIndex(0);
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.fastOutSlowIn,
                  );
                },
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildSegmentButton(
                title: 'Quick Settings',
                badgeCount: 0,
                isSelected: currentTab == 1,
                colors: colors,
                font: font,
                onTap: () {
                  HapticFeedback.selectionClick();
                  state.setSplitTabIndex(1);
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.fastOutSlowIn,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required int badgeCount,
    required bool isSelected,
    required ExpressiveThemeColors colors,
    required FontConfig font,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.activePill : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: colors.activePill.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: font.textStyleBuilder(
                fontSize: 13.0,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colors.onActivePill : colors.textSecondary,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? colors.onActivePill.withValues(alpha: 0.25) : colors.activePill,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeCount.toString(),
                  style: font.textStyleBuilder(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? colors.onActivePill : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSplitShadePageView(ShadeStateProvider state, ExpressiveThemeColors colors) {
    return PageView(
      controller: _pageController,
      onPageChanged: (pageIndex) {
        state.setSplitTabIndex(pageIndex);
      },
      children: [
        _buildNotificationsPanel(state, colors),
        _buildQuickSettingsPanel(state, colors),
      ],
    );
  }

  Widget _buildQuickSettingsPanel(ShadeStateProvider state, ExpressiveThemeColors colors) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      children: [
        // Brightness Capsule Slider
        ExpressiveSlider(
          value: state.brightness,
          onChanged: (val) => state.setBrightness(val),
          leadingIcon: Icons.wb_sunny_rounded,
          trailingIcon: Icons.auto_mode_rounded,
          onTrailingTap: () {
            HapticFeedback.lightImpact();
          },
          colors: colors,
          style: state.sliderStyle,
        ),
        const SizedBox(height: 10),

        // Volume Capsule Slider
        ExpressiveSlider(
          value: state.volume,
          onChanged: (val) => state.setVolume(val),
          leadingIcon: state.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          trailingIcon: Icons.more_vert_rounded,
          onTrailingTap: () {
            HapticFeedback.lightImpact();
          },
          colors: colors,
          style: state.sliderStyle,
        ),
        const SizedBox(height: 16),

        // Dynamic 4-Column Grid of 1x2 and 1x1 Tiles
        _buildDynamicTilesGrid(state, colors),
        const SizedBox(height: 24),

        // Expressive Media Card
        ExpressiveMediaCard(
          title: state.mediaTitle,
          artist: state.mediaArtist,
          appSource: state.mediaApp,
          isPlaying: state.isPlaying,
          progress: state.mediaProgress,
          colors: colors,
          font: state.selectedFont,
          onPlayPause: () => state.togglePlayPause(),
          onSkipNext: () => state.skipNextMedia(),
          onSkipPrevious: () => state.skipPreviousMedia(),
          onProgressChanged: (val) => state.setMediaProgress(val),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDynamicTilesGrid(ShadeStateProvider state, ExpressiveThemeColors colors) {
    final font = state.selectedFont;
    final rows = _packTilesIntoRows(state.tiles);

    return Column(
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
                    isEditing: _isEditMode,
                    isSelected: _isEditMode && _selectedTileId == rows[r][t].id,
                    onResizeTap: () => state.toggleTileSize(rows[r][t].id),
                    onInnerButtonTap: (rows[r][t].id == 'wifi' || rows[r][t].id == 'bluetooth')
                        ? () {
                            // Tapping inner button toggles wifi/mobile data or bluetooth directly
                            state.toggleTile(rows[r][t].id);
                          }
                        : null,
                    onOuterPillTap: (rows[r][t].id == 'wifi' || rows[r][t].id == 'bluetooth')
                        ? () {
                            // Tapping pill outside the inner button opens floating dialog box
                            if (rows[r][t].id == 'wifi') {
                              _showInternetDialog(context, state, colors);
                            } else {
                              _showBluetoothDialog(context, state, colors);
                            }
                          }
                        : null,
                    onTap: () {
                      if (_isEditMode) {
                        setState(() => _selectedTileId = rows[r][t].id);
                      } else {
                        state.toggleTile(rows[r][t].id);
                      }
                    },
                    onLongPress: () {
                      HapticFeedback.heavyImpact();
                      setState(() {
                        _isEditMode = true;
                        _selectedTileId = rows[r][t].id;
                      });
                    },
                  ),
                ),
              ],
              if (_rowSpan(rows[r]) < 4)
                Spacer(flex: 4 - _rowSpan(rows[r])),
            ],
          ),
        ],
      ],
    );
  }

  int _rowSpan(List<QsTileModel> row) {
    return row.fold(0, (sum, t) => sum + (t.isWide ? 2 : 1));
  }

  List<List<QsTileModel>> _packTilesIntoRows(List<QsTileModel> tiles) {
    final List<List<QsTileModel>> rows = [];
    List<QsTileModel> currentRow = [];
    int currentSpan = 0;

    for (final tile in tiles) {
      final span = tile.isWide ? 2 : 1;
      if (currentSpan + span > 4) {
        if (currentRow.isNotEmpty) {
          rows.add(currentRow);
        }
        currentRow = [tile];
        currentSpan = span;
      } else {
        currentRow.add(tile);
        currentSpan += span;
      }
    }
    if (currentRow.isNotEmpty) {
      rows.add(currentRow);
    }
    return rows;
  }

  Widget _buildNotificationsPanel(ShadeStateProvider state, ExpressiveThemeColors colors) {
    final font = state.selectedFont;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildNotificationsContainer(state, colors, font),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildUnifiedShadeView(ShadeStateProvider state, ExpressiveThemeColors colors) {
    final font = state.selectedFont;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Quick Settings elements (padded 20px horizontally)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brightness Capsule Slider
              ExpressiveSlider(
                value: state.brightness,
                onChanged: (val) => state.setBrightness(val),
                leadingIcon: Icons.wb_sunny_rounded,
                colors: colors,
                style: state.sliderStyle,
              ),
              const SizedBox(height: 12),

              // Volume Capsule Slider
              ExpressiveSlider(
                value: state.volume,
                onChanged: (val) => state.setVolume(val),
                leadingIcon: state.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                colors: colors,
                style: state.sliderStyle,
              ),
              const SizedBox(height: 16),

              // Dynamic Tiles Grid
              _buildDynamicTilesGrid(state, colors),
              const SizedBox(height: 20),

              // Expressive Media Card
              ExpressiveMediaCard(
                title: state.mediaTitle,
                artist: state.mediaArtist,
                appSource: state.mediaApp,
                isPlaying: state.isPlaying,
                progress: state.mediaProgress,
                colors: colors,
                font: font,
                onPlayPause: () => state.togglePlayPause(),
                onSkipNext: () => state.skipNextMedia(),
                onSkipPrevious: () => state.skipPreviousMedia(),
                onProgressChanged: (val) => state.setMediaProgress(val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Distinct Division: Notifications Container with Rounded Top Corners & Acrylic Blur
        _buildNotificationsContainer(state, colors, font),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildNotificationsContainer(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
    FontConfig font,
  ) {
    final blurSigma = state.customTheme.blurIntensity.clamp(4.0, 40.0);
    final cardOpacity = state.customTheme.cardOpacity.clamp(0.1, 1.0);
    // Container itself is slightly less opaque than the cards (allowing the acrylic blur to shine through)
    final containerAlpha = (cardOpacity * 0.42).clamp(0.15, 0.65);
    final containerBg = colors.isDark
        ? colors.surface.withValues(alpha: containerAlpha)
        : colors.surface.withValues(alpha: (containerAlpha + 0.15).clamp(0.2, 0.75));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
          bottom: Radius.circular(32),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: containerBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
                bottom: Radius.circular(32),
              ),
              border: Border.all(
                color: (colors.isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: colors.isDark ? 0.22 : 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.notifications.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 40,
                            color: colors.textSecondary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No notifications',
                            style: font.textStyleBuilder(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You\'re all caught up for right now.',
                            style: font.textStyleBuilder(
                              fontSize: 12.0,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => state.restoreSampleNotifications(),
                            child: Text(
                              'Restore sample notifications',
                              style: font.textStyleBuilder(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                                color: colors.activePill,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  for (final notif in state.notifications)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ExpressiveNotificationCard(
                        notification: notif,
                        colors: colors,
                        font: font,
                        onDismiss: () => state.dismissNotification(notif.id),
                        onActionTap: (_) {
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ),
                  // Clear All Action Row inside container
                  _buildClearAllActionRow(state, colors, font),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearAllActionRow(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
    FontConfig font,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Row(
        children: [
          // Notification History Circle Button
          _buildCircleActionBtn(Icons.history_rounded, colors, () {
            HapticFeedback.lightImpact();
          }),
          const SizedBox(width: 10),
          // Center Pill: Clear all (fills the width of the center!)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                HapticFeedback.mediumImpact();
                state.clearAllNotifications();
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colors.textSecondary.withValues(alpha: 0.15),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Clear all',
                    style: font.textStyleBuilder(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Notification Settings Circle Button
          _buildCircleActionBtn(Icons.tune_rounded, colors, () {
            HapticFeedback.lightImpact();
          }),
        ],
      ),
    );
  }

  Widget _buildCircleActionBtn(IconData icon, ExpressiveThemeColors colors, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.15),
          ),
        ),
        child: Center(
          child: Icon(icon, size: 20, color: colors.textPrimary),
        ),
      ),
    );
  }

  void _showInternetDialog(
    BuildContext context,
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    final font = state.selectedFont;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        return Dialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.activePill.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.wifi_rounded, color: colors.activePill, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Internet',
                            style: font.textStyleBuilder(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            'Wi-Fi & Mobile Network',
                            style: font.textStyleBuilder(
                              fontSize: 12.0,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Connected Wi-Fi Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.activePill.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.activePill.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_rounded, color: colors.activePill, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emad WiFi_EXT',
                              style: font.textStyleBuilder(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Connected • 5 GHz • Excellent signal',
                              style: font.textStyleBuilder(
                                fontSize: 12.0,
                                color: colors.activePill,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.settings_outlined, color: colors.activePill, size: 20),
                        onPressed: () {
                          SystemHardwareService.openWifiSettings();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Mobile Data Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.swap_vert_rounded, color: colors.textPrimary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mobile data',
                              style: font.textStyleBuilder(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              'Vodafone, LTE',
                              style: font.textStyleBuilder(
                                fontSize: 11.5,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: true,
                        activeTrackColor: colors.activePill.withValues(alpha: 0.5),
                        thumbColor: WidgetStateProperty.all(colors.activePill),
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Available Wi-Fi Networks
                Text(
                  'Available Networks',
                  style: font.textStyleBuilder(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildAvailableNetworkItem('Home_5G_Ultra', 'Secured with WPA3', colors, font),
                _buildAvailableNetworkItem('Studio_Guest', 'Open Network', colors, font),
                const SizedBox(height: 16),

                // Dialog Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        SystemHardwareService.openWifiSettings();
                      },
                      child: Text(
                        'Network settings',
                        style: font.textStyleBuilder(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: colors.activePill,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                        decoration: BoxDecoration(
                          color: colors.activePill,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          'Done',
                          style: font.textStyleBuilder(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                            color: colors.onActivePill,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvailableNetworkItem(
    String name,
    String security,
    ExpressiveThemeColors colors,
    FontConfig font,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.wifi_lock_rounded, size: 18, color: colors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: font.textStyleBuilder(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  security,
                  style: font.textStyleBuilder(
                    fontSize: 11.0,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: colors.textSecondary),
        ],
      ),
    );
  }

  void _showBluetoothDialog(
    BuildContext context,
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    final font = state.selectedFont;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        return Dialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.activePill.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.bluetooth_rounded, color: colors.activePill, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bluetooth',
                            style: font.textStyleBuilder(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            'Paired & Active Devices',
                            style: font.textStyleBuilder(
                              fontSize: 12.0,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Connected Device Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.activePill.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.activePill.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.headphones_rounded, color: colors.activePill, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emad\'s Pixel Buds Pro',
                              style: font.textStyleBuilder(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Active • 100% battery',
                              style: font.textStyleBuilder(
                                fontSize: 12.0,
                                color: colors.activePill,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.settings_outlined, color: colors.activePill, size: 20),
                        onPressed: () {
                          SystemHardwareService.openBluetoothSettings();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Previously Paired Devices
                Text(
                  'Previously Connected',
                  style: font.textStyleBuilder(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPairedDeviceItem('Car Multimedia', Icons.directions_car_rounded, colors, font),
                _buildPairedDeviceItem('Smartwatch 2', Icons.watch_rounded, colors, font),
                const SizedBox(height: 16),

                // Dialog Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        SystemHardwareService.openBluetoothSettings();
                      },
                      child: Text(
                        'Pair new device',
                        style: font.textStyleBuilder(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: colors.activePill,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                        decoration: BoxDecoration(
                          color: colors.activePill,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          'Done',
                          style: font.textStyleBuilder(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                            color: colors.onActivePill,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPairedDeviceItem(
    String name,
    IconData icon,
    ExpressiveThemeColors colors,
    FontConfig font,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: font.textStyleBuilder(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: colors.textSecondary),
        ],
      ),
    );
  }
}
