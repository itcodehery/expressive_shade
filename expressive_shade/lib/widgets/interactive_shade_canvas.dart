import 'dart:async';
import 'dart:ui';
import 'package:flutter/gestures.dart';
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
  final void Function(double deltaDy)? onDragShadeUpdate;
  final void Function(double velocity)? onDragShadeEnd;

  const InteractiveShadeCanvas({
    super.key,
    required this.colors,
    this.onDismissAndExecute,
    this.onDragShadeUpdate,
    this.onDragShadeEnd,
  });

  @override
  State<InteractiveShadeCanvas> createState() => _InteractiveShadeCanvasState();
}

class _InteractiveShadeCanvasState extends State<InteractiveShadeCanvas>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  final ScrollController _unifiedScrollController = ScrollController();
  final ValueNotifier<TileImpulse?> _tileImpulseNotifier =
      ValueNotifier<TileImpulse?>(null);
  late AnimationController _qsBouncyController;
  late Animation<double> _bouncyCurveAnimation;
  bool _isDraggingQs = false;
  bool _isEditMode = false;
  String? _selectedTileId;
  int _lastOpenEpoch = 0;

  /// True while the user scrolls or drags the shade; the backdrop blur is softened
  /// during that time because re-blurring every frame is the costliest paint operation.
  final ValueNotifier<bool> _reduceBlur = ValueNotifier<bool>(false);

  // Notifications Upward Drag-to-Close Tracker
  double _notifPointerStartY = 0.0;
  double _notifLastPointerY = 0.0;
  bool _isDraggingShadeUp = false;
  VelocityTracker? _notifVelocityTracker;

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
    final initialExpanded = context
        .read<ShadeStateProvider>()
        .isUnifiedQsExpanded;
    _pageController = PageController(initialPage: initialPage);
    _qsBouncyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 170),
      value: initialExpanded ? 1.0 : 0.0,
    );
    _bouncyCurveAnimation = CurvedAnimation(
      parent: _qsBouncyController,
      curve: Curves
          .easeOutCubic, // Smooth natural deceleration without initial overshoot jerk
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _tileImpulseNotifier.dispose();
    _reduceBlur.dispose();
    _qsBouncyController.dispose();
    _pageController.dispose();
    _unifiedScrollController.dispose();
    super.dispose();
  }

  /// Every time the shade is (re)opened it must start at its top: the unified
  /// list is reset to offset 0 and the split pager shows the requested panel.
  void _handleShadeOpened(int openEpoch, bool isSplit) {
    if (openEpoch == _lastOpenEpoch) return;
    _lastOpenEpoch = openEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_unifiedScrollController.hasClients) {
        _unifiedScrollController.jumpTo(0.0);
      }
      if (_pageController.hasClients) {
        _pageController.jumpToPage(
          context.read<ShadeStateProvider>().splitTabIndex,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Root only rebuilds for the few fields it actually needs; each section
    // below subscribes to the provider on its own via Consumer.
    final isExpanded = context.select<ShadeStateProvider, bool>(
      (s) => s.isUnifiedQsExpanded,
    );
    final isSplit = context.select<ShadeStateProvider, bool>(
      (s) => s.shadeMode == ShadeMode.split,
    );
    final openEpoch = context.select<ShadeStateProvider, int>(
      (s) => s.shadeOpenEpoch,
    );
    final colors = widget.colors;
    _handleShadeOpened(openEpoch, isSplit);

    if (!_isDraggingQs) {
      if (isExpanded &&
          _qsBouncyController.status != AnimationStatus.forward &&
          _qsBouncyController.value < 1.0) {
        _qsBouncyController.animateTo(
          1.0,
          curve: Curves.easeOutCubic,
          duration: const Duration(milliseconds: 320),
        );
      } else if (!isExpanded &&
          _qsBouncyController.status != AnimationStatus.reverse &&
          _qsBouncyController.value > 0.0) {
        _qsBouncyController.animateTo(
          0.0,
          curve: Curves.easeInCubic,
          duration: const Duration(milliseconds: 260),
        );
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
            Consumer<ShadeStateProvider>(
              builder: (context, state, _) => _buildStatusBar(state, colors),
            ),

            // Secondary Quick Actions Header or Edit Tiles Header
            Consumer<ShadeStateProvider>(
              builder: (context, state, _) => _isEditMode
                  ? _buildEditHeaderControls(state, colors)
                  : _buildHeaderControls(state, colors),
            ),

            const SizedBox(height: 6),

            // Main Canvas: Dual Mode Engine (Split vs Unified) or Edit Tiles View
            Expanded(
              child: Consumer<ShadeStateProvider>(
                builder: (context, state, _) => _isEditMode
                    ? _buildEditTilesView(state, colors)
                    : (state.shadeMode == ShadeMode.split
                          ? _buildSplitModeView(state, colors)
                          : _buildUnifiedShadeView(state, colors)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    final font = state.selectedFont;
    final topPadding = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        topPadding > 0 ? topPadding + 6 : 14,
        24,
        8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Live Clock & Date
          _LiveClock(font: font, colors: colors),

          // Status Icons & Live Battery Percentage
          Row(
            children: [
              Icon(Icons.wifi_rounded, size: 16, color: colors.textPrimary),
              const SizedBox(width: 6),
              Icon(
                Icons.signal_cellular_4_bar_rounded,
                size: 16,
                color: colors.textPrimary,
              ),
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
                      state.isCharging
                          ? Icons.battery_charging_full_rounded
                          : Icons.battery_full_rounded,
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

  Widget _buildHeaderControls(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
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
                Icon(
                  Icons.sim_card_rounded,
                  size: 14,
                  color: colors.activePill,
                ),
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
              if (state.shadeMode == ShadeMode.split &&
                  state.splitTabIndex == 0) {
                state.setSplitTabIndex(1);
                _pageController.jumpToPage(1);
              }
            });
          }),
          const SizedBox(width: 8),

          // Settings Gear
          _buildCircleHeaderBtn(Icons.settings_outlined, colors, () {
            HapticFeedback.lightImpact();
            _handleTileAction(() {
              SystemHardwareService.openSettings();
            });
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

  Widget _buildEditHeaderControls(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    final font = state.selectedFont;
    final hasSelection =
        _selectedTileId != null &&
        state.tiles.any((t) => t.id == _selectedTileId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Back Button
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colors.textPrimary,
              size: 24,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isEditMode = false;
                _selectedTileId = null;
              });
            },
          ),
          const Spacer(),

          // Reset / Undo circular button
          _buildCircleHeaderBtn(Icons.replay_rounded, colors, () {
            HapticFeedback.mediumImpact();
            state.resetTiles();
            setState(() {
              _selectedTileId = state.tiles.firstOrNull?.id;
            });
          }),
          const SizedBox(width: 8),

          // Remove Button matching refs/07_edit_tiles_resize_ref.png
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: hasSelection
                ? () {
                    HapticFeedback.mediumImpact();
                    state.removeTile(_selectedTileId!);
                    setState(() {
                      _selectedTileId = state.tiles.firstOrNull?.id;
                    });
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: hasSelection
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Remove',
                style: font.textStyleBuilder(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  color: hasSelection ? Colors.black : Colors.white38,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditTilesView(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    final font = state.selectedFont;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        // Title & Subtitle matching refs/07_edit_tiles_resize_ref.png
        Text(
          'Edit tiles',
          style: font.textStyleBuilder(
            fontSize: 26.0,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select tiles to rearrange and resize',
          style: font.textStyleBuilder(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // Main Active Tiles Container with distinct border (matching refs/07_edit_tiles_resize_ref.png)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.70),
              width: 1.5,
            ),
          ),
          child: _buildDynamicTilesGrid(state, colors),
        ),
        const SizedBox(height: 28),

        // Categorized Available Tiles Sections
        for (final category in TileCategory.values) ...[
          _buildCategorySection(state, colors, category, font),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildCategorySection(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
    TileCategory category,
    FontConfig font,
  ) {
    final categoryTiles = QsTileModel.allAvailableTiles
        .where((t) => t.category == category)
        .toList();
    if (categoryTiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header (Icon + Label)
        Row(
          children: [
            Icon(category.icon, size: 20, color: colors.textPrimary),
            const SizedBox(width: 8),
            Text(
              category.label,
              style: font.textStyleBuilder(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 4-Column Grid of Tiles under this category
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 14,
            childAspectRatio: 0.76,
          ),
          itemCount: categoryTiles.length,
          itemBuilder: (context, index) {
            final catTile = categoryTiles[index];
            final isAlreadyActive = state.tiles.any((t) => t.id == catTile.id);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (!isAlreadyActive) {
                  HapticFeedback.lightImpact();
                  state.addTile(catTile);
                  setState(() => _selectedTileId = catTile.id);
                } else {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTileId = catTile.id);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Squircle Icon Container with '+' badge if not added
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: isAlreadyActive
                              ? colors.surface.withValues(alpha: 0.35)
                              : colors.surface,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Center(
                          child: Icon(
                            catTile.icon,
                            size: 25,
                            color: isAlreadyActive
                                ? colors.textSecondary.withValues(alpha: 0.35)
                                : colors.textPrimary,
                          ),
                        ),
                      ),
                      // White Circle '+' badge at top-right if tile can be added
                      if (!isAlreadyActive)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add_rounded,
                                size: 16,
                                color: Color(0xDD000000),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Tile Label
                  Text(
                    catTile.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: font.textStyleBuilder(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w500,
                      color: isAlreadyActive
                          ? colors.textSecondary.withValues(alpha: 0.40)
                          : colors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCircleHeaderBtn(
    IconData icon,
    ExpressiveThemeColors colors,
    VoidCallback onTap,
  ) {
    return Material(
      color: colors.surface,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(child: Icon(icon, size: 20, color: colors.textPrimary)),
        ),
      ),
    );
  }

  Widget _buildSplitModeView(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    return Column(
      children: [
        const SizedBox(height: 4),
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

  Widget _buildQuickSettingsPanel(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    return ListView(
      key: ValueKey('qs_panel_${state.shadeOpenEpoch}'),
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
          leadingIcon: state.volume == 0
              ? Icons.volume_off_rounded
              : Icons.volume_up_rounded,
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

  Widget _buildDynamicTilesGrid(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    return _buildDynamicTilesGridCustom(
      state,
      colors,
      _packTilesIntoRows(state.tiles),
    );
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
                  child: _buildTileItemWithReorder(
                    tile: rows[r][t],
                    state: state,
                    colors: colors,
                    font: font,
                    row: r,
                    col: t,
                  ),
                ),
              ],
              if (_rowSpan(rows[r]) < 4) Spacer(flex: 4 - _rowSpan(rows[r])),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTileItemWithReorder({
    required QsTileModel tile,
    required ShadeStateProvider state,
    required ExpressiveThemeColors colors,
    required FontConfig font,
    required int row,
    required int col,
  }) {
    final pillWidget = ExpressivePill(
      tile: tile,
      colors: colors,
      font: font,
      row: row,
      col: col,
      impulseNotifier: _tileImpulseNotifier,
      isEditing: _isEditMode,
      isSelected: _isEditMode && _selectedTileId == tile.id,
      onResizeTap: () => state.toggleTileSize(tile.id),
      onInnerButtonTap:
          (tile.id == 'wifi' ||
              tile.id == 'bluetooth' ||
              tile.id == 'mobile_data')
          ? () {
              _handleTileAction(() {
                state.toggleTile(tile.id);
              });
            }
          : null,
      onOuterPillTap:
          (tile.id == 'wifi' ||
              tile.id == 'bluetooth' ||
              tile.id == 'mobile_data')
          ? () {
              if (tile.id == 'wifi') {
                if (state.networkTileStyle == NetworkTileStyle.unified) {
                  _showInternetDialog(context, state, colors);
                } else {
                  _handleTileAction(() {
                    SystemHardwareService.openWifiSettings();
                  });
                }
              } else if (tile.id == 'mobile_data') {
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
          setState(() => _selectedTileId = tile.id);
        } else {
          _handleTileAction(() {
            state.toggleTile(tile.id);
          });
        }
      },
      onLongPress: () {
        HapticFeedback.heavyImpact();
        setState(() {
          _isEditMode = true;
          _selectedTileId = tile.id;
        });
      },
    );

    if (!_isEditMode) {
      return pillWidget;
    }

    // In Edit Mode: allow dragging any pill to rearrange position
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != tile.id,
      onAcceptWithDetails: (details) {
        HapticFeedback.mediumImpact();
        state.moveTile(details.data, tile.id);
        setState(() {
          _selectedTileId = details.data;
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tile.isWide ? 34 : 24),
            border: isHovered
                ? Border.all(color: colors.activePill, width: 2.5)
                : null,
          ),
          child: LongPressDraggable<String>(
            data: tile.id,
            delay: const Duration(milliseconds: 100),
            feedback: Material(
              color: Colors.transparent,
              elevation: 8,
              borderRadius: BorderRadius.circular(tile.isWide ? 34 : 24),
              child: SizedBox(
                width: tile.isWide ? 200 : 92,
                height: 68,
                child: ExpressivePill(
                  tile: tile,
                  colors: colors,
                  font: font,
                  isEditing: true,
                  isSelected: true,
                  onTap: () {},
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.25, child: pillWidget),
            child: pillWidget,
          ),
        );
      },
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

  Widget _wrapWithNotificationsDragToClose(Widget child) {
    if (widget.onDragShadeUpdate == null) {
      return child;
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _notifVelocityTracker = VelocityTracker.withKind(
          PointerDeviceKind.touch,
        );
        _notifVelocityTracker?.addPosition(event.timeStamp, event.position);
        _notifPointerStartY = event.position.dy;
        _notifLastPointerY = event.position.dy;
        _isDraggingShadeUp = false;
      },
      onPointerMove: (event) {
        _notifVelocityTracker?.addPosition(event.timeStamp, event.position);
        final currentY = event.position.dy;
        final deltaY = currentY - _notifLastPointerY;
        _notifLastPointerY = currentY;
        final totalDelta = currentY - _notifPointerStartY;

        final isAtScrollTop =
            !_unifiedScrollController.hasClients ||
            _unifiedScrollController.offset <= 2.0;

        // Trigger upward drag-to-close only when list is at the top or already dragging upwards
        if ((isAtScrollTop && totalDelta < -20.0) || _isDraggingShadeUp) {
          _isDraggingShadeUp = true;
          _reduceBlur.value = true;
          widget.onDragShadeUpdate?.call(deltaY);
        }
      },
      onPointerUp: (event) {
        _notifVelocityTracker?.addPosition(event.timeStamp, event.position);
        if (_isDraggingShadeUp) {
          _isDraggingShadeUp = false;
          _reduceBlur.value = false;
          final velocity =
              _notifVelocityTracker?.getVelocity().pixelsPerSecond.dy ?? 0.0;
          widget.onDragShadeEnd?.call(velocity);
        }
        _notifVelocityTracker = null;
      },
      onPointerCancel: (_) {
        if (_isDraggingShadeUp) {
          _isDraggingShadeUp = false;
          _reduceBlur.value = false;
          widget.onDragShadeEnd?.call(0.0);
        }
        _notifVelocityTracker = null;
      },
      child: child,
    );
  }

  Widget _buildNotificationsPanel(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    final font = state.selectedFont;

    return ListView(
      key: ValueKey('notif_panel_${state.shadeOpenEpoch}'),
      padding: EdgeInsets.zero,
      children: [
        _wrapWithNotificationsDragToClose(
          _buildNotificationsContainer(state, colors, font),
        ),
      ],
    );
  }

  // 2-State Unified Mode View:
  // NO tab switcher is rendered here.
  // Pulling down from left side automatically scrolls directly to the Notifications container!
  // Quick Settings expansion animates in a bouncy spring manner (Curves.easeOutBack).
  // Brightness and Volume sliders are only visible when expanded.
  // Expand chip is removed in favor of downward swipe gesture.
  Widget _buildUnifiedShadeView(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    final font = state.selectedFont;
    final allRows = _packTilesIntoRows(state.tiles);
    final firstTwoRows = allRows.take(2).toList();
    final remainingRows = allRows.skip(2).toList();

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          _reduceBlur.value = true;
        } else if (notification is ScrollUpdateNotification) {
          if (notification.metrics.pixels <= 0) {
            final scrollDelta = notification.scrollDelta ?? 0;
            if (scrollDelta < 0 && !state.isUnifiedQsExpanded) {
              // Overscrolling downwards expands QS smoothly in real-time
              final delta = -scrollDelta / 280.0;
              _qsBouncyController.value = (_qsBouncyController.value + delta)
                  .clamp(0.0, 1.0);
            } else if (scrollDelta > 0 && _qsBouncyController.value > 0) {
              // Scrolling upwards from top contracts QS smoothly in real-time
              final delta = scrollDelta / 280.0;
              _qsBouncyController.value = (_qsBouncyController.value - delta)
                  .clamp(0.0, 1.0);
            }
          }
        } else if (notification is ScrollEndNotification) {
          _reduceBlur.value = false;
          if (!_isDraggingQs) {
            if (_qsBouncyController.value > 0.40 &&
                !state.isUnifiedQsExpanded) {
              HapticFeedback.lightImpact();
              _qsBouncyController.animateTo(
                1.0,
                curve: Curves.easeOutCubic,
                duration: const Duration(milliseconds: 170),
              );
              state.setUnifiedQsExpanded(true);
            } else if (_qsBouncyController.value < 0.40 &&
                state.isUnifiedQsExpanded) {
              HapticFeedback.lightImpact();
              _qsBouncyController.animateTo(
                0.0,
                curve: Curves.easeInCubic,
                duration: const Duration(milliseconds: 140),
              );
              state.setUnifiedQsExpanded(false);
            }
          }
        }
        return false;
      },
      child: ListView(
        controller: _unifiedScrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 0),
        children: [
          // Quick Settings Section with real-time drag-to-expand / drag-to-contract support
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragStart: (_) {
              _isDraggingQs = true;
            },
            onVerticalDragUpdate: (details) {
              // 1:1 real-time drag expansion
              final delta = details.delta.dy / 280.0;
              _qsBouncyController.value = (_qsBouncyController.value + delta)
                  .clamp(0.0, 1.0);
            },
            onVerticalDragEnd: (details) {
              _isDraggingQs = false;
              final velocity = details.primaryVelocity ?? 0;
              if (velocity > 160 ||
                  (_qsBouncyController.value > 0.40 && velocity > -120)) {
                // Dragged down past threshold or downward fling: snap to expanded with smooth cubic deceleration
                HapticFeedback.lightImpact();
                _qsBouncyController.animateTo(
                  1.0,
                  curve: Curves.easeOutCubic,
                  duration: const Duration(milliseconds: 170),
                );
                state.setUnifiedQsExpanded(true);
              } else {
                // Dragged up or upward fling: snap back to collapsed
                HapticFeedback.lightImpact();
                _qsBouncyController.animateTo(
                  0.0,
                  curve: Curves.easeInCubic,
                  duration: const Duration(milliseconds: 140),
                );
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
                            leadingIcon: state.volume == 0
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
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
                        child: _buildDynamicTilesGridCustom(
                          state,
                          colors,
                          remainingRows,
                        ),
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
                        child: RepaintBoundary(
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
                            onProgressChanged: (val) =>
                                state.setMediaProgress(val),
                          ),
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
          _wrapWithNotificationsDragToClose(
            RepaintBoundary(
              child: _buildNotificationsContainer(state, colors, font),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsContainer(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
    FontConfig font,
  ) {
    final blurSigma = state.customTheme.blurIntensity.clamp(4.0, 18.0);
    final cardOpacity = state.customTheme.cardOpacity.clamp(0.1, 1.0);
    // Container itself is semi-transparent allowing the acrylic blur to shine through
    final containerAlpha = (cardOpacity * 0.38).clamp(0.15, 0.55);
    final containerBg = colors.surface.withValues(alpha: containerAlpha);

    // Group notifications by appName for packed clustering
    final Map<String, List<NotificationModel>> grouped = {};
    for (final notif in state.notifications) {
      grouped.putIfAbsent(notif.appName, () => []).add(notif);
    }

    final screenHeight = MediaQuery.sizeOf(context).height;

    // The blur gets its own repaint layer and is softened while scrolling/dragging.
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        child: ValueListenableBuilder<bool>(
          valueListenable: _reduceBlur,
          builder: (context, reduce, child) {
            final sigma = reduce ? blurSigma * 0.4 : blurSigma;
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: child,
            );
          },
          child: Container(
            constraints: BoxConstraints(minHeight: screenHeight + 200),
            decoration: BoxDecoration(
              color: containerBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(36),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.notifications.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
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
                        onDismiss: () =>
                            state.dismissNotification(entry.value[i].id),
                        onActionTap: (action) => state
                            .performNotificationAction(entry.value[i], action),
                        onReply: (action, text) =>
                            state.performNotificationAction(
                              entry.value[i],
                              action,
                              replyText: text,
                            ),
                        onSnooze: entry.value[i].isOngoing
                            ? null
                            : () => state.snoozeNotification(entry.value[i].id),
                        onTap: () {
                          final n = entry.value[i];
                          state.openNotification(n).then((opened) {
                            if (opened && mounted) {
                              widget.onDismissAndExecute?.call(() {});
                            }
                          });
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
      padding: const EdgeInsets.only(top: 8, bottom: 4),
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

  Widget _buildCircleActionBtn(
    IconData icon,
    ExpressiveThemeColors colors,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
        ),
        child: Center(child: Icon(icon, size: 20, color: colors.textPrimary)),
      ),
    );
  }

  void _showInternetDialog(
    BuildContext context,
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    final font = state.selectedFont;
    final wifiTile = state.tiles.firstWhere(
      (t) => t.id == 'wifi',
      orElse: () => state.tiles.first,
    );

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        return Dialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
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
                      child: Icon(
                        Icons.wifi_rounded,
                        color: colors.activePill,
                        size: 22,
                      ),
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
                      icon: Icon(
                        Icons.close_rounded,
                        color: colors.textSecondary,
                        size: 20,
                      ),
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
                    border: Border.all(
                      color: colors.activePill.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.wifi_rounded,
                        color: colors.activePill,
                        size: 24,
                      ),
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
                        icon: Icon(
                          Icons.settings_outlined,
                          color: colors.activePill,
                          size: 20,
                        ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.swap_vert_rounded,
                        color: colors.textPrimary,
                        size: 22,
                      ),
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
                        icon: Icon(
                          Icons.open_in_new_rounded,
                          color: colors.textSecondary,
                          size: 18,
                        ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 9,
                        ),
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
    final btTile = state.tiles.firstWhere(
      (t) => t.id == 'bluetooth',
      orElse: () => state.tiles.first,
    );

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        return Dialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
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
                      child: Icon(
                        Icons.bluetooth_rounded,
                        color: colors.activePill,
                        size: 22,
                      ),
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
                      activeTrackColor: colors.activePill.withValues(
                        alpha: 0.5,
                      ),
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
                    color: btTile.isActive
                        ? colors.activePill.withValues(alpha: 0.14)
                        : colors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: btTile.isActive
                          ? colors.activePill.withValues(alpha: 0.3)
                          : colors.textSecondary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        btTile.isActive
                            ? Icons.bluetooth_connected_rounded
                            : Icons.bluetooth_disabled_rounded,
                        color: btTile.isActive
                            ? colors.activePill
                            : colors.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              btTile.isActive
                                  ? (btTile.subtitle ?? 'Bluetooth On')
                                  : 'Bluetooth Off',
                              style: font.textStyleBuilder(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              btTile.isActive
                                  ? 'Ready for paired devices'
                                  : 'Turn on to connect devices',
                              style: font.textStyleBuilder(
                                fontSize: 12.0,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.settings_outlined,
                          color: colors.activePill,
                          size: 20,
                        ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 9,
                        ),
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

/// Self-contained clock so the per-minute tick only rebuilds this widget
/// instead of the whole shade.
class _LiveClock extends StatefulWidget {
  final FontConfig font;
  final ExpressiveThemeColors colors;

  const _LiveClock({required this.font, required this.colors});

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _scheduleNextTick();
  }

  /// Fires exactly on the next minute boundary rather than polling every second.
  void _scheduleNextTick() {
    final now = DateTime.now();
    final untilNextMinute = Duration(
      seconds: 60 - now.second,
      milliseconds: -now.millisecond,
    );
    _timer = Timer(untilNextMinute, () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _scheduleNextTick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${_weekdays[_now.weekday - 1]}, ${_months[_now.month - 1]} ${_now.day}';
    return Row(
      children: [
        Text(
          timeStr,
          style: widget.font.textStyleBuilder(
            fontSize: 16.0,
            fontWeight: FontWeight.w700,
            color: widget.colors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          dateStr,
          style: widget.font.textStyleBuilder(
            fontSize: 13.0,
            fontWeight: FontWeight.w500,
            color: widget.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
