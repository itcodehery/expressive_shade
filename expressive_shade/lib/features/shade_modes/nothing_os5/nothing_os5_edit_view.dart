import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/font_config.dart';
import '../../../models/qs_tile_model.dart';
import '../../../theme/m3_expressive_theme.dart';
import 'bento_grid_packer.dart';
import 'widgets/nothing_os5_sliders.dart';
import 'widgets/nothing_os5_tile.dart';

class NothingOs5EditView extends StatelessWidget {
  final List<QsTileModel> tiles;
  final String? selectedTileId;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final double brightness;
  final double volume;
  final int ringerMode;
  final void Function(String id) onTileTap;
  final void Function(String id) onCycleSizeTap;
  final void Function(String id, TileSize size) onSetExactSize;
  final void Function(QsTileModel tile) onAddTile;
  final void Function(String id) onRemoveTile;
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onReset;
  final VoidCallback onDone;
  final VoidCallback? onOpenApp;

  const NothingOs5EditView({
    super.key,
    required this.tiles,
    this.selectedTileId,
    required this.colors,
    required this.font,
    this.brightness = 0.65,
    this.volume = 0.50,
    this.ringerMode = 2,
    required this.onTileTap,
    required this.onCycleSizeTap,
    required this.onSetExactSize,
    required this.onAddTile,
    required this.onRemoveTile,
    required this.onReorder,
    required this.onReset,
    required this.onDone,
    this.onOpenApp,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final selectedTile = selectedTileId != null
        ? tiles.where((t) => t.id == selectedTileId).firstOrNull
        : tiles.firstOrNull;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        18,
        topPadding > 0 ? topPadding + 8 : 16,
        18,
        36,
      ),
      children: [
        // 1. Top Edit Header Row
        Row(
          children: [
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onDone();
              },
              icon: Icon(
                Icons.arrow_back_rounded,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NothingOS 5 Bento',
                    style: font.textStyleBuilder(
                      fontSize: 19.0,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    'Tap a tile to resize (1×1, 1×2, 2×2) or drag to reorder',
                    style: font.textStyleBuilder(
                      fontSize: 11.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onOpenApp != null) ...[
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onOpenApp!();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colors.textPrimary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: colors.activePill,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Shade App',
                        style: font.textStyleBuilder(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 2),
            ],
            IconButton(
              tooltip: 'Reset tiles',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                HapticFeedback.mediumImpact();
                onReset();
              },
              icon: Icon(
                Icons.replay_rounded,
                color: colors.textPrimary,
                size: 21,
              ),
            ),
            if (selectedTile != null &&
                !selectedTile.isNothingOsSystemControl &&
                tiles.length > 1) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onRemoveTile(selectedTile.id);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'Remove',
                    style: font.textStyleBuilder(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),

        // 2. Selected Tile Size Selector Bar (1x1 | 1x2 | 2x2)
        if (selectedTile != null) ...[
          _buildSizeSelectorCard(selectedTile),
          const SizedBox(height: 16),
        ],

        // 3. Active Bento Grid Container
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: colors.textPrimary.withValues(alpha: 0.22),
              width: 1.4,
            ),
          ),
          child: _buildEditableBentoGrid(selectedTile?.id),
        ),
        const SizedBox(height: 28),

        // 4. Categorized Available Tiles Catalog
        for (final category in TileCategory.values) ...[
          _buildCategorySection(category),
          const SizedBox(height: 22),
        ],
      ],
    );
  }

  Widget _buildSizeSelectorCard(QsTileModel tile) {
    if (tile.isNothingOsSystemControl) {
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
            Icon(
              tile.icon,
              size: 20,
              color: colors.activePill,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tile.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: font.textStyleBuilder(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    'System Control (${tile.bentoRowSpan}×${tile.bentoColSpan}) • Drag to move anywhere',
                    style: font.textStyleBuilder(
                      fontSize: 11.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

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
          Icon(
            tile.icon,
            size: 20,
            color: colors.activePill,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tile.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: font.textStyleBuilder(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  'Tile dimension',
                  style: font.textStyleBuilder(
                    fontSize: 11.5,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Segmented 1x1 | 1x2 | 2x2 buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: TileSize.values.map((size) {
              final isSelected = currentSize == size;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSetExactSize(tile.id, size);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
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
                        fontSize: 12.5,
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

  Widget _buildEditableBentoGrid(String? activeSelectedId) {
    final packed = packNothingOs5BentoGrid(
      tiles,
      includeSystemControls: true,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 11.0;
        final double maxW = constraints.maxWidth;
        final double cellWidth = ((maxW - (3 * spacing)) / 4.0).clamp(48.0, 100.0);
        final double cellHeight = (cellWidth * 0.80).clamp(42.0, 64.0);
        final double totalHeight = packed.totalRows > 0
            ? (packed.totalRows * cellHeight) + ((packed.totalRows - 1) * spacing)
            : 72.0;

        return SizedBox(
          width: maxW,
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final item in packed.placements)
                if (item.tile != null)
                  AnimatedPositioned(
                    key: ValueKey('edit_bento_${item.tile!.id}'),
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    left: item.col * (cellWidth + spacing),
                    top: item.row * (cellHeight + spacing),
                    width: (item.colSpan * cellWidth) +
                        ((item.colSpan - 1) * spacing),
                    height: (item.rowSpan * cellHeight) +
                        ((item.rowSpan - 1) * spacing),
                    child: _buildDraggableBentoTile(
                      item.tile!,
                      item.tile!.id == activeSelectedId,
                      (item.colSpan * cellWidth) + ((item.colSpan - 1) * spacing),
                      (item.rowSpan * cellHeight) + ((item.rowSpan - 1) * spacing),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditableItemVisual(QsTileModel tile, bool isSelected) {
    switch (tile.id) {
      case 'nothing_volume':
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTileTap(tile.id),
          child: NothingOs5VerticalCapsuleSlider(
            value: volume,
            onChanged: (_) {},
            icon: Icons.music_note_rounded,
            colors: colors,
            isEditing: true,
            isSelected: isSelected,
          ),
        );
      case 'nothing_brightness':
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTileTap(tile.id),
          child: NothingOs5VerticalCapsuleSlider(
            value: brightness,
            onChanged: (_) {},
            icon: Icons.wb_sunny_outlined,
            colors: colors,
            isEditing: true,
            isSelected: isSelected,
          ),
        );
      case 'nothing_ringer':
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTileTap(tile.id),
          child: NothingOs5RingerPill(
            ringerMode: ringerMode,
            onModeChanged: (_) {},
            colors: colors,
            isEditing: true,
            isSelected: isSelected,
          ),
        );
      default:
        return NothingOs5Tile(
          tile: tile,
          colors: colors,
          font: font,
          isEditing: true,
          isSelected: isSelected,
          onTap: () => onTileTap(tile.id),
          onResizeTap: () => onCycleSizeTap(tile.id),
        );
    }
  }

  Widget _buildDraggableBentoTile(
    QsTileModel tile,
    bool isSelected,
    double width,
    double height,
  ) {
    final tileWidget = _buildEditableItemVisual(tile, isSelected);

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
      builder: (context, candidateData, _) {
        return LongPressDraggable<String>(
          data: tile.id,
          delay: const Duration(milliseconds: 160),
          onDragStarted: () {
            HapticFeedback.heavyImpact();
            onTileTap(tile.id);
          },
          feedback: Material(
            color: Colors.transparent,
            elevation: 8,
            child: SizedBox(
              width: width,
              height: height,
              child: _buildEditableItemVisual(tile, true),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.25, child: tileWidget),
          child: tileWidget,
        );
      },
    );
  }

  Widget _buildCategorySection(TileCategory category) {
    final categoryTiles = QsTileModel.allAvailableTiles
        .where((t) => t.category == category && !t.isNothingOsSystemControl)
        .toList();
    if (categoryTiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(category.icon, size: 19, color: colors.textPrimary),
            const SizedBox(width: 8),
            Text(
              category.label,
              style: font.textStyleBuilder(
                fontSize: 16.0,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 14,
            childAspectRatio: 0.78,
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
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isAlreadyActive
                              ? colors.surface.withValues(alpha: 0.35)
                              : colors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            catTile.icon,
                            size: 24,
                            color: isAlreadyActive
                                ? colors.textSecondary.withValues(alpha: 0.35)
                                : colors.textPrimary,
                          ),
                        ),
                      ),
                      if (!isAlreadyActive)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: colors.activePill,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add_rounded,
                                size: 14,
                                color: colors.onActivePill,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    catTile.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: font.textStyleBuilder(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isAlreadyActive
                          ? colors.textSecondary.withValues(alpha: 0.4)
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
