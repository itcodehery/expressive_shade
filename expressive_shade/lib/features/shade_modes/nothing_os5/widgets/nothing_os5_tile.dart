import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/font_config.dart';
import '../../../../models/qs_tile_model.dart';
import '../../../../theme/m3_expressive_theme.dart';

class NothingOs5Tile extends StatefulWidget {
  final QsTileModel tile;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onResizeTap;
  final bool isEditing;
  final bool isSelected;

  const NothingOs5Tile({
    super.key,
    required this.tile,
    required this.colors,
    required this.font,
    required this.onTap,
    this.onLongPress,
    this.onResizeTap,
    this.isEditing = false,
    this.isSelected = false,
  });

  @override
  State<NothingOs5Tile> createState() => _NothingOs5TileState();
}

class _NothingOs5TileState extends State<NothingOs5Tile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 75),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOutQuad,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _pressController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails _) {
    _pressController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final tile = widget.tile;
    final size = tile.tileSize;

    final Widget coreTile = ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onLongPress: widget.onLongPress,
        child: switch (size) {
          TileSize.size1x1 => _build1x1Circle(tile),
          TileSize.size1x2 => _build1x2Pill(tile),
          TileSize.size2x2 => _build2x2BentoSquare(tile),
        },
      ),
    );

    if (!widget.isEditing) {
      return coreTile;
    }

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        coreTile,
        if (widget.isSelected)
          Positioned(
            right: -4,
            bottom: -4,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onResizeTap?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.colors.textPrimary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.open_in_full_rounded,
                      size: 11,
                      color: widget.colors.background,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      size.label,
                      style: widget.font.textStyleBuilder(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: widget.colors.background,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 1x1 Circular/Capsule Tile (NothingOS 5 signature round icon button)
  Widget _build1x1Circle(QsTileModel tile) {
    final colors = widget.colors;
    final isActive = tile.isActive;
    final bgColor = isActive ? colors.activePill : colors.inactivePill;
    final fgColor = isActive ? colors.onActivePill : colors.onInactivePill;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: widget.isEditing && widget.isSelected
            ? Border.all(color: colors.textPrimary, width: 2.2)
            : null,
      ),
      child: Center(
        child: Icon(
          tile.icon,
          size: 22,
          color: fgColor,
        ),
      ),
    );
  }

  /// 1x2 Horizontal Stadium Pill (NothingOS 5 Wi-Fi / Bluetooth / Modes style)
  Widget _build1x2Pill(QsTileModel tile) {
    final colors = widget.colors;
    final font = widget.font;
    final isActive = tile.isActive;

    final bgColor = isActive
        ? colors.activePill
        : colors.inactivePill.withValues(alpha: 0.72);
    final fgColor = isActive ? colors.onActivePill : colors.onInactivePill;
    final subColor = isActive
        ? colors.onActivePill.withValues(alpha: 0.72)
        : colors.onInactivePill.withValues(alpha: 0.65);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: isActive ? 14 : 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: widget.isEditing && widget.isSelected
            ? Border.all(color: colors.textPrimary, width: 2.2)
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final badgeSize = (constraints.maxHeight - 4).clamp(26.0, 42.0);
          return Row(
            children: [
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    tile.icon,
                    size: 21,
                    color: fgColor,
                  ),
                )
              else
                Container(
                  width: badgeSize,
                  height: badgeSize,
                  margin: const EdgeInsets.only(right: 9),
                  decoration: BoxDecoration(
                    color: colors.isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.08),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      tile.icon,
                      size: (badgeSize * 0.48).clamp(15.0, 20.0),
                      color: fgColor,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        tile.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: font.textStyleBuilder(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: fgColor,
                        ),
                      ),
                    ),
                    if (tile.subtitle != null &&
                        tile.subtitle!.isNotEmpty &&
                        constraints.maxHeight >= 36 &&
                        (isActive || tile.id != 'modes')) ...[
                      const SizedBox(height: 1),
                      Flexible(
                        child: Text(
                          tile.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: font.textStyleBuilder(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w400,
                            color: subColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 2x2 Large Bento Square Tile (NEW in NothingOS 5)
  Widget _build2x2BentoSquare(QsTileModel tile) {
    final colors = widget.colors;
    final font = widget.font;
    final isActive = tile.isActive;

    final bgColor = isActive ? colors.activePill : colors.inactivePill;
    final fgColor = isActive ? colors.onActivePill : colors.onInactivePill;
    final subColor = isActive
        ? colors.onActivePill.withValues(alpha: 0.75)
        : colors.onInactivePill.withValues(alpha: 0.65);

    final badgeBg = isActive
        ? colors.onActivePill.withValues(alpha: 0.14)
        : (colors.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.07));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        border: widget.isEditing && widget.isSelected
            ? Border.all(color: colors.textPrimary, width: 2.2)
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxH = constraints.maxHeight;
          final badgeSize = (maxH * 0.36).clamp(24.0, 42.0);
          final showTextBlock = maxH >= 54.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: showTextBlock
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.center,
            children: [
              // Top row: Circular icon badge + NothingOS dot-matrix status cluster
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: badgeSize,
                    height: badgeSize,
                    decoration: BoxDecoration(
                      color: badgeBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        tile.icon,
                        size: (badgeSize * 0.52).clamp(15.0, 22.0),
                        color: fgColor,
                      ),
                    ),
                  ),
                  if (constraints.maxWidth >= 68)
                    _buildNothingDotMatrixGlyph(isActive, fgColor),
                ],
              ),

              // Bottom area: Title + Subtitle (overflow-safe during resize animations)
              if (showTextBlock)
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          tile.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: font.textStyleBuilder(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            color: fgColor,
                          ),
                        ),
                      ),
                      if (maxH >= 82.0) ...[
                        const SizedBox(height: 1),
                        Flexible(
                          child: Text(
                            tile.subtitle ?? (isActive ? 'Active' : 'Off'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: font.textStyleBuilder(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: subColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// NothingOS signature 3x3 dot-matrix status glyph indicator
  Widget _buildNothingDotMatrixGlyph(bool isActive, Color fgColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 2),
      child: SizedBox(
        width: 18,
        height: 18,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (r) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(3, (c) {
                final isLit = isActive
                    ? (r == 1 || c == 1) // Plus/diamond pattern when active
                    : (r == 1 && c == 1); // Single center dot when off
                return Container(
                  width: 3.5,
                  height: 3.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fgColor.withValues(alpha: isLit ? 0.85 : 0.22),
                  ),
                );
              }),
            );
          }),
        ),
      ),
    );
  }
}
