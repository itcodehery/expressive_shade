import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../features/shade_modes/common/standard_edit_tiles_view.dart';
import '../features/shade_modes/compact_matrix/compact_matrix_view.dart';
import '../features/shade_modes/compact_matrix/widgets/matrix_edit_grid.dart';
import '../features/shade_modes/split/split_shade_view.dart';
import '../features/shade_modes/unified/unified_shade_view.dart';
import '../models/font_config.dart';
import '../models/shade_mode.dart';
import '../providers/shade_state_provider.dart';
import '../theme/m3_expressive_theme.dart';
import 'expressive_pill.dart';
import 'expressive_power_menu_dialog.dart';

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
  int _lastOpenEpoch = 0;

  final ValueNotifier<bool> _reduceBlur = ValueNotifier<bool>(false);

  // Notifications Upward Drag-to-Close Tracker
  double _notifPointerStartX = 0.0;
  double _notifPointerStartY = 0.0;
  double _notifLastPointerY = 0.0;
  bool _dragStartExpanded = false;
  _DragAction _activeDragAction = _DragAction.none;
  VelocityTracker? _notifVelocityTracker;
  double _bottomOverscrollAccumulator = 0.0;

  @override
  void initState() {
    super.initState();
    final state = context.read<ShadeStateProvider>();
    _pageController = PageController(initialPage: state.splitTabIndex);

    _qsBouncyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _bouncyCurveAnimation = CurvedAnimation(
      parent: _qsBouncyController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _qsBouncyController.addListener(() {
      _reduceBlur.value = _qsBouncyController.isAnimating;
    });

    _unifiedScrollController.addListener(() {
      _reduceBlur.value = true;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _unifiedScrollController.dispose();
    _tileImpulseNotifier.dispose();
    _qsBouncyController.dispose();
    _reduceBlur.dispose();
    super.dispose();
  }

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
      if (isSplit && _pageController.hasClients) {
        final targetIndex = context.read<ShadeStateProvider>().splitTabIndex;
        _pageController.jumpToPage(targetIndex);
      }
    });
  }

  void _handleUnifiedQsToggle() {
    HapticFeedback.lightImpact();
    final state = context.read<ShadeStateProvider>();
    if (state.isUnifiedQsExpanded || _qsBouncyController.value > 0.5) {
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
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShadeStateProvider>();
    final isSplit = state.shadeMode == ShadeMode.split;
    final isExpanded = state.isUnifiedQsExpanded;
    final openEpoch = state.shadeOpenEpoch;
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

    final showStandardHeader = state.shadeMode != ShadeMode.smart;

    final mainContent = ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: Container(
        color: colors.background,
        child: SafeArea(
          top: false,
          bottom: true,
          child: Column(
          children: [
            if (showStandardHeader) ...[
              // Status Bar & System Header (Completely Opaque Top Section)
              Container(
                color: colors.background,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusBar(state, colors),
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
                ),
              ),
            ],

            // Main View
            Expanded(
              child: _isEditMode
                  ? (state.shadeMode == ShadeMode.smart
                      ? MatrixEditGrid(
                          tiles: state.tiles,
                          selectedTileId: _selectedTileId,
                          colors: colors,
                          font: state.selectedFont,
                          onReorder: (oldIdx, newIdx) =>
                              state.reorderTile(oldIdx, newIdx),
                          onTileTap: (id) =>
                              setState(() => _selectedTileId = id),
                          onAddTile: (tile) => state.addTile(tile),
                          onRemoveTile: (id) => state.removeTile(id),
                          onDone: () {
                            state.flushSave();
                            setState(() => _isEditMode = false);
                          },
                        )
                      : StandardEditTilesView(
                          tiles: state.tiles,
                          selectedTileId: _selectedTileId,
                          colors: colors,
                          font: state.selectedFont,
                          onTileTap: (id) =>
                              setState(() => _selectedTileId = id),
                          onResizeTap: (id) => state.toggleTileSize(id),
                          onAddTile: (tile) => state.addTile(tile),
                          onReorder: (oldIdx, newIdx) =>
                              state.reorderTile(oldIdx, newIdx),
                          impulseNotifier: _tileImpulseNotifier,
                        ))
                  : switch (state.shadeMode) {
                      ShadeMode.split => SplitShadeView(
                          pageController: _pageController,
                          colors: colors,
                          font: state.selectedFont,
                          tiles: state.tiles,
                          brightness: state.brightness,
                          volume: state.volume,
                          sliderStyle: state.sliderStyle,
                          onBrightnessChanged: (v) => state.setBrightness(v),
                          onVolumeChanged: (v) => state.setVolume(v),
                          onToggleTile: (id) => state.toggleTile(id),
                          onLongPressTile: (id) => setState(() {
                            _isEditMode = true;
                            _selectedTileId = id;
                          }),
                          onResizeTile: (id) => state.toggleTileSize(id),
                          impulseNotifier: _tileImpulseNotifier,
                          onPageChanged: (idx) => state.setSplitTabIndex(idx),
                          mediaTitle: state.mediaTitle,
                          mediaArtist: state.mediaArtist,
                          mediaApp: state.mediaApp,
                          isPlaying: state.isPlaying,
                          mediaProgress: state.mediaProgress,
                          mediaArtwork: state.mediaArtwork,
                          mediaPlayerStyle: state.mediaPlayerStyle,
                          onPlayPause: () => state.togglePlayPause(),
                          onSkipNext: () => state.skipNextMedia(),
                          onSkipPrevious: () => state.skipPreviousMedia(),
                          onProgressChanged: (v) => state.setMediaProgress(v),
                          notifications: state.notifications,
                          notificationStyle: state.notificationStyle,
                          onDismissNotification: (id) =>
                              state.dismissNotification(id),
                          onActionTap: (notif, action) =>
                              state.performNotificationAction(notif, action),
                          onReply: (notif, action, text) =>
                              state.performNotificationAction(notif, action,
                                  replyText: text),
                          onSnoozeNotification: (notif) =>
                              state.snoozeNotification(
                                  notif.id, duration: const Duration(hours: 1)),
                          onOpenNotification: (notif) {
                            if (widget.onDismissAndExecute != null) {
                              widget.onDismissAndExecute!(
                                  () => state.openNotification(notif));
                            } else {
                              state.openNotification(notif);
                            }
                          },
                        ),
                      ShadeMode.unified => UnifiedShadeView(
                          scrollController: _unifiedScrollController,
                          bouncyAnimation: _bouncyCurveAnimation,
                          colors: colors,
                          font: state.selectedFont,
                          tiles: state.tiles,
                          brightness: state.brightness,
                          volume: state.volume,
                          sliderStyle: state.sliderStyle,
                          onBrightnessChanged: (v) => state.setBrightness(v),
                          onVolumeChanged: (v) => state.setVolume(v),
                          onToggleExpand: _handleUnifiedQsToggle,
                          onToggleTile: (id) => state.toggleTile(id),
                          onLongPressTile: (id) => setState(() {
                            _isEditMode = true;
                            _selectedTileId = id;
                          }),
                          onResizeTile: (id) => state.toggleTileSize(id),
                          impulseNotifier: _tileImpulseNotifier,
                          reduceBlur: _reduceBlur,
                          customTheme: state.customTheme,
                          mediaTitle: state.mediaTitle,
                          mediaArtist: state.mediaArtist,
                          mediaApp: state.mediaApp,
                          isPlaying: state.isPlaying,
                          mediaProgress: state.mediaProgress,
                          mediaArtwork: state.mediaArtwork,
                          mediaPlayerStyle: state.mediaPlayerStyle,
                          onPlayPause: () => state.togglePlayPause(),
                          onSkipNext: () => state.skipNextMedia(),
                          onSkipPrevious: () => state.skipPreviousMedia(),
                          onProgressChanged: (v) => state.setMediaProgress(v),
                          notifications: state.notifications,
                          notificationStyle: state.notificationStyle,
                          onDismissNotification: (id) =>
                              state.dismissNotification(id),
                          onActionTap: (notif, action) =>
                              state.performNotificationAction(notif, action),
                          onReply: (notif, action, text) =>
                              state.performNotificationAction(notif, action,
                                  replyText: text),
                          onSnoozeNotification: (notif) =>
                              state.snoozeNotification(
                                  notif.id, duration: const Duration(hours: 1)),
                          onOpenNotification: (notif) {
                            if (widget.onDismissAndExecute != null) {
                              widget.onDismissAndExecute!(
                                  () => state.openNotification(notif));
                            } else {
                              state.openNotification(notif);
                            }
                          },
                        ),
                      ShadeMode.smart => CompactMatrixView(
                          batteryLevel: state.batteryLevel,
                          isCharging: state.isCharging,
                          colors: colors,
                          font: state.selectedFont,
                          tiles: state.tiles,
                          notifications: state.notifications,
                          notificationStyle: state.notificationStyle,
                          isExpanded: state.isUnifiedQsExpanded,
                          bouncyAnimation: _bouncyCurveAnimation,
                          isUnorganized: _isSmartUnorganized,
                          brightness: state.brightness,
                          sliderStyle: state.sliderStyle,
                          onBrightnessChanged: (v) => state.setBrightness(v),
                          onToggleTile: (id) => state.toggleTile(id),
                          onLongPressTile: (id) => setState(() {
                            _isEditMode = true;
                            _selectedTileId = id;
                          }),
                          onToggleExpand: _handleUnifiedQsToggle,
                          onEditTap: () => setState(() => _isEditMode = true),
                          onToggleOrganize: () => setState(
                              () => _isSmartUnorganized = !_isSmartUnorganized),
                          onClearAll: () => state.clearAllNotifications(),
                          onOpenHistory: () {
                            if (widget.onDismissAndExecute != null) {
                              widget.onDismissAndExecute!(
                                  () => state.openNotificationHistory());
                            } else {
                              state.openNotificationHistory();
                            }
                          },
                          onDismissNotification: (id) =>
                              state.dismissNotification(id),
                          onActionTap: (notif, action) =>
                              state.performNotificationAction(notif, action),
                          onReply: (notif, action, text) =>
                              state.performNotificationAction(notif, action,
                                  replyText: text),
                          onSnoozeNotification: (notif) =>
                              state.snoozeNotification(
                                  notif.id, duration: const Duration(hours: 1)),
                          onOpenNotification: (notif) {
                            if (widget.onDismissAndExecute != null) {
                              widget.onDismissAndExecute!(
                                  () => state.openNotification(notif));
                            } else {
                              state.openNotification(notif);
                            }
                          },
                          impulseNotifier: _tileImpulseNotifier,
                          scrollController: _unifiedScrollController,
                        ),
                    },
            ),
          ],
        ),
      ),
    ),
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
          _LiveClock(font: font, colors: colors),
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
                  state.carrierName.isNotEmpty ? state.carrierName : 'Jio',
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
          _buildCircleHeaderBtn(Icons.edit_rounded, colors, () {
            HapticFeedback.lightImpact();
            setState(() {
              _isEditMode = true;
              _selectedTileId = state.tiles.firstOrNull?.id;
            });
          }),
          const SizedBox(width: 8),
          _buildCircleHeaderBtn(Icons.settings_rounded, colors, () {
            HapticFeedback.lightImpact();
            if (widget.onDismissAndExecute != null) {
              widget.onDismissAndExecute!(() => state.openSettings());
            } else {
              state.openSettings();
            }
          }),
          const SizedBox(width: 8),
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
    final hasSelection = _selectedTileId != null &&
        state.tiles.any((t) => t.id == _selectedTileId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colors.textPrimary,
              size: 24,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              state.flushSave();
              setState(() {
                _isEditMode = false;
                _selectedTileId = null;
              });
            },
          ),
          const Spacer(),
          _buildCircleHeaderBtn(Icons.replay_rounded, colors, () {
            HapticFeedback.mediumImpact();
            state.resetTiles();
            setState(() {
              _selectedTileId = state.tiles.firstOrNull?.id;
            });
          }),
          const SizedBox(width: 8),
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

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_isEditMode) return false;
    final state = context.read<ShadeStateProvider>();

    // For Unified and Smart (Compact Matrix), when expanded, pointer listener handles collapsing QS
    if ((state.shadeMode == ShadeMode.unified || state.shadeMode == ShadeMode.smart) &&
        state.isUnifiedQsExpanded) {
      return false;
    }

    // For Split mode, only listen on notifications page (index 0)
    if (state.shadeMode == ShadeMode.split && state.splitTabIndex != 0) {
      return false;
    }

    if (notification is OverscrollNotification) {
      // In Flutter vertical scrolling, overscroll > 0 indicates pulling up past the bottom (maxScrollExtent)
      if (notification.overscroll > 0) {
        _bottomOverscrollAccumulator += notification.overscroll;
        final screenHeight = MediaQuery.of(context).size.height;
        widget.onDragShadeUpdate?.call(-notification.overscroll / screenHeight);
      }
    } else if (notification is ScrollEndNotification) {
      final metrics = notification.metrics;
      final velocity = notification.dragDetails?.primaryVelocity ?? 0.0;
      final isAtBottom = metrics.pixels >= metrics.maxScrollExtent - 4.0;

      if (_bottomOverscrollAccumulator > 18.0 || (isAtBottom && velocity < -120)) {
        widget.onDragShadeEnd?.call(velocity < 0 ? velocity : -350.0);
      } else if (_bottomOverscrollAccumulator > 0) {
        widget.onDragShadeEnd?.call(0.0);
      }
      _bottomOverscrollAccumulator = 0.0;
    }
    return false;
  }

  Widget _wrapWithNotificationsDragToClose(Widget child) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Listener(
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

          if (_isEditMode || _activeDragAction == _DragAction.ignored) return;

          final state = context.read<ShadeStateProvider>();
          final isUnifiedOrMatrix = state.shadeMode == ShadeMode.unified ||
              state.shadeMode == ShadeMode.smart;

          final isAtTop = !_unifiedScrollController.hasClients ||
              _unifiedScrollController.offset <= 4.0;
          final isAtBottom = !_unifiedScrollController.hasClients ||
              _unifiedScrollController.offset >=
                  _unifiedScrollController.position.maxScrollExtent - 4.0;

          if (_activeDragAction == _DragAction.none) {
            if (totalDeltaX.abs() > 10.0 && totalDeltaX.abs() > totalDeltaY.abs()) {
              _activeDragAction = _DragAction.ignored;
              return;
            }

            if (totalDeltaY.abs() > 12.0 &&
                totalDeltaY.abs() > totalDeltaX.abs() * 1.2) {
              if (isUnifiedOrMatrix) {
                if (_dragStartExpanded) {
                  // Expanded QS: swiping up anywhere collapses back to normal shade
                  if (totalDeltaY < -12.0) {
                    _activeDragAction = _DragAction.collapsingQs;
                  }
                } else {
                  // Normal shade: swiping down anywhere expands the shade
                  if (totalDeltaY > 12.0 && isAtTop) {
                    _activeDragAction = _DragAction.expandingQs;
                  } else if (totalDeltaY < -14.0 && isAtBottom) {
                    // Normal shade: swiping up when at bottom collapses the whole shade
                    _activeDragAction = _DragAction.dismissingShade;
                  }
                }
              } else {
                // Split shade
                if (totalDeltaY < -16.0 && isAtBottom) {
                  _activeDragAction = _DragAction.dismissingShade;
                }
              }
            }
          }

          if (_activeDragAction == _DragAction.expandingQs ||
              _activeDragAction == _DragAction.collapsingQs) {
            final progressDelta = deltaY / 220.0;
            _qsBouncyController.value =
                (_qsBouncyController.value + progressDelta).clamp(0.0, 1.0);
          } else if (_activeDragAction == _DragAction.dismissingShade) {
            widget.onDragShadeUpdate?.call(deltaY);
          } else if (!_dragStartExpanded && totalDeltaY < 0 && !isAtBottom) {
            // If pointer started on non-scrollable header area, forward upward drag to scroll list
            if (_unifiedScrollController.hasClients && event.position.dy < 240) {
              final newOffset = (_unifiedScrollController.offset - deltaY).clamp(
                0.0,
                _unifiedScrollController.position.maxScrollExtent,
              );
              _unifiedScrollController.jumpTo(newOffset);
            }
          }
        },
        onPointerUp: (event) {
          _notifVelocityTracker?.addPosition(event.timeStamp, event.position);
          final velocity =
              _notifVelocityTracker?.getVelocity().pixelsPerSecond.dy ?? 0.0;
          final state = context.read<ShadeStateProvider>();

          if (_activeDragAction == _DragAction.expandingQs) {
            if (velocity > 100 || _qsBouncyController.value > 0.30) {
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
            if (velocity < -100 || _qsBouncyController.value < 0.70) {
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
      ),
    );
  }
}

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
