import '../../../models/qs_tile_model.dart';

enum BentoItemType {
  tile,
  volumeSlider,
  brightnessSlider,
  ringerPill,
}

class BentoPlacement {
  final BentoItemType type;
  final QsTileModel? tile;
  final int row;
  final int col;
  final int rowSpan;
  final int colSpan;

  const BentoPlacement({
    required this.type,
    this.tile,
    required this.row,
    required this.col,
    required this.rowSpan,
    required this.colSpan,
  });
}

class BentoGridPackResult {
  final List<BentoPlacement> placements;
  final int totalRows;

  const BentoGridPackResult({
    required this.placements,
    required this.totalRows,
  });
}

/// Packs 1x1, 1x2, and 2x2 tiles plus movable NothingOS 5 system controls
/// (`nothing_volume` [2x1], `nothing_brightness` [2x1], `nothing_ringer` [1x2])
/// into a 4-column 2D Bento Grid.
BentoGridPackResult packNothingOs5BentoGrid(
  List<QsTileModel> tiles, {
  bool includeSystemControls = true,
  int maxCols = 4,
}) {
  final Map<int, List<bool>> occupied = {};

  bool isCellOccupied(int r, int c) {
    final rowList = occupied[r];
    if (rowList == null) return false;
    return rowList[c];
  }

  void markOccupied(int r, int c, int rowSpan, int colSpan) {
    for (int dr = 0; dr < rowSpan; dr++) {
      final rowList =
          occupied.putIfAbsent(r + dr, () => List<bool>.filled(maxCols, false));
      for (int dc = 0; dc < colSpan; dc++) {
        rowList[c + dc] = true;
      }
    }
  }

  bool canFit(int r, int c, int rowSpan, int colSpan) {
    if (c + colSpan > maxCols) return false;
    for (int dr = 0; dr < rowSpan; dr++) {
      for (int dc = 0; dc < colSpan; dc++) {
        if (isCellOccupied(r + dr, c + dc)) return false;
      }
    }
    return true;
  }

  final List<BentoPlacement> placements = [];
  final effectiveTiles = includeSystemControls
      ? QsTileModel.ensureNothingOsControls(tiles)
      : tiles.where((t) => !t.isNothingOsSystemControl).toList();

  for (final tile in effectiveTiles) {
    final rSpan = tile.bentoRowSpan;
    final cSpan = tile.bentoColSpan;

    int targetRow = 0;
    int targetCol = 0;
    bool placed = false;

    while (!placed) {
      for (int c = 0; c <= maxCols - cSpan; c++) {
        if (canFit(targetRow, c, rSpan, cSpan)) {
          targetCol = c;
          placed = true;
          break;
        }
      }
      if (!placed) {
        targetRow++;
      }
    }

    markOccupied(targetRow, targetCol, rSpan, cSpan);
    final itemType = switch (tile.id) {
      'nothing_volume' => BentoItemType.volumeSlider,
      'nothing_brightness' => BentoItemType.brightnessSlider,
      'nothing_ringer' => BentoItemType.ringerPill,
      _ => BentoItemType.tile,
    };

    placements.add(
      BentoPlacement(
        type: itemType,
        tile: tile,
        row: targetRow,
        col: targetCol,
        rowSpan: rSpan,
        colSpan: cSpan,
      ),
    );
  }

  int maxRow = 0;
  for (final p in placements) {
    final endRow = p.row + p.rowSpan;
    if (endRow > maxRow) {
      maxRow = endRow;
    }
  }

  return BentoGridPackResult(
    placements: placements,
    totalRows: maxRow,
  );
}
