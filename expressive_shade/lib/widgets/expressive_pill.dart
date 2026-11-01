import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/font_config.dart';
import '../models/qs_tile_model.dart';
import '../theme/m3_expressive_theme.dart';

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
  });

  @override
  State<ExpressivePill> createState() => _ExpressivePillState();
}

class _ExpressivePillState extends State<ExpressivePill>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  double _dragAccumulator = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 240),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInQuad,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _animController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails _) {
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
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
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
              onHorizontalDragStart: (_) {
                _dragAccumulator = 0.0;
                HapticFeedback.selectionClick();
              },
              onHorizontalDragUpdate: (details) {
                _dragAccumulator += details.delta.dx;
                // If 1x1 and dragged right > 18px -> expand to 1x2!
                if (!tile.isWide && _dragAccumulator > 18) {
                  HapticFeedback.mediumImpact();
                  widget.onResizeTap?.call();
                  _dragAccumulator = -25;
                }
                // If 1x2 and dragged left < -18px -> shrink to 1x1!
                else if (tile.isWide && _dragAccumulator < -18) {
                  HapticFeedback.mediumImpact();
                  widget.onResizeTap?.call();
                  _dragAccumulator = 25;
                }
              },
              onHorizontalDragEnd: (_) {
                _dragAccumulator = 0.0;
              },
              onTap: () {
                HapticFeedback.mediumImpact();
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
        boxShadow: [
          if (tile.isActive)
            BoxShadow(
              color: colors.activePill.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          // Inner Button: bigger (48x48) & more squared off (borderRadius: 16) than outer pill
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              if (widget.onInnerButtonTap != null) {
                widget.onInnerButtonTap!();
              } else {
                widget.onTap();
              }
            },
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
              onTap: () {
                HapticFeedback.lightImpact();
                if (widget.onOuterPillTap != null) {
                  widget.onOuterPillTap!();
                } else {
                  widget.onTap();
                }
              },
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
              onTap: () {
                HapticFeedback.lightImpact();
                if (widget.onOuterPillTap != null) {
                  widget.onOuterPillTap!();
                } else {
                  widget.onTap();
                }
              },
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
        boxShadow: [
          if (tile.isActive)
            BoxShadow(
              color: colors.activePill.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
        ],
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
