import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/font_config.dart';
import '../../../../models/qs_tile_model.dart';
import '../../../../theme/m3_expressive_theme.dart';

class MatrixEditGrid extends StatelessWidget {
  final List<QsTileModel> tiles;
  final String? selectedTileId;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(String id) onTileTap;
  final void Function(QsTileModel tile) onAddTile;
  final void Function(String id) onRemoveTile;
  final VoidCallback onDone;

  const MatrixEditGrid({
    super.key,
    required this.tiles,
    this.selectedTileId,
    required this.colors,
    required this.font,
    required this.onReorder,
    required this.onTileTap,
    required this.onAddTile,
    required this.onRemoveTile,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
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
              onTap: onDone,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          child: _buildMatrixGrid(),
        ),
        const SizedBox(height: 24),

        // Available Tiles Section
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

        _buildAvailableTiles(),
      ],
    );
  }

  Widget _buildMatrixGrid() {
    if (tiles.isEmpty) {
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

    final List<List<QsTileModel>> rows = [];
    for (int i = 0; i < tiles.length; i += 3) {
      final end = (i + 3 < tiles.length) ? i + 3 : tiles.length;
      rows.add(tiles.sublist(i, end));
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
                      ? _buildEditTileItem(rows[r][c])
                      : const SizedBox(height: 64),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildEditTileItem(QsTileModel tile) {
    final isSelected = selectedTileId == tile.id;

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
                color: tile.isActive ? colors.onActivePill : colors.textPrimary,
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.drag_indicator_rounded,
                size: 14,
                color: (tile.isActive ? colors.onActivePill : colors.textSecondary)
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
              color: tile.isActive ? colors.onActivePill : colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    return DragTarget<QsTileModel>(
      onWillAcceptWithDetails: (details) => details.data.id != tile.id,
      onAcceptWithDetails: (details) {
        final incoming = details.data;
        final oldIdx = tiles.indexWhere((t) => t.id == incoming.id);
        final newIdx = tiles.indexWhere((t) => t.id == tile.id);
        if (oldIdx != -1 && newIdx != -1) {
          HapticFeedback.mediumImpact();
          onReorder(oldIdx, newIdx);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return LongPressDraggable<QsTileModel>(
          data: tile,
          delay: const Duration(milliseconds: 140),
          onDragStarted: () {
            HapticFeedback.heavyImpact();
            onTileTap(tile.id);
          },
          feedback: Material(
            color: Colors.transparent,
            elevation: 10,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 100,
              height: 64,
              child: Opacity(
                opacity: 0.90,
                child: tileBox,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.25,
            child: tileBox,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: isHovered
                ? Matrix4.diagonal3Values(1.05, 1.05, 1.0)
                : Matrix4.identity(),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onTileTap(tile.id);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  tileBox,
                  // Remove tile button (minus badge)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onRemoveTile(tile.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.inactivePill,
                            width: 1.0,
                          ),
                        ),
                        child: Icon(
                          Icons.remove_rounded,
                          size: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvailableTiles() {
    final available = QsTileModel.defaultTiles
        .where((t) => !tiles.any((at) => at.id == t.id))
        .toList();

    if (available.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            'All available tiles are added to the matrix',
            style: font.textStyleBuilder(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: available.map((tile) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onAddTile(tile);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.inactivePill.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tile.icon, size: 16, color: colors.textPrimary),
                const SizedBox(width: 8),
                Text(
                  tile.title,
                  style: font.textStyleBuilder(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.add_rounded, size: 16, color: colors.activePill),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
