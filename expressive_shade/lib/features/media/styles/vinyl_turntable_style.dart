import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/font_config.dart';
import '../../../theme/m3_expressive_theme.dart';
import '../widgets/media_common_widgets.dart';

class VinylTurntableStyle extends StatelessWidget {
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

  const VinylTurntableStyle({
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
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 96,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: 0,
                      top: 4,
                      bottom: 4,
                      child: SpinningVinylDisc(
                        size: 88,
                        isPlaying: isPlaying,
                        artwork: artwork,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 96,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: artwork != null
                              ? Image.memory(
                                  artwork!,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                )
                              : const DefaultAlbumArtBackground(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.graphic_eq_rounded,
                          size: 14,
                          color: colors.activePill,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          source.toUpperCase(),
                          style: font.textStyleBuilder(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colors.activePill,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: font.textStyleBuilder(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (artist.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: font.textStyleBuilder(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: colors.activePill,
              inactiveTrackColor: colors.inactivePill,
              thumbColor: colors.activePill,
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: onProgressChanged,
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  Icons.repeat_rounded,
                  color: colors.textSecondary,
                  size: 20,
                ),
                onPressed: () => HapticFeedback.lightImpact(),
              ),
              IconButton(
                icon: Icon(
                  Icons.skip_previous_rounded,
                  color: colors.textPrimary,
                  size: 28,
                ),
                onPressed: onSkipPrevious,
              ),
              MediaCirclePlayButton(
                size: 48,
                bgColor: colors.activePill,
                iconColor: colors.onActivePill,
                isPlaying: isPlaying,
                onPlayPause: onPlayPause,
              ),
              IconButton(
                icon: Icon(
                  Icons.skip_next_rounded,
                  color: colors.textPrimary,
                  size: 28,
                ),
                onPressed: onSkipNext,
              ),
              IconButton(
                icon: Icon(
                  Icons.favorite_border_rounded,
                  color: colors.textSecondary,
                  size: 20,
                ),
                onPressed: () => HapticFeedback.lightImpact(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
