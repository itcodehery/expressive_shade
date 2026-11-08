import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/font_config.dart';
import '../../../providers/shade_state_provider.dart';
import '../../../theme/m3_expressive_theme.dart';
import '../services/lyrics_sync_service.dart';

/// "Inline Integration": A very minimalist synced lyrics view displayed directly below the media player.
class InlineLyricsView extends StatefulWidget {
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final TextAlign textAlign;

  const InlineLyricsView({
    super.key,
    required this.colors,
    required this.font,
    this.textAlign = TextAlign.center,
  });

  @override
  State<InlineLyricsView> createState() => _InlineLyricsViewState();
}

class _InlineLyricsViewState extends State<InlineLyricsView> {
  final LyricsSyncService _service = LyricsSyncService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Check setting option from layout
    final isEnabled = context.select<ShadeStateProvider, bool>(
      (s) => s.inlineLyricsEnabled,
    );

    if (!isEnabled || !_service.hasActiveTrack) {
      return const SizedBox.shrink();
    }

    final currentText = _service.currentLyricText;
    final nextText = _service.nextLyricText;

    // Don't show if empty or default placeholder when paused
    if (currentText.isEmpty || currentText == 'No track playing') {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'Inline Integration Synced Lyrics: $currentText',
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: widget.colors.isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: widget.textAlign == TextAlign.center
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            // Current Active Line with smooth slide & fade animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.22),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: Row(
                key: ValueKey<String>('${_service.currentLyricIndex}_$currentText'),
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: widget.textAlign == TextAlign.center
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    size: 13,
                    color: widget.colors.activePill.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      currentText,
                      textAlign: widget.textAlign,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: widget.font.textStyleBuilder(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        textStyle: const TextStyle(height: 1.25),
                        color: widget.colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Next Line preview in very subtle dimmed opacity
            if (nextText.isNotEmpty) ...[
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: Text(
                  nextText,
                  key: ValueKey<String>('next_$nextText'),
                  textAlign: widget.textAlign,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: widget.font.textStyleBuilder(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w400,
                    color: widget.colors.textSecondary.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
