import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../theme/m3_expressive_theme.dart';

class UnifiedPaginatedTilesContainer extends StatefulWidget {
  final ExpressiveThemeColors colors;
  final int pageCount;
  final int maxRows;
  final Animation<double> bouncyAnimation;
  final Widget Function(BuildContext context, int pageIndex) builder;

  const UnifiedPaginatedTilesContainer({
    super.key,
    required this.colors,
    required this.pageCount,
    required this.maxRows,
    required this.bouncyAnimation,
    required this.builder,
  });

  @override
  State<UnifiedPaginatedTilesContainer> createState() =>
      _UnifiedPaginatedTilesContainerState();
}

class _UnifiedPaginatedTilesContainerState
    extends State<UnifiedPaginatedTilesContainer> {
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
  void didUpdateWidget(covariant UnifiedPaginatedTilesContainer oldWidget) {
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
    final maxRows = widget.maxRows.clamp(2, 5);

    const double collapsedHeight = (2 * 68.0) + (1 * 12.0); // 148.0
    final double expandedHeight =
        (maxRows * 68.0) + ((maxRows - 1) * 12.0) + 2.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: widget.bouncyAnimation,
          builder: (context, child) {
            final currentHeight = collapsedHeight +
                (expandedHeight - collapsedHeight) *
                    widget.bouncyAnimation.value;

            return SizedBox(
              height: currentHeight,
              child: ClipRect(
                child: child,
              ),
            );
          },
          child: SizedBox(
            height: expandedHeight,
            child: RepaintBoundary(
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
                  physics: const BouncingScrollPhysics(),
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
