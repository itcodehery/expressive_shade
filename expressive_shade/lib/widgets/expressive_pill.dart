import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/font_config.dart';
import '../models/qs_tile_model.dart';
import '../theme/m3_expressive_theme.dart';

class TileImpulse {
  final String tileId;
  final int row;
  final int col;
  final int timestamp;

  const TileImpulse({
    required this.tileId,
    required this.row,
    required this.col,
    required this.timestamp,
  });
}

class ExpressivePill extends StatefulWidget {
  final QsTileModel tile;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isEditing;
  final bool isSelected;
  final VoidCallback? onResizeTap;
  final VoidCallback? onInnerButtonTap;
  final VoidCallback? onOuterPillTap;
  final int row;
  final int col;
  final ValueNotifier<TileImpulse?>? impulseNotifier;

  const ExpressivePill({
    super.key,
    required this.tile,
    required this.colors,
    required this.font,
    required this.onTap,
    this.onLongPress,
    this.isEditing = false,
    this.isSelected = false,
    this.onResizeTap,
    this.onInnerButtonTap,
    this.onOuterPillTap,
    this.row = 0,
    this.col = 0,
    this.impulseNotifier,
  });

  @override
  State<ExpressivePill> createState() => _ExpressivePillState();
}

class _ExpressivePillState extends State<ExpressivePill>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late AnimationController _neighborController;
  late Animation<double> _neighborScaleAnimation;
  double _dragAccumulator = 0.0;

  @override
  void initState() {
    super.initState();
    // 1. Primary Bouncy Press Animation (Curves.easeOutBack for expressive overshoot bounce)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
      reverseDuration: const Duration(milliseconds: 160),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.91).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInQuad,
        reverseCurve: Curves.easeOutBack, // M3 Expressive Spring Bounce
      ),
    );

    // 2. Spatial Neighbor Deflection Animation
    _neighborController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
      reverseDuration: const Duration(milliseconds: 140),
    );

    _neighborScaleAnimation = Tween<double>(begin: 1.0, end: 0.955).animate(
      CurvedAnimation(
        parent: _neighborController,
        curve: Curves.easeOutQuad,
        reverseCurve: Curves.easeOutBack,
      ),
    );

    widget.impulseNotifier?.addListener(_onImpulseReceived);
  }

  @override
  void didUpdateWidget(covariant ExpressivePill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.impulseNotifier != oldWidget.impulseNotifier) {
      oldWidget.impulseNotifier?.removeListener(_onImpulseReceived);
      widget.impulseNotifier?.addListener(_onImpulseReceived);
    }
  }

  @override
  void dispose() {
    widget.impulseNotifier?.removeListener(_onImpulseReceived);
    _animController.dispose();
    _neighborController.dispose();
    super.dispose();
  }

  void _onImpulseReceived() {
    final impulse = widget.impulseNotifier?.value;
    if (impulse == null || impulse.tileId == widget.tile.id) return;

    // Euclidean distance in the grid
    final dr = (widget.row - impulse.row).toDouble();
    final dc = (widget.col - impulse.col).toDouble();
    final dist = math.sqrt(dr * dr + dc * dc);

    // Only immediate neighbors (adjacent or diagonal within dist <= 1.5)
    if (dist <= 1.5 && mounted) {
      final delayMs = (dist * 18).toInt();
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) {
          _neighborController.forward().then((_) {
            if (mounted) {
              _neighborController.reverse();
            }
          });
        }
      });
    }
  }

  void _handleTapDown([TapDownDetails? _]) {
    _animController.forward();
    HapticFeedback.lightImpact();

    // Broadcast spatial impulse to neighboring tiles
    widget.impulseNotifier?.value = TileImpulse(
      tileId: widget.tile.id,
      row: widget.row,
      col: widget.col,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  void _handleTapUp([TapUpDetails? _]) {
    _animController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final tile = widget.tile;
    final colors = widget.colors;
    final font = widget.font;

    final bgColor = tile.isActive ? colors.activePill : colors.inactivePill;
    final fgColor = tile.isActive ? colors.onActivePill : colors.onInactivePill;

    final tileWidget = AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _neighborScaleAnimation]),
      builder: (context, child) {
        final totalScale = _scaleAnimation.value * _neighborScaleAnimation.value;
        return Transform.scale(
          scale: totalScale,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: widget.onInnerButtonTap == null ? _handleTapDown : null,
        onTapUp: widget.onInnerButtonTap == null ? _handleTapUp : null,
        onTapCancel: widget.onInnerButtonTap == null ? _handleTapCancel : null,
        onLongPress: widget.onLongPress,
        child: tile.isWide
            ? _buildWidePill(tile, bgColor, fgColor, colors, font)
            : _buildSquircleTile(tile, bgColor, fgColor, colors),
      ),
    );

    if (!widget.isSelected || !widget.isEditing) {
      return tileWidget;
    }

    // When selected in Edit Mode: render with prominent white border and attached draggable resize handle
    return Stack(
      clipBehavior: Clip.none,
      children: [
        tileWidget,
        // Attached vertical draggable resize handle pill on right edge
        Positioned(
          right: -10,
          top: 0,
          bottom: 0,
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) {
                _dragAccumulator = 0.0;
                HapticFeedback.selectionClick();
              },
              onVerticalDragUpdate: (details) {
                _dragAccumulator += details.delta.dy;
                if (_dragAccumulator.abs() > 32) {
                  HapticFeedback.mediumImpact();
                  widget.onResizeTap?.call();
                  _dragAccumulator = 0.0;
                }
              },
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onResizeTap?.call();
              },
              child: Container(
                width: 18,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    size: 15,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWidePill(
    QsTileModel tile,
    Color bgColor,
    Color fgColor,
    ExpressiveThemeColors colors,
    FontConfig font,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.fastOutSlowIn,
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(34),
        border: widget.isEditing && widget.isSelected
            ? Border.all(color: Colors.white, width: 2.2)
            : Border.all(color: Colors.transparent, width: 2.2),
      ),
      child: Row(
        children: [
          // Inner Button: bigger (48x48) & more squared off (borderRadius: 16) than outer pill
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _handleTapDown(),
            onTapUp: (_) {
              _animController.reverse();
              if (widget.onInnerButtonTap != null) {
                widget.onInnerButtonTap!();
              } else {
                widget.onTap();
              }
            },
            onTapCancel: _handleTapCancel,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tile.isActive
                    ? fgColor.withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16), // More squared off than outer capsule
              ),
              child: Center(
                child: Icon(
                  tile.icon,
                  size: 22,
                  color: fgColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Titles & Pill Body: tapping outside the inner button
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _handleTapDown(),
              onTapUp: (_) {
                _animController.reverse();
                if (widget.onOuterPillTap != null) {
                  widget.onOuterPillTap!();
                } else {
                  widget.onTap();
                }
              },
              onTapCancel: _handleTapCancel,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 260),
                    style: font.textStyleBuilder(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: fgColor,
                    ),
                    child: Text(
                      tile.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (tile.subtitle != null) ...[
                    const SizedBox(height: 2),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 260),
                      style: font.textStyleBuilder(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: fgColor.withValues(alpha: 0.75),
                      ),
                      child: Text(
                        tile.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Size indicator in Edit Mode or Detail Chevron
          if (widget.isEditing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: fgColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '1x2',
                style: font.textStyleBuilder(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w700,
                  color: fgColor.withValues(alpha: 0.8),
                ),
              ),
            )
          else if (tile.hasDetails)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _handleTapDown(),
              onTapUp: (_) {
                _animController.reverse();
                if (widget.onOuterPillTap != null) {
                  widget.onOuterPillTap!();
                } else {
                  widget.onTap();
                }
              },
              onTapCancel: _handleTapCancel,
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: fgColor.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSquircleTile(
    QsTileModel tile,
    Color bgColor,
    Color fgColor,
    ExpressiveThemeColors colors,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.fastOutSlowIn,
      height: 68,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: widget.isEditing && widget.isSelected
            ? Border.all(color: Colors.white, width: 2.2)
            : Border.all(color: Colors.transparent, width: 2.2),
      ),
      child: Center(
        child: Icon(
          tile.icon,
          size: 26,
          color: fgColor,
        ),
      ),
    );
  }
}
