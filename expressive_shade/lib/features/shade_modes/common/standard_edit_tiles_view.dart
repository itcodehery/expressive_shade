import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/font_config.dart';
import '../../../../models/qs_tile_model.dart';
import '../../../../theme/m3_expressive_theme.dart';
import '../../../../widgets/expressive_pill.dart';
import 'shade_tiles_grid.dart';

class StandardEditTilesView extends StatelessWidget {
  final List<QsTileModel> tiles;
  final String? selectedTileId;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final void Function(String id) onTileTap;
  final void Function(String id) onResizeTap;
  final void Function(QsTileModel tile) onAddTile;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueNotifier<TileImpulse?>? impulseNotifier;

  const StandardEditTilesView({
    super.key,
    required this.tiles,
    this.selectedTileId,
    required this.colors,
    required this.font,
    required this.onTileTap,
    required this.onResizeTap,
    required this.onAddTile,
    required this.onReorder,
    this.impulseNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
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

        // Main Active Tiles Container with distinct border
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
          child: _buildDynamicTilesGrid(),
        ),
        const SizedBox(height: 28),

        // Categorized Available Tiles Sections
        for (final category in TileCategory.values) ...[
          _buildCategorySection(category),
          const SizedBox(height: 24),
        ],
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

    const double fixedHeight = (5 * 68.0) + (4 * 12.0);

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
                  child: _buildTileItemWithReorder(
                    tile: rows[r][t],
                    row: baseRowIndex + r,
                    col: t,
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

  Widget _buildTileItemWithReorder({
    required QsTileModel tile,
    required int row,
    required int col,
  }) {
    final pillWidget = ExpressivePill(
      tile: tile,
      colors: colors,
      font: font,
      row: row,
      col: col,
      impulseNotifier: impulseNotifier,
      isEditing: true,
      isSelected: selectedTileId == tile.id,
      onResizeTap: () => onResizeTap(tile.id),
      onTap: () => onTileTap(tile.id),
    );

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != tile.id,
      onAcceptWithDetails: (details) {
        final incomingId = details.data;
        final oldIdx = tiles.indexWhere((t) => t.id == incomingId);
        final newIdx = tiles.indexWhere((t) => t.id == tile.id);
        if (oldIdx != -1 && newIdx != -1) {
          HapticFeedback.mediumImpact();
          onReorder(oldIdx, newIdx);
          onTileTap(incomingId);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tile.isWide ? 34 : 24),
            border: isHovered
                ? Border.all(color: colors.activePill, width: 2.0)
                : Border.all(color: Colors.transparent, width: 2.0),
          ),
          child: LongPressDraggable<String>(
            data: tile.id,
            delay: const Duration(milliseconds: 180),
            onDragStarted: () {
              HapticFeedback.heavyImpact();
              onTileTap(tile.id);
            },
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

  Widget _buildCategorySection(TileCategory category) {
    final categoryTiles = QsTileModel.allAvailableTiles
        .where((t) => t.category == category)
        .toList();
    if (categoryTiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            final isAlreadyActive = tiles.any((t) => t.id == catTile.id);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (!isAlreadyActive) {
                  HapticFeedback.lightImpact();
                  onAddTile(catTile);
                }
                onTileTap(catTile.id);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
}
