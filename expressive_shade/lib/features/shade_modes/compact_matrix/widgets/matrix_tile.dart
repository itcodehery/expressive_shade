import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/qs_tile_model.dart';
import '../../../../theme/m3_expressive_theme.dart';
import '../../../../widgets/expressive_pill.dart';

class MatrixTile extends StatefulWidget {
  final QsTileModel tile;
  final ExpressiveThemeColors colors;
  final int row;
  final int col;
  final ValueNotifier<TileImpulse?>? impulseNotifier;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const MatrixTile({
    super.key,
    required this.tile,
    required this.colors,
    required this.row,
    required this.col,
    required this.impulseNotifier,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<MatrixTile> createState() => _MatrixTileState();
}

class _MatrixTileState extends State<MatrixTile>
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
        curve: Curves.easeOutQuad,
        reverseCurve: Curves.easeOutBack,
      ),
    );
    _pressWidthAnim = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOutQuad,
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
  void didUpdateWidget(covariant MatrixTile oldWidget) {
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

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pressHeightAnim,
          _pressWidthAnim,
          _neighborHeightAnim,
          _neighborWidthAnim,
        ]),
        builder: (context, child) {
          final hSquish = _pressHeightAnim.value + _neighborHeightAnim.value;
          final wSquish = _pressWidthAnim.value + _neighborWidthAnim.value;
          final scaleY = (1.0 - (hSquish / 58.0)).clamp(0.85, 1.0);
          final scaleX = (1.0 - (wSquish / 80.0)).clamp(0.85, 1.0);

          return SizedBox(
            height: 58.0,
            child: Transform.scale(
              scaleX: scaleX,
              scaleY: scaleY,
              child: child,
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
    ),
  );
}
}
