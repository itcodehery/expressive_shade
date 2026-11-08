import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../models/qs_tile_model.dart';
import '../../../../theme/m3_expressive_theme.dart';

int rowSpan(List<QsTileModel> row) {
  return row.fold(0, (sum, t) => sum + (t.isWide ? 2 : 1));
}

class StandardBentoPlacement {
  final QsTileModel tile;
  final int row;
  final int col;
  final int rowSpan;
  final int colSpan;

  const StandardBentoPlacement({
    required this.tile,
    required this.row,
    required this.col,
    required this.rowSpan,
    required this.colSpan,
  });
}

class StandardBentoPage {
  final List<StandardBentoPlacement> placements;
  final int totalRows;

  const StandardBentoPage({
    required this.placements,
    required this.totalRows,
  });
}

/// Packs 1x1, 1x2, and 2x2 tiles into 4-column, 2D Bento pages (up to [maxRowsPerPage] rows per page)
/// so 2x2 tiles sit cleanly across 2 rows alongside 1x1/1x2 tiles without overflowing row height.
List<StandardBentoPage> packTilesIntoBentoPages(
  List<QsTileModel> rawTiles, {
  int maxCols = 4,
  int maxRowsPerPage = 5,
  bool avoidSpanningCollapsedBoundary = false,
}) {
  final tiles = rawTiles.where((t) => !t.isNothingOsSystemControl).toList();
  if (tiles.isEmpty) return const [];

  final List<List<List<bool>>> pageGrids = [];
  final List<List<StandardBentoPlacement>> pagePlacements = [];

  void addNewPage() {
    pageGrids.add(
      List.generate(maxRowsPerPage, (_) => List<bool>.filled(maxCols, false)),
    );
    pagePlacements.add([]);
  }

  bool canFitInPage(
    List<List<bool>> grid,
    int r,
    int c,
    int rSpan,
    int cSpan,
  ) {
    if (r + rSpan > maxRowsPerPage || c + cSpan > maxCols) return false;
    // In Unified Shade, collapsed view shows rows 0..1. Avoid starting a 2x2 tile at row 1.
    if (avoidSpanningCollapsedBoundary && r == 1 && rSpan > 1) return false;
    for (int dr = 0; dr < rSpan; dr++) {
      for (int dc = 0; dc < cSpan; dc++) {
        if (grid[r + dr][c + dc]) return false;
      }
    }
    return true;
  }

  void markInPage(
    List<List<bool>> grid,
    int r,
    int c,
    int rSpan,
    int cSpan,
  ) {
    for (int dr = 0; dr < rSpan; dr++) {
      for (int dc = 0; dc < cSpan; dc++) {
        grid[r + dr][c + dc] = true;
      }
    }
  }

  for (final tile in tiles) {
    final rSpan = tile.tileSize.rowSpan;
    final cSpan = tile.tileSize.colSpan;
    bool placed = false;

    for (int p = 0; p < pageGrids.length && !placed; p++) {
      final grid = pageGrids[p];
      for (int r = 0; r <= maxRowsPerPage - rSpan && !placed; r++) {
        for (int c = 0; c <= maxCols - cSpan; c++) {
          if (canFitInPage(grid, r, c, rSpan, cSpan)) {
            markInPage(grid, r, c, rSpan, cSpan);
            pagePlacements[p].add(
              StandardBentoPlacement(
                tile: tile,
                row: r,
                col: c,
                rowSpan: rSpan,
                colSpan: cSpan,
              ),
            );
            placed = true;
            break;
          }
        }
      }
    }

    if (!placed) {
      addNewPage();
      final p = pageGrids.length - 1;
      markInPage(pageGrids[p], 0, 0, rSpan, cSpan);
      pagePlacements[p].add(
        StandardBentoPlacement(
          tile: tile,
          row: 0,
          col: 0,
          rowSpan: rSpan,
          colSpan: cSpan,
        ),
      );
    }
  }

  final List<StandardBentoPage> result = [];
  for (final placements in pagePlacements) {
    int maxRow = 0;
    for (final pl in placements) {
      final endRow = pl.row + pl.rowSpan;
      if (endRow > maxRow) maxRow = endRow;
    }
    result.add(StandardBentoPage(placements: placements, totalRows: maxRow));
  }
  return result;
}

