import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/font_config.dart';
import '../models/notification_model.dart';
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
  final void Function(VoidCallback action)? onDismissAndExecute;

  const InteractiveShadeCanvas({
    super.key,
    required this.colors,
    this.onDismissAndExecute,
  });

  @override
  State<InteractiveShadeCanvas> createState() => _InteractiveShadeCanvasState();
}

class _InteractiveShadeCanvasState extends State<InteractiveShadeCanvas>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  final ScrollController _unifiedScrollController = ScrollController();
  final ValueNotifier<TileImpulse?> _tileImpulseNotifier = ValueNotifier<TileImpulse?>(null);
  late AnimationController _qsBouncyController;
  late Animation<double> _bouncyCurveAnimation;
  bool _isDraggingQs = false;
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();
  bool _isEditMode = false;
  String? _selectedTileId;
  String _lastTarget = '';

  void _handleTileAction(VoidCallback action) {
    if (widget.onDismissAndExecute != null) {
      widget.onDismissAndExecute!(action);
    } else {
      action();
    }
  }

  @override
  void initState() {
    super.initState();
    final initialPage = context.read<ShadeStateProvider>().splitTabIndex;
    final initialExpanded = context.read<ShadeStateProvider>().isUnifiedQsExpanded;
    _pageController = PageController(initialPage: initialPage);
    _qsBouncyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: initialExpanded ? 1.0 : 0.0,
    );
    _bouncyCurveAnimation = CurvedAnimation(
      parent: _qsBouncyController,
      curve: Curves.easeOutBack, // Android 17 Expressive Spring Bounce
      reverseCurve: Curves.easeInOutCubic,
    );
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _tileImpulseNotifier.dispose();
    _qsBouncyController.dispose();
    _pageController.dispose();
    _unifiedScrollController.dispose();
    super.dispose();
  }

  void _handleTargetScroll(ShadeStateProvider state) {
    if (state.targetPanel != _lastTarget) {
      _lastTarget = state.targetPanel;
      if (state.shadeMode == ShadeMode.unified) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_unifiedScrollController.hasClients) {
            if (_lastTarget == 'notifications') {
              _unifiedScrollController.animateTo(
                180.0,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
              );
            } else {
              _unifiedScrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
              );
            }
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShadeStateProvider>();
    final colors = widget.colors;
    _handleTargetScroll(state);

    final isExpanded = state.isUnifiedQsExpanded;
    if (!_isDraggingQs) {
      if (isExpanded && _qsBouncyController.status != AnimationStatus.forward && _qsBouncyController.value < 1.0) {
        _qsBouncyController.animateTo(1.0, curve: Curves.easeOutBack, duration: const Duration(milliseconds: 380));
      } else if (!isExpanded && _qsBouncyController.status != AnimationStatus.reverse && _qsBouncyController.value > 0.0) {
        _qsBouncyController.animateTo(0.0, curve: Curves.easeInOutCubic, duration: const Duration(milliseconds: 280));
      }
    }

    return Container(
      color: colors.background,
      child: SafeArea(
        top: false, // Render behind and over the status bar completely
        bottom: true,
        child: Column(
          children: [
            // Status Bar & System Header (renders directly over physical status bar)
            _buildStatusBar(state, colors),

            // Secondary Quick Actions Header or Edit Tiles Header
            if (_isEditMode)
              _buildEditHeaderControls(state, colors)
            else
              _buildHeaderControls(state, colors),

            const SizedBox(height: 6),

            // Main Canvas: Dual Mode Engine (Split vs Unified)
            Expanded(
              child: state.shadeMode == ShadeMode.split
                  ? _buildSplitModeView(state, colors)
                  : _buildUnifiedShadeView(state, colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(ShadeStateProvider state, ExpressiveThemeColors colors) {
    final font = state.selectedFont;
    final topPadding = MediaQuery.of(context).padding.top;

    final hour = _currentTime.hour.toString().padLeft(2, '0');
    final minute = _currentTime.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${weekdays[_currentTime.weekday - 1]}, ${months[_currentTime.month - 1]} ${_currentTime.day}';

    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPadding > 0 ? topPadding + 6 : 14, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Live Clock & Date
          Row(
            children: [
              Text(
                timeStr,
                style: font.textStyleBuilder(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: font.textStyleBuilder(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),

          // Status Icons & Live Battery Percentage
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
                      '${state.batteryLevel}%',
                      style: font.textStyleBuilder(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: colors.activePill,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      state.isCharging ? Icons.battery_charging_full_rounded : Icons.battery_full_rounded,
                      size: 14,
                      color: colors.activePill,
                    ),
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
          // Live Carrier Pill
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
                  state.carrierName,
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
            SystemHardwareService.openWifiSettings();
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.activePill : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.onActivePill.withValues(alpha: 0.20)
                      : colors.activePill.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: font.textStyleBuilder(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? colors.onActivePill : colors.activePill,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSplitModeView(ShadeStateProvider state, ExpressiveThemeColors colors) {
    return Column(
      children: [
        _buildSplitModeSegmentedTabs(state, colors),
        const SizedBox(height: 12),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              state.setSplitTabIndex(index);
            },
            children: [
              _buildNotificationsPanel(state, colors),
              _buildQuickSettingsPanel(state, colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSettingsPanel(ShadeStateProvider state, ExpressiveThemeColors colors) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
          artwork: state.mediaArtwork,
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
    return _buildDynamicTilesGridCustom(state, colors, _packTilesIntoRows(state.tiles));
  }

  Widget _buildDynamicTilesGridCustom(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
    List<List<QsTileModel>> rows,
  ) {
    final font = state.selectedFont;

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
                    row: r,
                    col: t,
                    impulseNotifier: _tileImpulseNotifier,
                    isEditing: _isEditMode,
                    isSelected: _isEditMode && _selectedTileId == rows[r][t].id,
                    onResizeTap: () => state.toggleTileSize(rows[r][t].id),
                    onInnerButtonTap: (rows[r][t].id == 'wifi' || rows[r][t].id == 'bluetooth' || rows[r][t].id == 'mobile_data')
                        ? () {
                            _handleTileAction(() {
                              state.toggleTile(rows[r][t].id);
                            });
                          }
                        : null,
                    onOuterPillTap: (rows[r][t].id == 'wifi' || rows[r][t].id == 'bluetooth' || rows[r][t].id == 'mobile_data')
                        ? () {
                            if (rows[r][t].id == 'wifi') {
                              if (state.networkTileStyle == NetworkTileStyle.unified) {
                                _showInternetDialog(context, state, colors);
                              } else {
                                _handleTileAction(() {
                                  SystemHardwareService.openWifiSettings();
                                });
                              }
                            } else if (rows[r][t].id == 'mobile_data') {
                              _handleTileAction(() {
                                SystemHardwareService.openMobileDataSettings();
                              });
                            } else {
                              _showBluetoothDialog(context, state, colors);
                            }
                          }
                        : null,
                    onTap: () {
                      if (_isEditMode) {
                        setState(() => _selectedTileId = rows[r][t].id);
                      } else {
                        _handleTileAction(() {
                          state.toggleTile(rows[r][t].id);
                        });
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

  // 2-State Unified Mode View:
  // NO tab switcher is rendered here.
  // Pulling down from left side automatically scrolls directly to the Notifications container!
  // Quick Settings expansion animates in a bouncy spring manner (Curves.easeOutBack).
  // Brightness and Volume sliders are only visible when expanded.
  // Expand chip is removed in favor of downward swipe gesture.
  Widget _buildUnifiedShadeView(ShadeStateProvider state, ExpressiveThemeColors colors) {
    final font = state.selectedFont;
    final allRows = _packTilesIntoRows(state.tiles);
    final firstTwoRows = allRows.take(2).toList();
    final remainingRows = allRows.skip(2).toList();

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          if (notification.metrics.pixels <= 0) {
            final scrollDelta = notification.scrollDelta ?? 0;
            if (scrollDelta < 0 && !state.isUnifiedQsExpanded) {
              // Overscrolling downwards expands QS in real-time!
              final delta = -scrollDelta / 200.0;
              _qsBouncyController.value = (_qsBouncyController.value + delta).clamp(0.0, 1.0);
            } else if (scrollDelta > 0 && _qsBouncyController.value > 0) {
              // Scrolling upwards from top contracts QS in real-time!
              final delta = scrollDelta / 200.0;
              _qsBouncyController.value = (_qsBouncyController.value - delta).clamp(0.0, 1.0);
            }
          }
        } else if (notification is ScrollEndNotification) {
          if (!_isDraggingQs) {
            if (_qsBouncyController.value > 0.45 && !state.isUnifiedQsExpanded) {
              HapticFeedback.lightImpact();
              _qsBouncyController.animateTo(1.0, curve: Curves.easeOutBack, duration: const Duration(milliseconds: 320));
              state.setUnifiedQsExpanded(true);
            } else if (_qsBouncyController.value < 0.45 && state.isUnifiedQsExpanded) {
              HapticFeedback.lightImpact();
              _qsBouncyController.animateTo(0.0, curve: Curves.easeInOutCubic, duration: const Duration(milliseconds: 260));
              state.setUnifiedQsExpanded(false);
            }
          }
        }
        return false;
      },
      child: ListView(
        controller: _unifiedScrollController,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Quick Settings Section with real-time drag-to-expand / drag-to-contract support
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragStart: (_) {
              _isDraggingQs = true;
            },
            onVerticalDragUpdate: (details) {
              // 1:1 real-time drag expansion!
              final delta = details.delta.dy / 220.0;
              _qsBouncyController.value = (_qsBouncyController.value + delta).clamp(0.0, 1.0);
            },
            onVerticalDragEnd: (details) {
              _isDraggingQs = false;
              final velocity = details.primaryVelocity ?? 0;
              if (velocity > 180 || (_qsBouncyController.value > 0.45 && velocity > -150)) {
                // Dragged down past threshold or downward fling: snap to 1.0 with bouncy spring
                HapticFeedback.lightImpact();
                _qsBouncyController.animateTo(1.0, curve: Curves.easeOutBack, duration: const Duration(milliseconds: 320));
                state.setUnifiedQsExpanded(true);
              } else {
                // Dragged up or upward fling: snap back to 0.0
                HapticFeedback.lightImpact();
                _qsBouncyController.animateTo(0.0, curve: Curves.easeInOutCubic, duration: const Duration(milliseconds: 260));
                state.setUnifiedQsExpanded(false);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brightness & Volume Sliders (ONLY visible in expanded state with bouncy animation)
                  AnimatedBuilder(
                    animation: _bouncyCurveAnimation,
                    builder: (context, child) {
                      if (_qsBouncyController.value <= 0.001) {
                        return const SizedBox.shrink();
                      }
                      return SizeTransition(
                        sizeFactor: _bouncyCurveAnimation,
                        alignment: Alignment.topCenter,
                        child: FadeTransition(
                          opacity: _qsBouncyController,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          // Brightness Capsule Slider
                          ExpressiveSlider(
                            value: state.brightness,
                            onChanged: (val) => state.setBrightness(val),
                            leadingIcon: Icons.wb_sunny_rounded,
                            colors: colors,
                            style: state.sliderStyle,
                          ),
                          const SizedBox(height: 10),

                          // Volume Capsule Slider
                          ExpressiveSlider(
                            value: state.volume,
                            onChanged: (val) => state.setVolume(val),
                            leadingIcon: state.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                            colors: colors,
                            style: state.sliderStyle,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Dynamic Tiles Grid: First 2 Rows (Always visible)
                  _buildDynamicTilesGridCustom(state, colors, firstTwoRows),

                  // Dynamic Tiles Grid: Remaining Rows (Animated with bouncy spring expansion)
                  if (remainingRows.isNotEmpty) ...[
                    AnimatedBuilder(
                      animation: _bouncyCurveAnimation,
                      builder: (context, child) {
                        if (_qsBouncyController.value <= 0.001) {
                          return const SizedBox.shrink();
                        }
                        return SizeTransition(
                          sizeFactor: _bouncyCurveAnimation,
                          alignment: Alignment.topCenter,
                          child: FadeTransition(
                            opacity: _qsBouncyController,
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildDynamicTilesGridCustom(state, colors, remainingRows),
                      ),
                    ),
                  ],

                  // Expressive Media Card (Animated bouncy or active)
                  if (state.isPlaying) ...[
                    const SizedBox(height: 12),
                    ExpressiveMediaCard(
                      title: state.mediaTitle,
                      artist: state.mediaArtist,
                      appSource: state.mediaApp,
                      isPlaying: state.isPlaying,
                      progress: state.mediaProgress,
                      artwork: state.mediaArtwork,
                      colors: colors,
                      font: font,
                      onPlayPause: () => state.togglePlayPause(),
                      onSkipNext: () => state.skipNextMedia(),
                      onSkipPrevious: () => state.skipPreviousMedia(),
                      onProgressChanged: (val) => state.setMediaProgress(val),
                    ),
                  ] else ...[
                    AnimatedBuilder(
                      animation: _bouncyCurveAnimation,
                      builder: (context, child) {
                        if (_qsBouncyController.value <= 0.001) {
                          return const SizedBox.shrink();
                        }
                        return SizeTransition(
                          sizeFactor: _bouncyCurveAnimation,
                          alignment: Alignment.topCenter,
                          child: FadeTransition(
                            opacity: _qsBouncyController,
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ExpressiveMediaCard(
                          title: state.mediaTitle,
                          artist: state.mediaArtist,
                          appSource: state.mediaApp,
                          isPlaying: state.isPlaying,
                          progress: state.mediaProgress,
                          artwork: state.mediaArtwork,
                          colors: colors,
                          font: font,
                          onPlayPause: () => state.togglePlayPause(),
                          onSkipNext: () => state.skipNextMedia(),
                          onSkipPrevious: () => state.skipPreviousMedia(),
                          onProgressChanged: (val) => state.setMediaProgress(val),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Distinct Division: Notifications Container with Rounded Top Corners & Acrylic Blur
          _buildNotificationsContainer(state, colors, font),
          const SizedBox(height: 24),
        ],
      ),
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

    // Group notifications by appName for packed clustering
    final Map<String, List<NotificationModel>> grouped = {};
    for (final notif in state.notifications) {
      grouped.putIfAbsent(notif.appName, () => []).add(notif);
    }

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
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
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
                  for (final entry in grouped.entries) ...[
                    for (int i = 0; i < entry.value.length; i++)
                      ExpressiveNotificationCard(
                        notification: entry.value[i],
                        colors: colors,
                        font: font,
                        isFirstInGroup: i == 0,
                        isLastInGroup: i == entry.value.length - 1,
                        groupCount: entry.value.length,
                        onDismiss: () => state.dismissNotification(entry.value[i].id),
                        onActionTap: (_) {
                          HapticFeedback.lightImpact();
                        },
                      ),
                  ],
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
    final wifiTile = state.tiles.firstWhere((t) => t.id == 'wifi', orElse: () => state.tiles.first);

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

                // Connected Real Wi-Fi Card
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
                              wifiTile.title,
                              style: font.textStyleBuilder(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              wifiTile.subtitle ?? 'Wi-Fi',
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

                // Real Mobile Network Card
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
                              state.carrierName,
                              style: font.textStyleBuilder(
                                fontSize: 11.5,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.open_in_new_rounded, color: colors.textSecondary, size: 18),
                        onPressed: () {
                          SystemHardwareService.openWifiSettings();
                        },
                      ),
                    ],
                  ),
                ),
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

  void _showBluetoothDialog(
    BuildContext context,
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    final font = state.selectedFont;
    final btTile = state.tiles.firstWhere((t) => t.id == 'bluetooth', orElse: () => state.tiles.first);

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
                            btTile.isActive ? (btTile.subtitle ?? 'On') : 'Off',
                            style: font.textStyleBuilder(
                              fontSize: 12.0,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: btTile.isActive,
                      activeTrackColor: colors.activePill.withValues(alpha: 0.5),
                      thumbColor: WidgetStateProperty.all(colors.activePill),
                      onChanged: (_) {
                        state.toggleTile('bluetooth');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Real Connected/Active Device Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: btTile.isActive ? colors.activePill.withValues(alpha: 0.14) : colors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: btTile.isActive ? colors.activePill.withValues(alpha: 0.3) : colors.textSecondary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        btTile.isActive ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
                        color: btTile.isActive ? colors.activePill : colors.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              btTile.isActive ? (btTile.subtitle ?? 'Bluetooth On') : 'Bluetooth Off',
                              style: font.textStyleBuilder(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              btTile.isActive ? 'Ready for paired devices' : 'Turn on to connect devices',
                              style: font.textStyleBuilder(
                                fontSize: 12.0,
                                color: colors.textSecondary,
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
                const SizedBox(height: 18),

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
                        'Device settings',
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
}
