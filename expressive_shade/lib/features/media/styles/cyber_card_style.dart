import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/font_config.dart';
import '../../../theme/m3_expressive_theme.dart';
import '../widgets/media_common_widgets.dart';

class CyberCardStyle extends StatelessWidget {
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

  const CyberCardStyle({
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
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: colors.activePill.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: artwork != null
                          ? Image.memory(
                              artwork!,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            )
                          : const DefaultAlbumArtBackground(),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 12,
                        color: colors.activePill,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.activePill,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'NOW PLAYING • $source',
                        style: font.textStyleBuilder(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: colors.onActivePill,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
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

          // Thick pill slider
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: colors.inactivePill,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.activePill),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onSkipPrevious,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.inactivePill,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.skip_previous_rounded,
                        color: colors.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onPlayPause();
                  },
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.activePill,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: colors.onActivePill,
                          size: 24,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPlaying ? 'PAUSE' : 'PLAY',
                          style: font.textStyleBuilder(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.onActivePill,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onSkipNext,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.inactivePill,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.skip_next_rounded,
                        color: colors.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
