import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/font_config.dart';

class MediaPillBadge extends StatelessWidget {
  final String text;
  final IconData icon;
  final FontConfig font;

  const MediaPillBadge({
    super.key,
    required this.text,
    required this.icon,
    required this.font,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: font.textStyleBuilder(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class MediaCirclePlayButton extends StatelessWidget {
  final double size;
  final Color bgColor;
  final Color iconColor;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  const MediaCirclePlayButton({
    super.key,
    required this.size,
    required this.bgColor,
    required this.iconColor,
    required this.isPlaying,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.mediumImpact();
          onPlayPause();
        },
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: iconColor,
              size: size * 0.58,
            ),
          ),
        ),
      ),
    );
  }
}

class PlayPauseSpringButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const PlayPauseSpringButton({
    super.key,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  State<PlayPauseSpringButton> createState() => _PlayPauseSpringButtonState();
}

class _PlayPauseSpringButtonState extends State<PlayPauseSpringButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
      reverseDuration: const Duration(milliseconds: 140),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(
        parent: _springController,
        curve: Curves.easeInQuad,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _handleTapDown(_) {
    _springController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(_) {
    _springController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _springController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                widget.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                key: ValueKey(widget.isPlaying),
                size: 30,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MediaIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const MediaIconBtn({
    super.key,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(icon, color: Colors.white, size: 22),
      onPressed: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
    );
  }
}

class SpinningVinylDisc extends StatefulWidget {
  final double size;
  final bool isPlaying;
  final Uint8List? artwork;

  const SpinningVinylDisc({
    super.key,
    required this.size,
    required this.isPlaying,
    this.artwork,
  });

  @override
  State<SpinningVinylDisc> createState() => _SpinningVinylDiscState();
}

class _SpinningVinylDiscState extends State<SpinningVinylDisc>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.isPlaying) {
      _anim.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SpinningVinylDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _anim.repeat();
      } else {
        _anim.stop();
      }
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _anim,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF141416),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: const Color(0xFF282828), width: 1.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size * 0.82,
              height: widget.size * 0.82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF242426), width: 1),
              ),
            ),
            Container(
              width: widget.size * 0.65,
              height: widget.size * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF202022), width: 1),
              ),
            ),
            Container(
              width: widget.size * 0.42,
              height: widget.size * 0.42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF333333),
              ),
              child: ClipOval(
                child: widget.artwork != null
                    ? Image.memory(
                        widget.artwork!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      )
                    : const DefaultAlbumArtBackground(),
              ),
            ),
            Container(
              width: widget.size * 0.12,
              height: widget.size * 0.12,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpressiveWaveformSeeker extends StatefulWidget {
  final double value;
  final bool isPlaying;
  final ValueChanged<double> onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;

  const ExpressiveWaveformSeeker({
    super.key,
    required this.value,
    required this.isPlaying,
    required this.onChanged,
    this.activeColor = Colors.white,
    this.inactiveColor = const Color(0x4DFFFFFF),
    this.thumbColor = Colors.white,
  });

  @override
  State<ExpressiveWaveformSeeker> createState() => _ExpressiveWaveformSeekerState();
}

class _ExpressiveWaveformSeekerState extends State<ExpressiveWaveformSeeker>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.isPlaying) {
      _anim.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ExpressiveWaveformSeeker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _anim.repeat();
      } else {
        _anim.stop();
      }
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    setState(() {
      _isDragging = true;
      _dragValue = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
    });
    HapticFeedback.selectionClick();
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    setState(() {
      _dragValue = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
    });
    widget.onChanged(_dragValue);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    widget.onChanged(_dragValue);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final currentVal = _isDragging ? _dragValue : widget.value;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) => _onPanStart(d, constraints),
          onHorizontalDragUpdate: (d) => _onPanUpdate(d, constraints),
          onHorizontalDragEnd: _onPanEnd,
          onTapDown: (d) {
            final val = (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
            widget.onChanged(val);
            HapticFeedback.lightImpact();
          },
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              return SizedBox(
                height: 24,
                child: CustomPaint(
                  size: Size(constraints.maxWidth, 24),
                  painter: SquigglyWavePainter(
                    progress: currentVal,
                    wavePhase: _anim.value * 2 * math.pi,
                    isPlaying: widget.isPlaying,
                    activeColor: widget.activeColor,
                    inactiveColor: widget.inactiveColor,
                    thumbColor: widget.thumbColor,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class SquigglyWavePainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final bool isPlaying;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;

  SquigglyWavePainter({
    required this.progress,
    required this.wavePhase,
    required this.isPlaying,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final progressX = size.width * progress;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (progressX < size.width) {
      canvas.drawLine(
        Offset(progressX, centerY),
        Offset(size.width, centerY),
        inactivePaint,
      );
    }

    if (progressX > 0) {
      final activePaint = Paint()
        ..color = activeColor
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      if (!isPlaying) {
        canvas.drawLine(
          Offset(0, centerY),
          Offset(progressX, centerY),
          activePaint,
        );
      } else {
        final path = Path();
        path.moveTo(0, centerY);

        const double waveLength = 22.0;
        const double waveAmp = 4.0;
        double x = 0;

        while (x < progressX) {
          final nextX = (x + waveLength).clamp(0.0, progressX);
          final midX = (x + nextX) / 2;
          final sinVal = math.sin((x / waveLength) * 2 * math.pi - wavePhase);
          final controlY = centerY + (sinVal * waveAmp);

          path.quadraticBezierTo(midX, controlY, nextX, centerY);
          x = nextX;
        }

        canvas.drawPath(path, activePaint);
      }
    }

    final thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(progressX, centerY), 6.5, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant SquigglyWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}

class DefaultAlbumArtBackground extends StatelessWidget {
  const DefaultAlbumArtBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2830), Color(0xFF16151A)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 40,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
