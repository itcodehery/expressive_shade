import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../models/font_config.dart';
import '../../../theme/m3_expressive_theme.dart';
import '../widgets/media_common_widgets.dart';

class CompactPillStyle extends StatelessWidget {
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

  const CompactPillStyle({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colors.textSecondary.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Spinning Vinyl Disc
              SpinningVinylDisc(
                size: 52,
                isPlaying: isPlaying,
                artwork: artwork,
              ),
              const SizedBox(width: 14),

              // Title and artist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: font.textStyleBuilder(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: colors.activePill,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            artist.isNotEmpty
                                ? (source.isNotEmpty ? '$artist • $source' : artist)
                                : (source.isNotEmpty ? source : 'Media'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: font.textStyleBuilder(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.skip_previous_rounded,
                  color: colors.textSecondary,
                  size: 22,
                ),
                onPressed: onSkipPrevious,
              ),
              MediaCirclePlayButton(
                size: 42,
                bgColor: colors.activePill,
                iconColor: colors.onActivePill,
                isPlaying: isPlaying,
                onPlayPause: onPlayPause,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.skip_next_rounded,
                  color: colors.textSecondary,
                  size: 22,
                ),
                onPressed: onSkipNext,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Interactive thin sleek linear progress bar
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) {
                  final newProg = (details.localPosition.dx / constraints.maxWidth)
                      .clamp(0.0, 1.0);
                  onProgressChanged(newProg);
                },
                onTapDown: (details) {
                  final newProg = (details.localPosition.dx / constraints.maxWidth)
                      .clamp(0.0, 1.0);
                  onProgressChanged(newProg);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 4.5,
                      backgroundColor: colors.inactivePill,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.activePill),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
