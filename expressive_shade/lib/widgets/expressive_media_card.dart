import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/font_config.dart';
import '../theme/m3_expressive_theme.dart';

class ExpressiveMediaCard extends StatelessWidget {
  final String title;
  final String artist;
  final String appSource;
  final bool isPlaying;
  final double progress;
  final Uint8List? artwork;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final VoidCallback onPlayPause;
  final VoidCallback? onSkipNext;
  final VoidCallback? onSkipPrevious;
  final ValueChanged<double> onProgressChanged;

  const ExpressiveMediaCard({
    super.key,
    required this.title,
    required this.artist,
    required this.appSource,
    required this.isPlaying,
    required this.progress,
    this.artwork,
    required this.colors,
    required this.font,
    required this.onPlayPause,
    this.onSkipNext,
    this.onSkipPrevious,
    required this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = title.isNotEmpty && title != 'No media playing' ? title : 'Lord I Know';
    final displayArtist = artist.isNotEmpty && artist != 'Tap to open media player' ? artist : 'Kid Cudi';
    final displaySource = appSource.isNotEmpty ? appSource : 'Spotify';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // 1. Background Album Art
            Positioned.fill(
              child: artwork != null
                  ? Image.memory(
                      artwork!,
                      fit: BoxFit.cover,
                      // Keep the previous frame while new art decodes (no flicker)
                      // and decode at the native 256px size instead of full resolution.
                      gaplessPlayback: true,
                      cacheWidth: 256,
                      cacheHeight: 256,
                      filterQuality: FilterQuality.low,
                    )
                  : const _DefaultAlbumArtBackground(),
            ),

            // 2. Dark Scrim Overlay for crisp contrast
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Foreground Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Source App Badge & Output Device Pill ("This phone")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Source App Pill
                      Container(
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
                            const Icon(
                              Icons.album_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              displaySource,
                              style: font.textStyleBuilder(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Output Device Pill ("This phone")
                      Container(
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
                            const Icon(
                              Icons.phone_android_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'This phone',
                              style: font.textStyleBuilder(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Middle Row: Title & Artist + Large Squircle Play/Pause Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayTitle,
                              style: font.textStyleBuilder(
                                fontSize: 19.0,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              displayArtist,
                              style: font.textStyleBuilder(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.80),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Large Squircle Play/Pause Button (matching screenshot)
                      _PlayPauseSpringButton(
                        isPlaying: isPlaying,
                        onTap: onPlayPause,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bottom Controls Row: Previous, Squiggly Progress Wave, Next, Repeat, Shuffle
                  Row(
                    children: [
                      // Skip Previous
                      _MediaIconBtn(
                        icon: Icons.skip_previous_rounded,
                        onTap: onSkipPrevious,
                      ),
                      const SizedBox(width: 4),

                      // Interactive Squiggly Wave Progress Line
                      Expanded(
                        child: SquigglyWaveProgress(
                          value: progress,
                          isPlaying: isPlaying,
                          activeColor: Colors.white,
                          inactiveColor: Colors.white.withValues(alpha: 0.28),
                          thumbColor: Colors.white,
                          onChanged: onProgressChanged,
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Skip Next
                      _MediaIconBtn(
                        icon: Icons.skip_next_rounded,
                        onTap: onSkipNext,
                      ),
                      const SizedBox(width: 2),

                      // Repeat
                      _MediaIconBtn(
                        icon: Icons.repeat_rounded,
                        onTap: () {
                          HapticFeedback.lightImpact();
                        },
                      ),
                      const SizedBox(width: 2),

                      // Shuffle
                      _MediaIconBtn(
                        icon: Icons.shuffle_rounded,
                        onTap: () {
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallback Cosmic/Psychedelic Album Art Background matching Kid Cudi Man on the Moon III
class _DefaultAlbumArtBackground extends StatelessWidget {
  const _DefaultAlbumArtBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.4, -0.3),
          radius: 1.2,
          colors: [
            Color(0xFF8B2FC9), // Celestial violet
            Color(0xFF283FA8), // Deep cobalt
            Color(0xFF141F61), // Cosmic navy
            Color(0xFF0A0E2B), // Void black
          ],
          stops: [0.0, 0.45, 0.75, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _CosmicArtPainter(),
      ),
    );
  }
}

class _CosmicArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Glowing celestial moon orb (top right)
    final moonCenter = Offset(size.width * 0.72, size.height * 0.40);
    final moonPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.90),
          const Color(0xFFC4D5FF).withValues(alpha: 0.60),
          const Color(0xFF5D73D4).withValues(alpha: 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(Rect.fromCircle(center: moonCenter, radius: 46));
    canvas.drawCircle(moonCenter, 46, moonPaint);

    // Warm nebula spray (left/middle)
    final nebulaPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF5284).withValues(alpha: 0.35),
          const Color(0xFFFF7E40).withValues(alpha: 0.20),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.32, size.height * 0.55), radius: 80));
    canvas.drawCircle(Offset(size.width * 0.32, size.height * 0.55), 80, nebulaPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Squiggly Wave Progress Line (Sinusoidal animated wave when playing, flat when paused)
class SquigglyWaveProgress extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final bool isPlaying;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;
  final ValueChanged<double> onChanged;

  const SquigglyWaveProgress({
    super.key,
    required this.value,
    required this.isPlaying,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
    required this.onChanged,
  });

  @override
  State<SquigglyWaveProgress> createState() => _SquigglyWaveProgressState();
}

class _SquigglyWaveProgressState extends State<SquigglyWaveProgress>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _waveController;
  late AnimationController _flattenController;
  late Animation<double> _flattenAnimation;

  @override
  void initState() {
    super.initState();
    // Wave moves continuously towards the right when playing with soft gentle pace
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );

    _flattenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      value: widget.isPlaying ? 1.0 : 0.0,
    );

    _flattenAnimation = CurvedAnimation(
      parent: _flattenController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    if (widget.isPlaying) {
      _waveController.repeat();
    }
    WidgetsBinding.instance.addObserver(this);
  }

  /// Stops the endless wave animation while the app/shade is hidden and restarts it on return.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (widget.isPlaying && !_waveController.isAnimating) {
        _waveController.repeat();
      }
    } else {
      _waveController.stop();
    }
  }

  @override
  void didUpdateWidget(covariant SquigglyWaveProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _waveController.repeat();
        _flattenController.forward();
      } else {
        _flattenController.reverse().then((_) {
          if (!widget.isPlaying) {
            _waveController.stop();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _waveController.dispose();
    _flattenController.dispose();
    super.dispose();
  }

  void _handleDrag(DragUpdateDetails details, BoxConstraints constraints) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final localX = details.localPosition.dx;
      final newProgress = (localX / box.size.width).clamp(0.0, 1.0);
      widget.onChanged(newProgress);
    }
  }

  void _handleTapDown(TapDownDetails details, BoxConstraints constraints) {
    HapticFeedback.selectionClick();
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final localX = details.localPosition.dx;
      final newProgress = (localX / box.size.width).clamp(0.0, 1.0);
      widget.onChanged(newProgress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) => _handleDrag(details, constraints),
          onTapDown: (details) => _handleTapDown(details, constraints),
          child: SizedBox(
            height: 28,
            child: AnimatedBuilder(
              animation: Listenable.merge([_waveController, _flattenAnimation]),
              builder: (context, _) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, 28),
                  painter: _SquigglyWavePainter(
                    progress: widget.value.clamp(0.0, 1.0),
                    wavePhase: _waveController.value * 2 * math.pi,
                    amplitudeFactor: _flattenAnimation.value,
                    activeColor: widget.activeColor,
                    inactiveColor: widget.inactiveColor,
                    thumbColor: widget.thumbColor,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _SquigglyWavePainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final double amplitudeFactor;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;

  _SquigglyWavePainter({
    required this.progress,
    required this.wavePhase,
    required this.amplitudeFactor,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final thumbX = (progress * size.width).clamp(0.0, size.width);

    const wavelength = 25.0; // Softer, more elongated wave (was 18.0)
    final baseAmplitude = 2.4 * amplitudeFactor; // Softer, gentler amplitude (was 3.8)

    // 1. Draw Active Wave Segment (from 0 to thumbX)
    if (thumbX > 0) {
      final activePath = Path();
      activePath.moveTo(0, centerY);

      // Draw sinusoidal wave with smooth start and end envelopes
      const step = 1.0;
      for (double x = 0; x <= thumbX; x += step) {
        double envelope = 1.0;
        if (x < 12.0) {
          envelope = (x / 12.0);
        }
        if (thumbX - x < 12.0) {
          envelope = math.min(envelope, (thumbX - x) / 12.0);
        }

        // Softer sinusoidal wave moving gently to the right
        final y = centerY + math.sin((x / wavelength * 2 * math.pi) - wavePhase) * baseAmplitude * envelope;
        activePath.lineTo(x, y);
      }

      final activePaint = Paint()
        ..color = activeColor
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(activePath, activePaint);
    }

    // 2. Draw Inactive Flat Line (from thumbX to width)
    if (thumbX < size.width) {
      final inactivePaint = Paint()
        ..color = inactiveColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(thumbX, centerY),
        Offset(size.width, centerY),
        inactivePaint,
      );
    }

    // 3. Draw Tactile Thumb Knob
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(thumbX, centerY + 1), 6.5, shadowPaint);

    final thumbPaint = Paint()..color = thumbColor;
    canvas.drawCircle(Offset(thumbX, centerY), 5.5, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant _SquigglyWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.amplitudeFactor != amplitudeFactor ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}

/// Spring Play/Pause Pill Button
class _PlayPauseSpringButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _PlayPauseSpringButton({
    required this.isPlaying,
    required this.onTap,
  });

  @override
  State<_PlayPauseSpringButton> createState() => _PlayPauseSpringButtonState();
}

class _PlayPauseSpringButtonState extends State<_PlayPauseSpringButton>
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
        reverseCurve: Curves.easeOutBack, // M3 Expressive Spring Bounce
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
                widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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

class _MediaIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MediaIconBtn({
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
