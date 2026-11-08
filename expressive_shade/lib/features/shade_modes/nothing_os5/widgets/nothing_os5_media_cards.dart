import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/font_config.dart';
import '../../../../services/system_hardware_service.dart';
import '../../../../theme/m3_expressive_theme.dart';

/// Hero Media Player Card shown at the top of the Left (Notifications) pane in NothingOS 5.
class NothingOs5HeroMediaCard extends StatelessWidget {
  final String title;
  final String artist;
  final String appSource;
  final bool isPlaying;
  final double progress;
  final dynamic artwork;
  final FontConfig font;
  final ExpressiveThemeColors colors;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipNext;
  final VoidCallback onSkipPrevious;
  final ValueChanged<double> onProgressChanged;

  const NothingOs5HeroMediaCard({
    super.key,
    required this.title,
    required this.artist,
    required this.appSource,
    required this.isPlaying,
    required this.progress,
    this.artwork,
    required this.font,
    required this.colors,
    required this.onPlayPause,
    required this.onSkipNext,
    required this.onSkipPrevious,
    required this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Uint8List? artBytes = artwork is Uint8List ? artwork as Uint8List : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 174,
        decoration: const BoxDecoration(
          color: Color(0xFF18191E),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background album art or rich dark gradient
            if (artBytes != null && artBytes.isNotEmpty)
              Image.memory(
                artBytes,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2B2D38),
                      Color(0xFF14151A),
                    ],
                  ),
                ),
              ),

            // Dark vignette scrim so white typography is always legible
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.38),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),

            // Content layout
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top row: App badge on left, Cast pill on right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.music_note_rounded,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          SystemHardwareService.triggerCast();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.45),
                              width: 1.0,
                            ),
                          ),
                          child: const Icon(
                            Icons.cast_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Middle row: Title/Artist on left, Stadium Play/Pause pill on right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title.isNotEmpty ? title : 'There for You',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: font.textStyleBuilder(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              artist.isNotEmpty
                                  ? artist
                                  : 'Martin Garrix, Troye Sivan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: font.textStyleBuilder(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          onPlayPause();
                        },
                        child: Container(
                          width: 64,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDE1FF),
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: Center(
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 24,
                              color: const Color(0xFF141624),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom row: Prev, Vertical-Tick Seekbar, Next, Repeat, Shuffle
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onSkipPrevious();
                        },
                        child: const Icon(
                          Icons.skip_previous_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _NothingTickSeekbar(
                          progress: progress,
                          onChanged: onProgressChanged,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onSkipNext();
                        },
                        child: const Icon(
                          Icons.skip_next_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(
                        Icons.repeat_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                      const SizedBox(width: 14),
                      Icon(
                        Icons.shuffle_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.55),
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

class _NothingTickSeekbar extends StatelessWidget {
  final double progress;
  final ValueChanged<double> onChanged;

  const _NothingTickSeekbar({
    required this.progress,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final thumbX = (w * p).clamp(2.0, (w - 4.0).clamp(2.0, double.infinity));

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) {
            if (w > 0) {
              onChanged((d.localPosition.dx / w).clamp(0.0, 1.0));
            }
          },
          onTapDown: (d) {
            if (w > 0) {
              HapticFeedback.selectionClick();
              onChanged((d.localPosition.dx / w).clamp(0.0, 1.0));
            }
          },
          child: SizedBox(
            height: 22,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Background track
                Container(
                  height: 2.5,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Active track
                Container(
                  height: 2.5,
                  width: thumbX,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Vertical tick thumb
                Positioned(
                  left: (thumbX - 2).clamp(0.0, w),
                  child: Container(
                    width: 4,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Compact Media Player Bar shown at the top of the Right (Control Center) pane in NothingOS 5.
class NothingOs5CompactMediaCard extends StatelessWidget {
  final String title;
  final String artist;
  final bool isPlaying;
  final dynamic artwork;
  final FontConfig font;
  final ExpressiveThemeColors colors;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipNext;

  const NothingOs5CompactMediaCard({
    super.key,
    required this.title,
    required this.artist,
    required this.isPlaying,
    this.artwork,
    required this.font,
    required this.colors,
    required this.onPlayPause,
    required this.onSkipNext,
  });

  @override
  Widget build(BuildContext context) {
    final Uint8List? artBytes = artwork is Uint8List ? artwork as Uint8List : null;

    final cardBg = colors.isDark
        ? colors.surface.withValues(alpha: 0.85)
        : colors.surface;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          // Rounded square album art
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 52,
              height: 52,
              child: artBytes != null && artBytes.isNotEmpty
                  ? Image.memory(
                      artBytes,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: colors.isDark
                              ? const [
                                  Color(0xFF334155),
                                  Color(0xFF0F172A),
                                ]
                              : const [
                                  Color(0xFFE4E4E7),
                                  Color(0xFFD4D4D8),
                                ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.album_rounded,
                          color: colors.isDark
                              ? Colors.white70
                              : const Color(0xFF52525B),
                          size: 26,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Title & Artist
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.isNotEmpty ? title : 'There for You',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: font.textStyleBuilder(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  artist.isNotEmpty ? artist : 'Martin Garrix, Troye Sivan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: font.textStyleBuilder(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Cast, Play/Pause, Next controls
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.cast_rounded,
              size: 19,
              color: colors.textPrimary.withValues(alpha: 0.8),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              SystemHardwareService.triggerCast();
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 24,
              color: colors.textPrimary,
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              onPlayPause();
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.skip_next_rounded,
              size: 23,
              color: colors.textPrimary,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              onSkipNext();
            },
          ),
        ],
      ),
    );
  }
}
