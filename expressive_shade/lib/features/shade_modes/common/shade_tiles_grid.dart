import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../models/qs_tile_model.dart';
import '../../../../theme/m3_expressive_theme.dart';

int rowSpan(List<QsTileModel> row) {
  return row.fold(0, (sum, t) => sum + (t.isWide ? 2 : 1));
}

List<List<QsTileModel>> packTilesIntoRows(List<QsTileModel> tiles, {int maxSpan = 4}) {
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

List<List<QsTileModel>> packTilesInto3ColRows(List<QsTileModel> tiles) {
  final List<List<QsTileModel>> rows = [];
  for (int i = 0; i < tiles.length; i += 3) {
    final end = (i + 3 < tiles.length) ? i + 3 : tiles.length;
    rows.add(tiles.sublist(i, end));
  }
  return rows;
}

class PaginatedTilesContainer extends StatefulWidget {
  final ExpressiveThemeColors colors;
  final List<List<List<QsTileModel>>> pages;
  final Widget Function(BuildContext context, int pageIndex) builder;
  final double fixedHeight;

  const PaginatedTilesContainer({
    super.key,
    required this.colors,
    required this.pages,
    required this.builder,
    this.fixedHeight = (5 * 68.0) + (4 * 12.0),
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
    if (widget.pages.length > 1) {
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
    if (_currentPage >= widget.pages.length) {
      _currentPage = (widget.pages.length - 1).clamp(0, widget.pages.length);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }
    }
    if (widget.pages.length != oldWidget.pages.length &&
        widget.pages.length > 1) {
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
    final showIndicator = widget.pages.length > 1;

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
              itemCount: widget.pages.length,
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
              children: List.generate(widget.pages.length, (index) {
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
