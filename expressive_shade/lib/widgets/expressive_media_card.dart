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
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.activePill.withValues(alpha: 0.22),
            colors.surface,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: App Badge & Cast Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.activePill.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 16,
                          color: colors.activePill,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        appSource,
                        style: font.textStyleBuilder(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.background.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.speaker_group_rounded, size: 14, color: colors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Phone speaker',
                          style: font.textStyleBuilder(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Track Info & Playback Controls
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
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          artist,
                          style: font.textStyleBuilder(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Media Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onSkipPrevious != null)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: Icon(Icons.skip_previous_rounded, color: colors.textPrimary, size: 24),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            onSkipPrevious!();
                          },
                        ),
                      const SizedBox(width: 4),
                      // Tactile Play/Pause Pill Button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onPlayPause();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colors.activePill,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: colors.activePill.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                key: ValueKey(isPlaying),
                                size: 26,
                                color: colors.onActivePill,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (onSkipNext != null)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: Icon(Icons.skip_next_rounded, color: colors.textPrimary, size: 24),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            onSkipNext!();
                          },
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Interactive Scrub Progress Bar
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: colors.activePill,
                  inactiveTrackColor: colors.sliderTrack,
                  thumbColor: colors.activePill,
                ),
                child: Slider(
                  value: progress,
                  onChanged: (val) {
                    onProgressChanged(val);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
