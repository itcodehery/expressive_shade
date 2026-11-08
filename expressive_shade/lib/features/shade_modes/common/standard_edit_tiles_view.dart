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
  final void Function(String id, TileSize size)? onSetExactSize;
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
    this.onSetExactSize,
    required this.onAddTile,
    required this.onReorder,
    this.impulseNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final visibleTiles =
        tiles.where((t) => !t.isNothingOsSystemControl).toList();
    final selectedTile = selectedTileId != null
        ? visibleTiles.where((t) => t.id == selectedTileId).firstOrNull
        : visibleTiles.firstOrNull;

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
          'Select tiles to rearrange and resize (1×1, 1×2)',
          style: font.textStyleBuilder(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),

        if (selectedTile != null && onSetExactSize != null) ...[
          _buildSizeSelectorBar(selectedTile),
          const SizedBox(height: 14),
        ],

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

  Widget _buildSizeSelectorBar(QsTileModel tile) {
    final currentSize = tile.tileSize;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.activePill.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(tile.icon, size: 20, color: colors.activePill),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tile.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: font.textStyleBuilder(
                fontSize: 14.0,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [TileSize.size1x1, TileSize.size1x2].map((size) {
              final isSelected = currentSize == size;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSetExactSize?.call(tile.id, size);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.activePill
                          : colors.inactivePill.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      size.label,
                      style: font.textStyleBuilder(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? colors.onActivePill
                            : colors.onInactivePill,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicTilesGrid() {
    final pages = packTilesIntoBentoPages(tiles, maxCols: 4, maxRowsPerPage: 5);
    if (pages.isEmpty) return const SizedBox.shrink();

    if (pages.length == 1) {
      return _buildBentoTilesPage(pages.first, 0);
    }

    const double fixedHeight = (5 * 68.0) + (4 * 12.0) + 2.0;

    return PaginatedTilesContainer(
      colors: colors,
      pageCount: pages.length,
      fixedHeight: fixedHeight,
      builder: (context, pageIndex) {
        return _buildBentoTilesPage(pages[pageIndex], pageIndex * 5);
      },
    );
  }

  Widget _buildBentoTilesPage(StandardBentoPage page, int baseRowIndex) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double colSpacing = 10.0;
        const double rowSpacing = 12.0;
        const double rowHeight = 68.0;
        final double maxW = constraints.maxWidth;
        final double cellWidth = (maxW - (3 * colSpacing)) / 4.0;
        final int rowsCount = page.totalRows.clamp(1, 5);
        final double totalH =
            (rowsCount * rowHeight) + ((rowsCount - 1) * rowSpacing);

        return SizedBox(
          width: maxW,
          height: totalH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final p in page.placements)
                Positioned(
                  key: ValueKey('edit_std_${p.tile.id}'),
                  left: p.col * (cellWidth + colSpacing),
                  top: p.row * (rowHeight + rowSpacing),
                  width: (p.colSpan * cellWidth) +
                      ((p.colSpan - 1) * colSpacing),
                  height: (p.rowSpan * rowHeight) +
                      ((p.rowSpan - 1) * rowSpacing),
                  child: _buildTileItemWithReorder(
                    tile: p.tile,
                    row: baseRowIndex + p.row,
                    col: p.col,
                  ),
                ),
            ],
          ),
        );
      },
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
          foregroundDecoration: isHovered
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(tile.isWide ? 34 : 24),
                  border: Border.all(color: colors.activePill, width: 2.0),
                )
              : null,
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
        .where((t) => !t.isNothingOsSystemControl && t.category == category)
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
