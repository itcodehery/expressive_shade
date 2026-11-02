import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/font_config.dart';
import '../../../theme/m3_expressive_theme.dart';
import '../widgets/media_common_widgets.dart';

class ExpressiveWaveStyle extends StatelessWidget {
  final String title;
  final String artist;
  final String source;
  final bool isPlaying;
  final double progress;
  final Uint8List? artwork;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final VoidCallback onPlayPause;
  final VoidCallback? onSkipNext;
  final VoidCallback? onSkipPrevious;
  final ValueChanged<double> onProgressChanged;

  const ExpressiveWaveStyle({
    super.key,
    required this.title,
    required this.artist,
    required this.source,
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
            // Background Album Art
            Positioned.fill(
              child: artwork != null
                  ? Image.memory(
                      artwork!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      cacheWidth: 256,
                      cacheHeight: 256,
                      filterQuality: FilterQuality.low,
                    )
                  : const DefaultAlbumArtBackground(),
            ),

            // Scrim
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

            // Foreground Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Source App Badge & Output Device Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MediaPillBadge(text: source, icon: Icons.album_rounded, font: font),
                      MediaPillBadge(text: 'This phone', icon: Icons.phone_android_rounded, font: font),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Middle Row: Title & Artist + Prominent Squircle Play/Pause Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: font.textStyleBuilder(
                                fontSize: 19.0,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (artist.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                artist,
                                style: font.textStyleBuilder(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.80),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Large Spring Squircle Play/Pause Button
                      PlayPauseSpringButton(
                        isPlaying: isPlaying,
                        onTap: onPlayPause,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bottom Controls Row: Previous, Squiggly Progress Wave, Next, Repeat, Shuffle
                  Row(
                    children: [
                      MediaIconBtn(
                        icon: Icons.skip_previous_rounded,
                        onTap: onSkipPrevious,
                      ),
                      const SizedBox(width: 4),

                      // Interactive Squiggly Wave Progress Line
                      Expanded(
                        child: ExpressiveWaveformSeeker(
                          value: progress,
                          isPlaying: isPlaying,
                          onChanged: onProgressChanged,
                          activeColor: Colors.white,
                          inactiveColor: Colors.white.withValues(alpha: 0.28),
                          thumbColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),

                      MediaIconBtn(
                        icon: Icons.skip_next_rounded,
                        onTap: onSkipNext,
                      ),
                      const SizedBox(width: 2),

                      MediaIconBtn(
                        icon: Icons.repeat_rounded,
                        onTap: () => HapticFeedback.lightImpact(),
                      ),
                      const SizedBox(width: 2),

                      MediaIconBtn(
                        icon: Icons.shuffle_rounded,
                        onTap: () => HapticFeedback.lightImpact(),
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
