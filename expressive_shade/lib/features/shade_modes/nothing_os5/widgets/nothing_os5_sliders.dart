import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/m3_expressive_theme.dart';

/// Side-by-side vertical capsule sliders (Volume & Brightness) occupying a 2x2 Bento block.
class NothingOs5VerticalSlidersPair extends StatelessWidget {
  final double volume;
  final double brightness;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double> onBrightnessChanged;
  final ExpressiveThemeColors colors;
  final double spacing;

  const NothingOs5VerticalSlidersPair({
    super.key,
    required this.volume,
    required this.brightness,
    required this.onVolumeChanged,
    required this.onBrightnessChanged,
    required this.colors,
    this.spacing = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: NothingOs5VerticalCapsuleSlider(
            value: volume,
            onChanged: onVolumeChanged,
            icon: volume <= 0.01
                ? Icons.music_off_rounded
                : Icons.music_note_rounded,
            colors: colors,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: NothingOs5VerticalCapsuleSlider(
            value: brightness,
            onChanged: onBrightnessChanged,
            icon: Icons.wb_sunny_outlined,
            colors: colors,
          ),
        ),
      ],
    );
  }
}

class NothingOs5VerticalCapsuleSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final IconData icon;
  final ExpressiveThemeColors colors;
  final VoidCallback? onLongPress;
  final bool isEditing;
  final bool isSelected;

  const NothingOs5VerticalCapsuleSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.icon,
    required this.colors,
    this.onLongPress,
    this.isEditing = false,
    this.isSelected = false,
  });

  @override
  State<NothingOs5VerticalCapsuleSlider> createState() =>
      _NothingOs5VerticalCapsuleSliderState();
}

class _NothingOs5VerticalCapsuleSliderState
    extends State<NothingOs5VerticalCapsuleSlider> {
  bool _isDragging = false;

  void _updateFromLocalDy(double dy, double maxHeight) {
    if (maxHeight <= 0) return;
    // Bottom is 0.0, top is 1.0
    final newVal = (1.0 - (dy / maxHeight)).clamp(0.0, 1.0);
    widget.onChanged(newVal);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final val = widget.value.clamp(0.0, 1.0);
    final trackColor = colors.inactivePill.withValues(alpha: 0.65);
    final fillColor = colors.activePill;
    final iconOnFill = val > 0.22;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final fillH = (maxH * val).clamp(0.0, maxH);

        final capsule = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: widget.isEditing && widget.isSelected
                ? Border.all(color: colors.textPrimary, width: 2.2)
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: trackColor,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Filled portion rising from bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: fillH,
                    child: Container(
                      color: fillColor,
                    ),
                  ),
                  // Bottom icon
                  Positioned(
                    bottom: 14,
                    child: Icon(
                      widget.icon,
                      size: 21,
                      color: iconOnFill
                          ? colors.onActivePill
                          : colors.onInactivePill,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (widget.isEditing) {
          return capsule;
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: widget.onLongPress,
          onVerticalDragStart: (d) {
            HapticFeedback.selectionClick();
            setState(() => _isDragging = true);
            _updateFromLocalDy(d.localPosition.dy, maxH);
          },
          onVerticalDragUpdate: (d) {
            _updateFromLocalDy(d.localPosition.dy, maxH);
          },
          onVerticalDragEnd: (_) {
            setState(() => _isDragging = false);
          },
          onVerticalDragCancel: () {
            setState(() => _isDragging = false);
          },
          onTapDown: (d) {
            HapticFeedback.lightImpact();
            _updateFromLocalDy(d.localPosition.dy, maxH);
          },
          child: AnimatedScale(
            scale: _isDragging ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: capsule,
          ),
        );
      },
    );
  }
}

/// NothingOS 5 3-dot horizontal Ringer Mode pill (Silent • Vibrate • Ring)
class NothingOs5RingerPill extends StatelessWidget {
  /// 0: Silent, 1: Vibrate, 2: Ring
  final int ringerMode;
  final ValueChanged<int> onModeChanged;
  final ExpressiveThemeColors colors;
  final VoidCallback? onLongPress;
  final bool isEditing;
  final bool isSelected;

  const NothingOs5RingerPill({
    super.key,
    required this.ringerMode,
    required this.onModeChanged,
    required this.colors,
    this.onLongPress,
    this.isEditing = false,
    this.isSelected = false,
  });

  IconData _iconForMode(int mode) {
    switch (mode) {
      case 0:
        return Icons.volume_off_outlined;
      case 1:
        return Icons.vibration_rounded;
      default:
        return Icons.volume_up_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackColor = colors.inactivePill.withValues(alpha: 0.65);
    final thumbColor = colors.activePill;
    final dotColor = colors.onInactivePill.withValues(alpha: 0.55);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final thumbSize = (h - 10.0).clamp(32.0, 56.0);

        final pillBody = Container(
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(999),
            border: isEditing && isSelected
                ? Border.all(color: colors.textPrimary, width: 2.2)
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 3 background dots
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Center(
                      child: Container(
                        width: 4.5,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              // Animated active circular thumb
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                alignment: ringerMode == 0
                    ? Alignment.centerLeft
                    : (ringerMode == 1
                        ? Alignment.center
                        : Alignment.centerRight),
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
                    color: thumbColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _iconForMode(ringerMode),
                      size: 20,
                      color: colors.onActivePill,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        if (isEditing) {
          return pillBody;
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: onLongPress,
          onTapUp: (details) {
            final third = w / 3.0;
            final tappedIndex = (details.localPosition.dx / third)
                .floor()
                .clamp(0, 2);
            HapticFeedback.mediumImpact();
            if (tappedIndex == ringerMode) {
              onModeChanged((ringerMode + 1) % 3);
            } else {
              onModeChanged(tappedIndex);
            }
          },
          onHorizontalDragStart: (details) {
            if (w <= 0) return;
            final third = w / 3.0;
            final draggedIndex = (details.localPosition.dx / third)
                .floor()
                .clamp(0, 2);
            if (draggedIndex != ringerMode) {
              HapticFeedback.selectionClick();
              onModeChanged(draggedIndex);
            }
          },
          onHorizontalDragUpdate: (details) {
            if (w <= 0) return;
            final third = w / 3.0;
            final draggedIndex = (details.localPosition.dx / third)
                .floor()
                .clamp(0, 2);
            if (draggedIndex != ringerMode) {
              HapticFeedback.selectionClick();
              onModeChanged(draggedIndex);
            }
          },
          child: pillBody,
        );
      },
    );
  }
}