List<List<QsTileModel>> packTilesIntoRows(List<QsTileModel> rawTiles, {int maxSpan = 4}) {
  final tiles = rawTiles.where((t) => !t.isNothingOsSystemControl).toList();
  final List<List<QsTileModel>> rows = [];
  List<QsTileModel> currentRow = [];
  int currentSpan = 0;

  for (final tile in tiles) {
    final span = tile.isWide ? 2 : 1;
    if (currentSpan + span > maxSpan) {
      if (currentRow.isNotEmpty) {
        rows.add(currentRow);
      }
      currentRow = [tile];
      currentSpan = span;
    } else {
      currentRow.add(tile);
      currentSpan += span;
    }
  }
  if (currentRow.isNotEmpty) {
    rows.add(currentRow);
  }
  return rows;
}

List<List<QsTileModel>> packTilesInto3ColRows(List<QsTileModel> rawTiles) {
  final tiles = rawTiles.where((t) => !t.isNothingOsSystemControl).toList();
  final List<List<QsTileModel>> rows = [];
  for (int i = 0; i < tiles.length; i += 3) {
    final end = (i + 3 < tiles.length) ? i + 3 : tiles.length;
    rows.add(tiles.sublist(i, end));
  }
  return rows;
}

class PaginatedTilesContainer extends StatefulWidget {
  final ExpressiveThemeColors colors;
  final int pageCount;
  final Widget Function(BuildContext context, int pageIndex) builder;
  final double fixedHeight;

  const PaginatedTilesContainer({
    super.key,
    required this.colors,
    required this.pageCount,
    required this.builder,
    this.fixedHeight = (5 * 68.0) + (4 * 12.0) + 2.0,
  });

  @override
  State<PaginatedTilesContainer> createState() => _PaginatedTilesContainerState();
}

class _PaginatedTilesContainerState extends State<PaginatedTilesContainer> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isIndicatorVisible = false;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.pageCount > 1) {
      _showIndicatorBriefly();
    }
  }

  void _showIndicatorBriefly([
    Duration duration = const Duration(milliseconds: 1800),
  ]) {
    _fadeTimer?.cancel();
    if (mounted && !_isIndicatorVisible) {
      setState(() => _isIndicatorVisible = true);
    }
    _fadeTimer = Timer(duration, () {
      if (mounted && _isIndicatorVisible) {
        setState(() => _isIndicatorVisible = false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant PaginatedTilesContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage >= widget.pageCount) {
      _currentPage = (widget.pageCount - 1).clamp(0, widget.pageCount);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }
    }
    if (widget.pageCount != oldWidget.pageCount &&
        widget.pageCount > 1) {
      _showIndicatorBriefly();
    }
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showIndicator = widget.pageCount > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.fixedHeight,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification ||
                  notification is ScrollUpdateNotification) {
                _fadeTimer?.cancel();
                if (!_isIndicatorVisible) {
                  setState(() => _isIndicatorVisible = true);
                }
              } else if (notification is ScrollEndNotification) {
                _showIndicatorBriefly();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.pageCount,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
                _showIndicatorBriefly();
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: widget.builder(context, index),
                  ),
                );
              },
            ),
          ),
        ),
        if (showIndicator) ...[
          const SizedBox(height: 12),
          // Material 3 Expressive Pill Dots Indicator (fades out when inactive)
          AnimatedOpacity(
            opacity: _isIndicatorVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.pageCount, (index) {
                final isSelected = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.colors.activePill
                        : widget.colors.inactivePill,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }
}
