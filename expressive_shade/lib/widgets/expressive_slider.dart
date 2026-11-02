import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/slider_style.dart';
import '../theme/m3_expressive_theme.dart';

class ExpressiveSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final IconData leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;
  final ExpressiveThemeColors colors;
  final double height;
  final SliderStyle style;

  const ExpressiveSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.leadingIcon,
    this.trailingIcon,
    this.onTrailingTap,
    required this.colors,
    this.height = 56.0,
    this.style = SliderStyle.separatedBar,
  });

  @override
  State<ExpressiveSlider> createState() => _ExpressiveSliderState();
}

class _ExpressiveSliderState extends State<ExpressiveSlider> {
  bool _isDragging = false;

  void _updateFromPosition(Offset localPos, double width) {
    if (width <= 0) return;
    final newVal = (localPos.dx / width).clamp(0.0, 1.0);
    if ((newVal - widget.value).abs() > 0.008) {
      widget.onChanged(newVal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final fillPercent = widget.value.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final fillWidth = totalWidth * fillPercent;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: GestureDetector(
            onHorizontalDragStart: (details) {
              setState(() => _isDragging = true);
              HapticFeedback.selectionClick();
              _updateFromPosition(details.localPosition, totalWidth);
            },
            onHorizontalDragUpdate: (details) {
              _updateFromPosition(details.localPosition, totalWidth);
            },
            onHorizontalDragEnd: (_) {
              setState(() => _isDragging = false);
              HapticFeedback.lightImpact();
            },
            onTapDown: (details) {
              HapticFeedback.selectionClick();
              _updateFromPosition(details.localPosition, totalWidth);
            },
            child: AnimatedScale(
              scale: _isDragging ? 1.015 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: widget.style == SliderStyle.matrixCapsule
                  ? _buildMatrixCapsuleSlider(totalWidth, fillPercent, colors)
                  : Container(
                      height: widget.height,
                      decoration: BoxDecoration(
                        color: colors.sliderTrack,
                        borderRadius: BorderRadius.circular(widget.height / 2),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Progress Fill based on Selected Style
                          if (widget.style == SliderStyle.separatedBar)
                            _buildSeparatedBarFill(fillWidth, totalWidth, colors)
                          else
                            _buildContinuousPillFill(fillWidth, colors),

                          // Leading Icon
                          Positioned(
                            left: 18,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Icon(
                                widget.leadingIcon,
                                size: 22,
                                color: fillPercent > 0.15
                                    ? colors.onActivePill
                                    : colors.onInactivePill,
                              ),
                            ),
                          ),

                          // Optional Trailing Action Icon
                          if (widget.trailingIcon != null)
                            Positioned(
                              right: 14,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: IconButton(
                                  icon: Icon(
                                    widget.trailingIcon,
                                    size: 20,
                                    color: fillPercent > 0.85
                                        ? colors.onActivePill
                                        : colors.textSecondary,
                                  ),
                                  onPressed: widget.onTrailingTap,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSeparatedBarFill(double fillWidth, double totalWidth, ExpressiveThemeColors colors) {
    const barWidth = 4.5;
    const gap = 5.0;
    final availableFill = (fillWidth - gap - barWidth).clamp(0.0, totalWidth);
    const overflowY = 6.0; // Taller than the actual bar by 12px total

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main active block
        if (availableFill > 0)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: availableFill,
            child: Container(
              decoration: BoxDecoration(
                color: colors.sliderProgress,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(widget.height / 2),
                  right: const Radius.circular(6),
                ),
              ),
            ),
          ),

        // Separated Vertical Indicator Bar - Taller than the actual bar, NO glow
        if (fillWidth > 6)
          Positioned(
            left: (fillWidth - barWidth).clamp(0.0, totalWidth - barWidth - 1),
            top: -overflowY,
            bottom: -overflowY,
            child: Container(
              width: barWidth,
              decoration: BoxDecoration(
                color: colors.sliderProgress,
                borderRadius: BorderRadius.circular(barWidth / 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContinuousPillFill(double fillWidth, ExpressiveThemeColors colors) {
    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedContainer(
        duration: _isDragging ? Duration.zero : const Duration(milliseconds: 140),
        curve: Curves.easeOutQuad,
        width: fillWidth,
        height: widget.height,
        decoration: BoxDecoration(
          color: colors.sliderProgress,
          borderRadius: BorderRadius.circular(widget.height / 2),
        ),
      ),
    );
  }

  Widget _buildMatrixCapsuleSlider(
    double totalWidth,
    double fillPercent,
    ExpressiveThemeColors colors,
  ) {
    const minPillWidth = 74.0;
    final pillWidth = minPillWidth + (totalWidth - minPillWidth) * fillPercent;

    return SizedBox(
      height: widget.height,
      width: totalWidth,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Thin track line extending all the way
          Container(
            height: 4.0,
            width: totalWidth,
            decoration: BoxDecoration(
              color: colors.inactivePill.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Pill Capsule on the left
          AnimatedContainer(
            duration: _isDragging ? Duration.zero : const Duration(milliseconds: 60),
            width: pillWidth,
            height: widget.height,
            decoration: BoxDecoration(
              color: colors.activePill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(
                widget.leadingIcon,
                size: 22,
                color: colors.onActivePill,
              ),
            ),
          ),
          if (widget.trailingIcon != null)
            Positioned(
              right: 14,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: Icon(
                    widget.trailingIcon,
                    size: 20,
                    color: fillPercent > 0.85
                        ? colors.onActivePill
                        : colors.textSecondary,
                  ),
                  onPressed: widget.onTrailingTap,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
