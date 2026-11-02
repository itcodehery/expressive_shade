import 'dart:async';
import 'dart:math' as math;
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
import 'notification_channel_settings_card.dart';
import 'springy_dismissible_notification.dart';

enum _DragAction { none, expandingQs, collapsingQs, dismissingShade, ignored }

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
  bool _isEditMode = false;
  bool _isSmartUnorganized = false;
  String? _selectedTileId;
  String? _smartSettingsNotifId;
  int _lastOpenEpoch = 0;

  /// True while the user scrolls or drags the shade; the backdrop blur is softened
  /// during that time because re-blurring every frame is the costliest paint operation.
  final ValueNotifier<bool> _reduceBlur = ValueNotifier<bool>(false);

  // Notifications Upward Drag-to-Close Tracker
  double _notifPointerStartX = 0.0;
  double _notifPointerStartY = 0.0;
  double _notifLastPointerY = 0.0;
  bool _dragStartExpanded = false;
  _DragAction _activeDragAction = _DragAction.none;
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
      context.read<ShadeStateProvider>().setUnifiedQsExpanded(false);
      _qsBouncyController.value = 0.0;
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

    if (_activeDragAction == _DragAction.none) {
      if (isExpanded &&
          _qsBouncyController.status != AnimationStatus.forward &&
          _qsBouncyController.value < 1.0) {
        _qsBouncyController.animateTo(
          1.0,
          curve: Curves.easeOutCubic,
          duration: const Duration(milliseconds: 260),
        );
      } else if (!isExpanded &&
          _qsBouncyController.status != AnimationStatus.reverse &&
          _qsBouncyController.value > 0.0) {
        _qsBouncyController.animateTo(
          0.0,
          curve: Curves.easeInCubic,
          duration: const Duration(milliseconds: 220),
        );
      }
    }

    final mainContent = Consumer<ShadeStateProvider>(
      builder: (context, state, _) {
        final showStandardHeader = state.shadeMode != ShadeMode.smart;

        return Container(
          color: state.shadeMode == ShadeMode.smart && !_isEditMode
              ? Colors.transparent
              : colors.background,
          child: SafeArea(
            top: false, // Render behind and over the status bar completely
            bottom: true,
            child: Column(
              children: [
                if (showStandardHeader) ...[
                  // Status Bar & System Header (renders directly over physical status bar)
                  _buildStatusBar(state, colors),

                  // Secondary Quick Actions Header or Edit Tiles Header
                  if (_isEditMode) ...[
                    _buildEditHeaderControls(state, colors),
                    const SizedBox(height: 6),
                  ] else if (state.shadeMode == ShadeMode.unified) ...[
                    ClipRect(
                      child: SizeTransition(
                        sizeFactor: _bouncyCurveAnimation,
                        alignment: Alignment.topCenter,
                        child: FadeTransition(
                          opacity: _bouncyCurveAnimation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildHeaderControls(state, colors),
                              const SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    _buildHeaderControls(state, colors),
                    const SizedBox(height: 6),
                  ],
                ],

                // Main Canvas: Dual Mode Engine (Split vs Smart vs Unified) or Edit Tiles View
                Expanded(
                  child: _isEditMode
                      ? (state.shadeMode == ShadeMode.smart
                          ? _buildSmartEditTilesView(state, colors)
                          : _buildEditTilesView(state, colors))
                      : switch (state.shadeMode) {
                          ShadeMode.split => _buildSplitModeView(state, colors),
                          ShadeMode.smart => _buildSmartView(state, colors),
                          ShadeMode.unified =>
                            _buildUnifiedShadeView(state, colors),
                        },
                ),
              ],
            ),
          ),
        );
      },
    );

    return _wrapWithNotificationsDragToClose(mainContent);
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
          style: state.mediaPlayerStyle,
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
    return _buildPaginatedTilesGrid(
      state,
      colors,
      _packTilesIntoRows(state.tiles),
    );
  }

  Widget _buildPaginatedTilesGrid(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
    List<List<QsTileModel>> rows, {
    int maxRowsPerPage = 5,
    double rowHeight = 68.0,
    double rowSpacing = 12.0,
  }) {
    if (rows.length <= maxRowsPerPage) {
      return _buildTilesGridPage(state, colors, rows, 0);
    }

    // Chunk rows into pages of up to maxRowsPerPage rows each
    final List<List<List<QsTileModel>>> pages = [];
    for (int i = 0; i < rows.length; i += maxRowsPerPage) {
      final end = (i + maxRowsPerPage < rows.length)
          ? i + maxRowsPerPage
          : rows.length;
      pages.add(rows.sublist(i, end));
    }

    final double fixedHeight =
        (maxRowsPerPage * rowHeight) + ((maxRowsPerPage - 1) * rowSpacing);

    return _PaginatedTilesContainer(
      colors: colors,
      pages: pages,
      fixedHeight: fixedHeight,
      builder: (context, pageIndex) {
        return _buildTilesGridPage(
          state,
          colors,
          pages[pageIndex],
          pageIndex * maxRowsPerPage,
        );
      },
    );
  }

  Widget _buildUnifiedPaginatedTilesGrid(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
    List<List<QsTileModel>> allRows, {
    int maxRowsPerPage = 5,
  }) {
    if (allRows.isEmpty) return const SizedBox.shrink();

    // Chunk all rows into unified pages of up to 5 rows each
    final List<List<List<QsTileModel>>> pages = [];
    for (int i = 0; i < allRows.length; i += maxRowsPerPage) {
      final end = (i + maxRowsPerPage < allRows.length)
          ? i + maxRowsPerPage
          : allRows.length;
      pages.add(allRows.sublist(i, end));
    }

    return _UnifiedPaginatedTilesContainer(
      colors: colors,
      pages: pages,
      bouncyAnimation: _bouncyCurveAnimation,
      builder: (context, pageIndex) {
        final pageRows = pages[pageIndex];
        final topTwo = pageRows.take(2).toList();
        final rest = pageRows.skip(2).toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Always visible top 2 rows of this page
            _buildTilesGridPage(
              state,
              colors,
              topTwo,
              pageIndex * maxRowsPerPage,
            ),

            // Expandable remaining rows of this page
            if (rest.isNotEmpty) ...[
              ClipRect(
                child: SizeTransition(
                  sizeFactor: _bouncyCurveAnimation,
                  alignment: Alignment.topCenter,
                  child: FadeTransition(
                    opacity: _bouncyCurveAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        _buildTilesGridPage(
                          state,
                          colors,
                          rest,
                          pageIndex * maxRowsPerPage + 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTilesGridPage(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
    List<List<QsTileModel>> rows,
    int baseRowIndex,
  ) {
    final font = state.selectedFont;

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
                  child: _buildTileItemWithReorder(
                    tile: rows[r][t],
                    state: state,
                    colors: colors,
                    font: font,
                    row: baseRowIndex + r,
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
              state.toggleTile(tile.id);
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
          state.toggleTile(tile.id);
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
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _notifVelocityTracker = VelocityTracker.withKind(
          PointerDeviceKind.touch,
        );
        _notifVelocityTracker?.addPosition(event.timeStamp, event.position);
        _notifPointerStartX = event.position.dx;
        _notifPointerStartY = event.position.dy;
        _notifLastPointerY = event.position.dy;
        _activeDragAction = _DragAction.none;
        final state = context.read<ShadeStateProvider>();
        _dragStartExpanded =
            state.isUnifiedQsExpanded || _qsBouncyController.value > 0.5;
      },
      onPointerMove: (event) {
        _notifVelocityTracker?.addPosition(event.timeStamp, event.position);
        final currentY = event.position.dy;
        final currentX = event.position.dx;
        final deltaY = currentY - _notifLastPointerY;
        _notifLastPointerY = currentY;
        final totalDeltaX = currentX - _notifPointerStartX;
        final totalDeltaY = currentY - _notifPointerStartY;

        // In edit mode or if gesture already determined to be horizontal, skip
        if (_isEditMode || _activeDragAction == _DragAction.ignored) return;

        final state = context.read<ShadeStateProvider>();
        final isUnifiedOrMatrix =
            state.shadeMode == ShadeMode.unified ||
            state.shadeMode == ShadeMode.smart;

        // Check if user has scrolled down into the notifications
        final isScrolledDown = _unifiedScrollController.hasClients &&
            _unifiedScrollController.offset > 8.0;

        // Lock in the active drag action once touch slop threshold is passed
        if (_activeDragAction == _DragAction.none) {
          // If movement is predominantly horizontal (e.g. dismissing a notification or paging tiles), ignore
          if (totalDeltaX.abs() > 10.0 && totalDeltaX.abs() > totalDeltaY.abs()) {
            _activeDragAction = _DragAction.ignored;
            return;
          }

          // Only trigger vertical drag actions if vertical movement dominates horizontal movement
          if (totalDeltaY.abs() > 14.0 && totalDeltaY.abs() > totalDeltaX.abs() * 1.3) {
            if (isUnifiedOrMatrix) {
              if (_dragStartExpanded) {
                // State 2: Expanded Quick Settings
                // Swiping up anywhere from expanded QS collapses back to normal shade (Rule 3)
                if (totalDeltaY < -14.0 && !isScrolledDown) {
                  _activeDragAction = _DragAction.collapsingQs;
                }
              } else {
                // State 1: Normal Shade (2 rows of QS + notifications)
                // Swiping down anywhere from normal shade expands the shade (Rule 2)
                if (totalDeltaY > 14.0 && !isScrolledDown) {
                  _activeDragAction = _DragAction.expandingQs;
                }
                // Swiping up anywhere from normal shade collapses the whole shade (Rule 4)
                else if (totalDeltaY < -16.0 && !isScrolledDown) {
                  _activeDragAction = _DragAction.dismissingShade;
                }
              }
            } else {
              // Split mode: upward swipe when at top dismisses the shade
              if (totalDeltaY < -18.0 && !isScrolledDown) {
                _activeDragAction = _DragAction.dismissingShade;
              }
            }
          }
        }

        // Lock scroll view during active gesture drag so content doesn't bounce/jitter
        if (_activeDragAction != _DragAction.none &&
            _activeDragAction != _DragAction.ignored) {
          if (_unifiedScrollController.hasClients &&
              _unifiedScrollController.offset != 0.0) {
            _unifiedScrollController.jumpTo(0.0);
          }
        }

        // Execute continuous real-time movement for the active action
        if (_activeDragAction == _DragAction.expandingQs ||
            _activeDragAction == _DragAction.collapsingQs) {
          final progressDelta = deltaY / 220.0;
          _qsBouncyController.value =
              (_qsBouncyController.value + progressDelta).clamp(0.0, 1.0);
        } else if (_activeDragAction == _DragAction.dismissingShade) {
          _reduceBlur.value = true;
          widget.onDragShadeUpdate?.call(deltaY);
        }
      },
      onPointerUp: (event) {
        _notifVelocityTracker?.addPosition(event.timeStamp, event.position);
        final velocity =
            _notifVelocityTracker?.getVelocity().pixelsPerSecond.dy ?? 0.0;
        final state = context.read<ShadeStateProvider>();

        if (_activeDragAction == _DragAction.expandingQs) {
          // Rule 2: Swiping down from normal shade expands the shade
          if (velocity > 120 || _qsBouncyController.value > 0.30) {
            HapticFeedback.lightImpact();
            _qsBouncyController.animateTo(
              1.0,
              curve: Curves.easeOutCubic,
              duration: const Duration(milliseconds: 220),
            );
            state.setUnifiedQsExpanded(true);
          } else {
            HapticFeedback.lightImpact();
            _qsBouncyController.animateTo(
              0.0,
              curve: Curves.easeInCubic,
              duration: const Duration(milliseconds: 180),
            );
            state.setUnifiedQsExpanded(false);
          }
        } else if (_activeDragAction == _DragAction.collapsingQs) {
          // Rule 3: Swiping up anywhere from expanded QS collapses back to normal shade
          if (velocity < -120 || _qsBouncyController.value < 0.70) {
            HapticFeedback.lightImpact();
            _qsBouncyController.animateTo(
              0.0,
              curve: Curves.easeInCubic,
              duration: const Duration(milliseconds: 200),
            );
            state.setUnifiedQsExpanded(false);
          } else {
            HapticFeedback.lightImpact();
            _qsBouncyController.animateTo(
              1.0,
              curve: Curves.easeOutCubic,
              duration: const Duration(milliseconds: 200),
            );
            state.setUnifiedQsExpanded(true);
          }
        } else if (_activeDragAction == _DragAction.dismissingShade) {
          // Rule 4: Swiping up from normal shade collapses whole shade
          _reduceBlur.value = false;
          widget.onDragShadeEnd?.call(velocity);
        }

        _activeDragAction = _DragAction.none;
        _notifVelocityTracker = null;
      },
      onPointerCancel: (_) {
        if (_activeDragAction == _DragAction.dismissingShade) {
          _reduceBlur.value = false;
          widget.onDragShadeEnd?.call(0.0);
        } else if (_activeDragAction == _DragAction.expandingQs) {
          final state = context.read<ShadeStateProvider>();
          if (_qsBouncyController.value > 0.30) {
            _qsBouncyController.animateTo(1.0, curve: Curves.easeOutCubic);
            state.setUnifiedQsExpanded(true);
          } else {
            _qsBouncyController.animateTo(0.0, curve: Curves.easeInCubic);
            state.setUnifiedQsExpanded(false);
          }
        } else if (_activeDragAction == _DragAction.collapsingQs) {
          final state = context.read<ShadeStateProvider>();
          if (_qsBouncyController.value < 0.70) {
            _qsBouncyController.animateTo(0.0, curve: Curves.easeInCubic);
            state.setUnifiedQsExpanded(false);
          } else {
            _qsBouncyController.animateTo(1.0, curve: Curves.easeOutCubic);
            state.setUnifiedQsExpanded(true);
          }
        }
        _activeDragAction = _DragAction.none;
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
      children: [_buildNotificationsContainer(state, colors, font)],
    );
  }

  // 2-State Unified Mode View:
  // NO tab switcher is rendered here.
  // Pulling down from left side automatically scrolls directly to the Notifications container!
  // Quick Settings expansion animates in a bouncy spring manner (Curves.easeOutBack).
  // Brightness and Volume sliders are only visible when expanded.
  // Expand chip is removed in favor of downward swipe gesture.

  // ===========================================================================
  // 3. COMPACT MATRIX SHADE MODE (3-Column Matrix, Capsule Slider, Categorized Alerts)
  // ===========================================================================
  Widget _buildSmartView(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    final font = state.selectedFont;
    final blurSigma = state.customTheme.blurIntensity.clamp(4.0, 24.0);
    final cardOpacity = state.customTheme.cardOpacity.clamp(0.1, 1.0);
    final bgAlpha = (cardOpacity * 0.45).clamp(0.15, 0.65);

    final rows3 = _packTilesInto3ColRows(state.tiles);
    final topTwoRows = rows3.take(2).toList();
    final remainingRows = rows3.skip(2).toList();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: colors.background.withValues(alpha: bgAlpha),
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.3),
              radius: 1.3,
              colors: [
                colors.activePill.withValues(alpha: 0.15),
                colors.background.withValues(alpha: bgAlpha * 0.7),
                colors.background.withValues(alpha: bgAlpha),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: ListView(
            controller: _unifiedScrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
                // Top Header: Chips for Time/Date and Battery
                _buildSmartHeader(state, colors, font),
                const SizedBox(height: 12),

                // Quick Settings Matrix Section:
                // - Brightness slider ONLY appears when expanded (animates above the tiles)
                // - First 2 rows (6 tiles) always visible
                // - Remaining rows smoothly slide down and fade in below the top 2 rows
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brightness Slider: ONLY appears when Quick Settings is expanded
                    ClipRect(
                      child: SizeTransition(
                        sizeFactor: _bouncyCurveAnimation,
                        alignment: Alignment.topCenter,
                        child: FadeTransition(
                          opacity: _bouncyCurveAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSmartBrightnessSlider(state, colors),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Top 2 rows (always visible)
                    _buildSmartTilesRowsPage(topTwoRows, state, colors),

                    // Animated expandable section: Smooth Slide-down & Fade-in for remaining rows
                    if (remainingRows.isNotEmpty) ...[
                      ClipRect(
                        child: SizeTransition(
                          sizeFactor: _bouncyCurveAnimation,
                          alignment: Alignment.topCenter,
                          child: FadeTransition(
                            opacity: _bouncyCurveAnimation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                _buildSmartTilesRowsPage(
                                  remainingRows,
                                  state,
                                  colors,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                  // Drag Handle / Tap to Expand or Contract (with smooth animation)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (state.isUnifiedQsExpanded ||
                          _qsBouncyController.value > 0.5) {
                        _qsBouncyController.animateTo(
                          0.0,
                          curve: Curves.easeInCubic,
                          duration: const Duration(milliseconds: 200),
                        );
                        state.setUnifiedQsExpanded(false);
                      } else {
                        _qsBouncyController.animateTo(
                          1.0,
                          curve: Curves.easeOutCubic,
                          duration: const Duration(milliseconds: 240),
                        );
                        state.setUnifiedQsExpanded(true);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _bouncyCurveAnimation,
                          builder: (context, _) {
                            final isExpanded = _qsBouncyController.value > 0.5;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.activePill.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 3.5,
                                    decoration: BoxDecoration(
                                      color: colors.activePill
                                          .withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: colors.activePill,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Categorized Notifications
              _buildSmartNotifications(state, colors, font),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartHeader(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
    FontConfig font,
  ) {
    final now = DateTime.now();
    final hour =
        now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final amPm = now.hour >= 12 ? 'pm' : 'am';

    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final dateFormatted = '$month / $day';

    final topPadding = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.only(top: topPadding > 0 ? topPadding + 6 : 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Time & Date Chip on the left
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.inactivePill.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded, size: 15, color: colors.activePill),
                const SizedBox(width: 6),
                Text(
                  '$hour:$minute $amPm',
                  style: font.textStyleBuilder(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 3.5,
                  height: 3.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateFormatted,
                  style: font.textStyleBuilder(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Battery & Edit Controls Chip on the right
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.inactivePill.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.isCharging
                          ? Icons.battery_charging_full_rounded
                          : Icons.battery_full_rounded,
                      size: 15,
                      color: colors.activePill,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.isCharging
                          ? 'Charging ${state.batteryLevel}%'
                          : '${state.batteryLevel}%',
                      style: font.textStyleBuilder(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildCircleHeaderBtn(Icons.edit_outlined, colors, () {
                HapticFeedback.lightImpact();
                setState(() {
                  _isEditMode = true;
                  _selectedTileId = state.tiles.firstOrNull?.id;
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmartBrightnessSlider(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    return ExpressiveSlider(
      value: state.brightness,
      onChanged: (val) => state.setBrightness(val),
      leadingIcon: Icons.wb_sunny_rounded,
      colors: colors,
      height: 46.0,
      style: state.sliderStyle,
    );
  }

  List<List<QsTileModel>> _packTilesInto3ColRows(List<QsTileModel> tiles) {
    final List<List<QsTileModel>> rows3 = [];
    List<QsTileModel> curRow = [];
    for (final tile in tiles) {
      curRow.add(tile);
      if (curRow.length == 3) {
        rows3.add(curRow);
        curRow = [];
      }
    }
    if (curRow.isNotEmpty) {
      rows3.add(curRow);
    }
    return rows3;
  }

  Widget _buildSmartTilesRowsPage(
    List<List<QsTileModel>> rows,
    ShadeStateProvider state,
    ExpressiveThemeColors colors, [
    int baseRow = 0,
  ]) {
    return Column(
      children: [
        for (int r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 10),
          Row(
            children: [
              for (int c = 0; c < 3; c++) ...[
                if (c > 0) const SizedBox(width: 10),
                Expanded(
                  child: c < rows[r].length
                      ? _buildSmartTile(
                          rows[r][c],
                          state,
                          colors,
                          row: baseRow + r,
                          col: c,
                        )
                      : const SizedBox(height: 58),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSmartTile(
    QsTileModel tile,
    ShadeStateProvider state,
    ExpressiveThemeColors colors, {
    int row = 0,
    int col = 0,
  }) {
    return _SmartMatrixTile(
      tile: tile,
      state: state,
      colors: colors,
      row: row,
      col: col,
      impulseNotifier: _tileImpulseNotifier,
      onTap: () {
        HapticFeedback.lightImpact();
        state.toggleTile(tile.id);
      },
      onLongPress: () {
        HapticFeedback.heavyImpact();
        setState(() {
          _isEditMode = true;
          _selectedTileId = tile.id;
        });
      },
    );
  }

  Widget _buildSmartNotifications(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
    FontConfig font,
  ) {
    if (state.notifications.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        alignment: Alignment.center,
        child: Text(
          'No notifications',
          style: font.textStyleBuilder(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.activePill.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    if (_isSmartUnorganized) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSmartSectionHeader('All notifications', colors, font),
          const SizedBox(height: 10),
          for (int i = 0; i < state.notifications.length; i++)
            _buildSmartNotificationCard(
              state.notifications[i],
              state,
              colors,
              font,
              isFirstInGroup: i == 0,
              isLastInGroup: i == state.notifications.length - 1,
            ),
          _buildSmartActionButtonsRow(state, colors, font),
        ],
      );
    }

    final important = <NotificationModel>[];
    final other = <NotificationModel>[];

    for (final notif in state.notifications) {
      if (_isSmartImportant(notif)) {
        important.add(notif);
      } else {
        other.add(notif);
      }
    }

    if (important.isEmpty && other.isNotEmpty) {
      important.addAll(other.take((other.length / 2).ceil()));
      other.removeRange(0, important.length);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (important.isNotEmpty) ...[
          _buildSmartSectionHeader('Important', colors, font),
          const SizedBox(height: 8),
          for (int i = 0; i < important.length; i++)
            _buildSmartNotificationCard(
              important[i],
              state,
              colors,
              font,
              isFirstInGroup: i == 0,
              isLastInGroup: i == important.length - 1,
            ),
          const SizedBox(height: 16),
        ],
        if (other.isNotEmpty) ...[
          _buildSmartSectionHeader('Other', colors, font),
          const SizedBox(height: 8),
          for (int i = 0; i < other.length; i++)
            _buildSmartNotificationCard(
              other[i],
              state,
              colors,
              font,
              isFirstInGroup: i == 0,
              isLastInGroup: i == other.length - 1,
            ),
        ],
        _buildSmartActionButtonsRow(state, colors, font),
      ],
    );
  }

  bool _isSmartImportant(NotificationModel notif) {
    final combined =
        '${notif.appName} ${notif.title} ${notif.content}'.toLowerCase();
    if (notif.isOngoing) return true;
    if (combined.contains('missed call') ||
        combined.contains('call') ||
        combined.contains('otp') ||
        combined.contains('bank') ||
        combined.contains('code') ||
        combined.contains('driving') ||
        combined.contains('license') ||
        combined.contains('urgent') ||
        combined.contains('security') ||
        combined.contains('alert')) {
      return true;
    }
    return false;
  }

  Widget _buildSmartSectionHeader(
    String title,
    ExpressiveThemeColors colors,
    FontConfig font,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: colors.activePill.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: font.textStyleBuilder(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.activePill,
          ),
        ),
      ),
    );
  }

  Widget _buildSmartNotificationCard(
    NotificationModel notif,
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
    FontConfig font, {
    required bool isFirstInGroup,
    required bool isLastInGroup,
  }) {
    final isCall = notif.title.toLowerCase().contains('call') ||
        notif.content.toLowerCase().contains('call');
    final isChat = notif.appName.toLowerCase().contains('whatsapp') ||
        notif.appName.toLowerCase().contains('message') ||
        notif.appName.toLowerCase().contains('chat');

    String? actionLabel;
    if (isCall) {
      actionLabel = 'Call Back';
    } else if (isChat) {
      actionLabel = 'Reply';
    } else if (notif.actions.isNotEmpty) {
      actionLabel = notif.actions.first.title;
    }

    final BorderRadius borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isFirstInGroup ? 22 : 8),
      topRight: Radius.circular(isFirstInGroup ? 22 : 8),
      bottomLeft: Radius.circular(isLastInGroup ? 22 : 8),
      bottomRight: Radius.circular(isLastInGroup ? 22 : 8),
    );

    if (_smartSettingsNotifId == notif.id) {
      return NotificationChannelSettingsCard(
        notification: notif,
        colors: colors,
        font: font,
        borderRadius: borderRadius,
        onClose: () => setState(() => _smartSettingsNotifId = null),
      );
    }

    return SpringyDismissibleNotification(
      key: Key('smart_notif_${notif.id}'),
      colors: colors,
      borderRadius: borderRadius,
      margin: EdgeInsets.only(bottom: isLastInGroup ? 10 : 3),
      onDismissed: () {
        state.dismissNotification(notif.id);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          state.openNotification(notif).then((opened) {
            if (opened && mounted) {
              widget.onDismissAndExecute?.call(() {});
            }
          });
        },
        onLongPress: () {
          HapticFeedback.heavyImpact();
          setState(() {
            _smartSettingsNotifId =
                (_smartSettingsNotifId == notif.id) ? null : notif.id;
          });
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.72),
            borderRadius: borderRadius,
            border: Border.all(
              color: colors.inactivePill.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              // Real App Icon / Avatar with rounded squircle background
              Container(
                width: 26,
                height: 26,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: notif.appColor.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: notif.appIconBytes != null
                    ? Image.memory(
                        notif.appIconBytes!,
                        width: 26,
                        height: 26,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            notif.appIcon,
                            size: 14,
                            color: notif.appColor,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          notif.appIcon,
                          size: 14,
                          color: notif.appColor,
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // Content text: Title & Content formatted
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      if (notif.title.isNotEmpty)
                        TextSpan(
                          text: '${notif.title}  ',
                          style: font.textStyleBuilder(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      TextSpan(
                        text: notif.content,
                        style: font.textStyleBuilder(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Action Pill Button (Call Back / Reply / etc.)
              if (actionLabel != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (notif.actions.isNotEmpty) {
                      state.performNotificationAction(
                        notif,
                        notif.actions.first,
                      );
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colors.activePill.withValues(alpha: 0.65),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      actionLabel,
                      style: font.textStyleBuilder(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.activePill,
                      ),
                    ),
                  ),
                ),
              ],

              // Distinct vertical accent bar on the right
              Container(
                width: 5,
                height: 32,
                margin: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  color: colors.activePill.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartActionButtonsRow(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
    FontConfig font,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(
        children: [
          // 1. History Icon Button
          _buildSmartIconButton(
            icon: Icons.history_rounded,
            colors: colors,
            onTap: () {
              HapticFeedback.lightImpact();
              SystemHardwareService.openNotificationHistory();
            },
          ),
          const SizedBox(width: 10),

          // 2. Wide Clear All Button (prominent in the center)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.mediumImpact();
                state.clearAllNotifications();
              },
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Clear all',
                    style: font.textStyleBuilder(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: colors.activePill,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 3. Organize / Unorganize Icon Button
          _buildSmartIconButton(
            icon: _isSmartUnorganized
                ? Icons.auto_awesome_mosaic_rounded
                : Icons.filter_list_rounded,
            colors: colors,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isSmartUnorganized = !_isSmartUnorganized;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSmartIconButton({
    required IconData icon,
    required ExpressiveThemeColors colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 21,
            color: colors.activePill,
          ),
        ),
      ),
    );
  }

  Widget _buildSmartEditTilesView(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    final font = state.selectedFont;
    final topPadding = MediaQuery.of(context).padding.top;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        topPadding > 0 ? topPadding + 6 : 14,
        16,
        32,
      ),
      children: [
        // Header Row with Title and Done button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rearrange Tiles',
                  style: font.textStyleBuilder(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Drag to change tile positions',
                  style: font.textStyleBuilder(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w400,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _isEditMode = false);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.activePill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: colors.onActivePill,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Done',
                      style: font.textStyleBuilder(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.onActivePill,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 3-Column Matrix Active Tiles Container
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colors.inactivePill.withValues(alpha: 0.35),
              width: 1.0,
            ),
          ),
          child: _buildSmartEditGrid(state, colors, font),
        ),
        const SizedBox(height: 24),

        // Available Tiles Section (tap to add to matrix, without resizing)
        Text(
          'Available Tiles',
          style: font.textStyleBuilder(
            fontSize: 16.0,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to add or remove tiles from the matrix',
          style: font.textStyleBuilder(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),

        _buildSmartAvailableTilesGrid(state, colors, font),
      ],
    );
  }

  Widget _buildSmartEditGrid(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
    FontConfig font,
  ) {
    final activeTiles = state.tiles;
    if (activeTiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'No active tiles',
            style: font.textStyleBuilder(
              fontSize: 14,
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    // Chunk tiles into rows of 3
    final List<List<QsTileModel>> rows = [];
    for (int i = 0; i < activeTiles.length; i += 3) {
      final end = (i + 3 < activeTiles.length) ? i + 3 : activeTiles.length;
      rows.add(activeTiles.sublist(i, end));
    }

    return Column(
      children: [
        for (int r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 10),
          Row(
            children: [
              for (int c = 0; c < 3; c++) ...[
                if (c > 0) const SizedBox(width: 10),
                Expanded(
                  child: c < rows[r].length
                      ? _buildSmartEditTileItem(
                          tile: rows[r][c],
                          state: state,
                          colors: colors,
                          font: font,
                        )
                      : const SizedBox(height: 64),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSmartEditTileItem({
    required QsTileModel tile,
    required ShadeStateProvider state,
    required ExpressiveThemeColors colors,
    required FontConfig font,
  }) {
    final isSelected = _selectedTileId == tile.id;

    final tileBox = Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: tile.isActive
            ? colors.activePill
            : colors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? colors.activePill
              : (tile.isActive
                  ? colors.activePill
                  : colors.inactivePill.withValues(alpha: 0.4)),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tile.icon,
                size: 20,
                color:
                    tile.isActive ? colors.onActivePill : colors.textPrimary,
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.drag_indicator_rounded,
                size: 14,
                color: (tile.isActive
                        ? colors.onActivePill
                        : colors.textSecondary)
                    .withValues(alpha: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            tile.title,
            style: font.textStyleBuilder(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color:
                  tile.isActive ? colors.onActivePill : colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

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
            borderRadius: BorderRadius.circular(14),
            border: isHovered
                ? Border.all(color: colors.activePill, width: 2.5)
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              LongPressDraggable<String>(
                data: tile.id,
                delay: const Duration(milliseconds: 80),
                feedback: Material(
                  color: Colors.transparent,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 90,
                    height: 64,
                    child: Opacity(opacity: 0.9, child: tileBox),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.25,
                  child: tileBox,
                ),
                child: tileBox,
              ),
              // Subtle remove button at top right
              Positioned(
                top: -5,
                right: -5,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    state.removeTile(tile.id);
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colors.inactivePill,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.surface,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmartAvailableTilesGrid(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
    FontConfig font,
  ) {
    final inactiveTiles = QsTileModel.allAvailableTiles
        .where((t) => !state.tiles.any((at) => at.id == t.id))
        .toList();

    if (inactiveTiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'All tiles added',
            style: font.textStyleBuilder(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: inactiveTiles.length,
      itemBuilder: (context, index) {
        final tile = inactiveTiles[index];
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            state.addTile(tile);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colors.inactivePill.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  tile.icon,
                  size: 18,
                  color: colors.textPrimary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    tile.title,
                    style: font.textStyleBuilder(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.add_rounded,
                  size: 14,
                  color: colors.activePill,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnifiedShadeView(
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    final font = state.selectedFont;
    final allRows = _packTilesIntoRows(state.tiles);

    return ListView(
      controller: _unifiedScrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
        padding: const EdgeInsets.only(top: 8, bottom: 0),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Sliders for Brightness and Media/Volume AT THE TOP
                ClipRect(
                  child: SizeTransition(
                    sizeFactor: _bouncyCurveAnimation,
                    alignment: Alignment.topCenter,
                    child: FadeTransition(
                      opacity: _bouncyCurveAnimation,
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
                          const SizedBox(height: 10),

                          // Volume / Media Capsule Slider
                          ExpressiveSlider(
                            value: state.volume,
                            onChanged: (val) => state.setVolume(val),
                            leadingIcon: state.volume == 0
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            colors: colors,
                            style: state.sliderStyle,
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Unified Paginated Quick Settings Grid (Entire grid pages together!)
                _buildUnifiedPaginatedTilesGrid(state, colors, allRows),

                // 3. Drag Handle / Tap to Expand or Contract (with smooth animation)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (state.isUnifiedQsExpanded ||
                        _qsBouncyController.value > 0.5) {
                      _qsBouncyController.animateTo(
                        0.0,
                        curve: Curves.easeInCubic,
                        duration: const Duration(milliseconds: 200),
                      );
                      state.setUnifiedQsExpanded(false);
                    } else {
                      _qsBouncyController.animateTo(
                        1.0,
                        curve: Curves.easeOutCubic,
                        duration: const Duration(milliseconds: 240),
                      );
                      state.setUnifiedQsExpanded(true);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _bouncyCurveAnimation,
                        builder: (context, _) {
                          final isExpanded = _qsBouncyController.value > 0.5;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.activePill.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 34,
                                  height: 3.5,
                                  decoration: BoxDecoration(
                                    color: colors.activePill
                                        .withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: colors.activePill,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

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
                      style: state.mediaPlayerStyle,
                      onPlayPause: () => state.togglePlayPause(),
                      onSkipNext: () => state.skipNextMedia(),
                      onSkipPrevious: () => state.skipPreviousMedia(),
                      onProgressChanged: (val) => state.setMediaProgress(val),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Distinct Division: Notifications Container with Rounded Top Corners & Acrylic Blur
          RepaintBoundary(
            child: _buildNotificationsContainer(state, colors, font),
          ),
        ],
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

class _PaginatedTilesContainer extends StatefulWidget {
  final ExpressiveThemeColors colors;
  final List<List<List<QsTileModel>>> pages;
  final Widget Function(BuildContext context, int pageIndex) builder;
  final double fixedHeight;

  const _PaginatedTilesContainer({
    required this.colors,
    required this.pages,
    required this.builder,
    this.fixedHeight = (5 * 68.0) + (4 * 12.0),
  });

  @override
  State<_PaginatedTilesContainer> createState() =>
      _PaginatedTilesContainerState();
}

class _PaginatedTilesContainerState extends State<_PaginatedTilesContainer> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isIndicatorVisible = false;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.pages.length > 1) {
      _showIndicatorBriefly();
    }
  }

  void _showIndicatorBriefly([
    Duration duration = const Duration(milliseconds: 1800),
  ]) {
    _fadeTimer?.cancel();
    if (mounted && !_isIndicatorVisible) {
      setState(() => _isIndicatorVisible = true);
    }
    _fadeTimer = Timer(duration, () {
      if (mounted && _isIndicatorVisible) {
        setState(() => _isIndicatorVisible = false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _PaginatedTilesContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage >= widget.pages.length) {
      _currentPage = (widget.pages.length - 1).clamp(0, widget.pages.length);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }
    }
    if (widget.pages.length != oldWidget.pages.length &&
        widget.pages.length > 1) {
      _showIndicatorBriefly();
    }
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showIndicator = widget.pages.length > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.fixedHeight,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification ||
                  notification is ScrollUpdateNotification) {
                _fadeTimer?.cancel();
                if (!_isIndicatorVisible) {
                  setState(() => _isIndicatorVisible = true);
                }
              } else if (notification is ScrollEndNotification) {
                _showIndicatorBriefly();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.pages.length,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
                _showIndicatorBriefly();
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: widget.builder(context, index),
                  ),
                );
              },
            ),
          ),
        ),
        if (showIndicator) ...[
          const SizedBox(height: 12),
          // Material 3 Expressive Pill Dots Indicator (fades out when inactive)
          AnimatedOpacity(
            opacity: _isIndicatorVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.pages.length, (index) {
                final isSelected = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.colors.activePill
                        : widget.colors.inactivePill,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }
}

class _UnifiedPaginatedTilesContainer extends StatefulWidget {
  final ExpressiveThemeColors colors;
  final List<List<List<QsTileModel>>> pages;
  final Animation<double> bouncyAnimation;
  final Widget Function(BuildContext context, int pageIndex) builder;

  const _UnifiedPaginatedTilesContainer({
    required this.colors,
    required this.pages,
    required this.bouncyAnimation,
    required this.builder,
  });

  @override
  State<_UnifiedPaginatedTilesContainer> createState() =>
      _UnifiedPaginatedTilesContainerState();
}

class _UnifiedPaginatedTilesContainerState
    extends State<_UnifiedPaginatedTilesContainer> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isIndicatorVisible = false;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.pages.length > 1) {
      _showIndicatorBriefly();
    }
  }

  void _showIndicatorBriefly([
    Duration duration = const Duration(milliseconds: 1800),
  ]) {
    _fadeTimer?.cancel();
    if (mounted && !_isIndicatorVisible) {
      setState(() => _isIndicatorVisible = true);
    }
    _fadeTimer = Timer(duration, () {
      if (mounted && _isIndicatorVisible) {
        setState(() => _isIndicatorVisible = false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _UnifiedPaginatedTilesContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage >= widget.pages.length) {
      _currentPage = (widget.pages.length - 1).clamp(0, widget.pages.length);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }
    }
    if (widget.pages.length != oldWidget.pages.length &&
        widget.pages.length > 1) {
      _showIndicatorBriefly();
    }
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showIndicator = widget.pages.length > 1;

    // Calculate maximum rows on any page (capped at 5)
    int maxRows = 2;
    for (final page in widget.pages) {
      if (page.length > maxRows) maxRows = page.length;
    }
    maxRows = maxRows.clamp(2, 5);

    const double collapsedHeight = (2 * 68.0) + (1 * 12.0); // 148.0
    final double expandedHeight = (maxRows * 68.0) + ((maxRows - 1) * 12.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: widget.bouncyAnimation,
          builder: (context, _) {
            final currentHeight = collapsedHeight +
                (expandedHeight - collapsedHeight) *
                    widget.bouncyAnimation.value;

            return SizedBox(
              height: currentHeight,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification ||
                      notification is ScrollUpdateNotification) {
                    _fadeTimer?.cancel();
                    if (!_isIndicatorVisible) {
                      setState(() => _isIndicatorVisible = true);
                    }
                  } else if (notification is ScrollEndNotification) {
                    _showIndicatorBriefly();
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.pages.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                    _showIndicatorBriefly();
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: widget.builder(context, index),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
        if (showIndicator) ...[
          const SizedBox(height: 12),
          // Material 3 Expressive Pill Dots Indicator (fades out when inactive)
          AnimatedOpacity(
            opacity: _isIndicatorVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.pages.length, (index) {
                final isSelected = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.colors.activePill
                        : widget.colors.inactivePill,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }
}

class _SmartMatrixTile extends StatefulWidget {
  final QsTileModel tile;
  final ShadeStateProvider state;
  final ExpressiveThemeColors colors;
  final int row;
  final int col;
  final ValueNotifier<TileImpulse?>? impulseNotifier;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SmartMatrixTile({
    required this.tile,
    required this.state,
    required this.colors,
    required this.row,
    required this.col,
    required this.impulseNotifier,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_SmartMatrixTile> createState() => _SmartMatrixTileState();
}

class _SmartMatrixTileState extends State<_SmartMatrixTile>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressHeightAnim;
  late Animation<double> _pressWidthAnim;

  late AnimationController _neighborController;
  late Animation<double> _neighborHeightAnim;
  late Animation<double> _neighborWidthAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _pressHeightAnim = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeInQuad,
        reverseCurve: Curves.easeOutBack,
      ),
    );
    _pressWidthAnim = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeInQuad,
        reverseCurve: Curves.easeOutBack,
      ),
    );

    _neighborController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 320),
    );
    _neighborHeightAnim = Tween<double>(begin: 0.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _neighborController,
        curve: Curves.easeOutQuad,
        reverseCurve: Curves.easeOutBack,
      ),
    );
    _neighborWidthAnim = Tween<double>(begin: 0.0, end: 4.5).animate(
      CurvedAnimation(
        parent: _neighborController,
        curve: Curves.easeOutQuad,
        reverseCurve: Curves.easeOutBack,
      ),
    );

    widget.impulseNotifier?.addListener(_onImpulse);
  }

  @override
  void didUpdateWidget(covariant _SmartMatrixTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.impulseNotifier != oldWidget.impulseNotifier) {
      oldWidget.impulseNotifier?.removeListener(_onImpulse);
      widget.impulseNotifier?.addListener(_onImpulse);
    }
  }

  @override
  void dispose() {
    widget.impulseNotifier?.removeListener(_onImpulse);
    _pressController.dispose();
    _neighborController.dispose();
    super.dispose();
  }

  void _onImpulse() {
    final impulse = widget.impulseNotifier?.value;
    if (impulse == null || impulse.tileId == widget.tile.id) return;

    final dr = (widget.row - impulse.row).toDouble();
    final dc = (widget.col - impulse.col).toDouble();
    final dist = math.sqrt(dr * dr + dc * dc);

    if (dist <= 1.5 && mounted) {
      final delayMs = (dist * 20).toInt();
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) {
          _neighborController.forward().then((_) {
            if (mounted) _neighborController.reverse();
          });
        }
      });
    }
  }

  void _handleTapDown([TapDownDetails? _]) {
    _pressController.forward();
    HapticFeedback.lightImpact();
    widget.impulseNotifier?.value = TileImpulse(
      tileId: widget.tile.id,
      row: widget.row,
      col: widget.col,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  void _handleTapUp([TapUpDetails? _]) {
    _pressController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final tile = widget.tile;
    final colors = widget.colors;
    final isActive = tile.isActive;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pressHeightAnim,
        _pressWidthAnim,
        _neighborHeightAnim,
        _neighborWidthAnim,
      ]),
      builder: (context, child) {
        final hSquish = _pressHeightAnim.value + _neighborHeightAnim.value;
        final wSquish = _pressWidthAnim.value + _neighborWidthAnim.value;
        final currentHeight = (58.0 - hSquish).clamp(40.0, 58.0);

        return SizedBox(
          height: 58.0,
          child: Center(
            child: SizedBox(
              height: currentHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: (wSquish / 2).clamp(0.0, 8.0),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isActive ? colors.activePill : colors.inactivePill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? colors.activePill
                  : colors.inactivePill.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          child: Center(
            child: Icon(
              tile.icon,
              size: 26,
              color: isActive ? colors.onActivePill : colors.onInactivePill,
            ),
          ),
        ),
      ),
    );
  }
}
