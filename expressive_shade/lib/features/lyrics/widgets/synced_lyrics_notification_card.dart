import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/font_config.dart';
import '../../../theme/m3_expressive_theme.dart';
import '../services/lyrics_sync_service.dart';

class SyncedLyricsNotificationCard extends StatefulWidget {
  final ExpressiveThemeColors colors;
  final FontConfig font;

  const SyncedLyricsNotificationCard({
    super.key,
    required this.colors,
    required this.font,
  });

  @override
  State<SyncedLyricsNotificationCard> createState() =>
      _SyncedLyricsNotificationCardState();
}

class _SyncedLyricsNotificationCardState
    extends State<SyncedLyricsNotificationCard>
    with SingleTickerProviderStateMixin {
  final LyricsSyncService _service = LyricsSyncService.instance;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (_service.isPlaying) {
      _waveController.repeat();
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _scrollController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (!mounted) return;

    if (_service.isPlaying && !_waveController.isAnimating) {
      _waveController.repeat();
    } else if (!_service.isPlaying && _waveController.isAnimating) {
      _waveController.stop();
    }

    setState(() {});

    if (_service.isExpanded &&
        _scrollController.hasClients &&
        _service.currentLyricIndex >= 0 &&
        _service.currentLyrics != null) {
      final targetOffset = (_service.currentLyricIndex * 42.0).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (!_service.isVisible || !_service.hasActiveTrack) {
      return const SizedBox.shrink();
    }

    final cardBg = widget.colors.notificationCardBackground;
    final isExpanded = _service.isExpanded;
    final title = _service.trackTitle ?? '';
    final artist = _service.artistName ?? '';
    final total = _service.trackDuration;
    final current = _service.currentPosition;
    final progress = total.inMilliseconds > 0
        ? (current.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.colors.textPrimary.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.selectionClick();
            _service.toggleExpanded();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Wave indicator + Title/Artist + Synced Badge + Controls
                _buildHeader(title, artist),
                const SizedBox(height: 10),

                // Main Lyrics Section (Compact vs Expanded)
                AnimatedCrossFade(
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                  firstChild: _buildCompactLyrics(),
                  secondChild: _buildExpandedLyricsReel(),
                ),

                const SizedBox(height: 10),

                // Progress Bar with Time Labels
                _buildProgressBar(progress, current, total),

                // Expanded Controls Row (when expanded)
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  _buildExpandedControls(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String artist) {
    return Row(
      children: [
        // Pulsing Wave/Music Icon
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: widget.colors.activePill.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: _service.isPlaying
                ? AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(3, (index) {
                          final phase = (_waveController.value * 2 * math.pi) +
                              (index * 1.8);
                          final height = 5.0 + 8.0 * (0.5 + 0.5 * math.sin(phase));
                          return Container(
                            width: 3,
                            height: height,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: widget.colors.activePill,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      );
                    },
                  )
                : Icon(
                    Icons.music_note_rounded,
                    size: 16,
                    color: widget.colors.activePill,
                  ),
          ),
        ),
        const SizedBox(width: 10),

        // Title and Artist
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: widget.font.textStyleBuilder(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: widget.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: widget.font.textStyleBuilder(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: widget.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Live Lyrics Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: _service.isSynced
                ? widget.colors.activePill.withValues(alpha: 0.15)
                : widget.colors.textSecondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lyrics_rounded,
                size: 11,
                color: _service.isSynced
                    ? widget.colors.activePill
                    : widget.colors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _service.isSynced
                    ? 'SYNCED'
                    : (_service.isLoadingLyrics ? 'SYNCING' : 'LYRICS'),
                style: widget.font.textStyleBuilder(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  textStyle: const TextStyle(letterSpacing: 0.5),
                  color: _service.isSynced
                      ? widget.colors.activePill
                      : widget.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),

        // Expand / Collapse Chevron Button
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          icon: Icon(
            _service.isExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: widget.colors.textSecondary,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            _service.toggleExpanded();
          },
        ),
      ],
    );
  }

  Widget _buildCompactLyrics() {
    final currentText = _service.currentLyricText;
    final nextText = _service.nextLyricText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Active Line with Slide & Fade Animation
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.25),
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
          child: Container(
            key: ValueKey<String>('${_service.currentLyricIndex}_$currentText'),
            width: double.infinity,
            alignment: Alignment.centerLeft,
            child: Text(
              currentText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: widget.font.textStyleBuilder(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                textStyle: const TextStyle(height: 1.25),
                color: widget.colors.textPrimary,
              ),
            ),
          ),
        ),

        // Upcoming Line Preview
        if (nextText.isNotEmpty) ...[
          const SizedBox(height: 3),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Text(
              nextText,
              key: ValueKey<String>('next_$nextText'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: widget.font.textStyleBuilder(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: widget.colors.textSecondary.withValues(alpha: 0.65),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExpandedLyricsReel() {
    final lyrics = _service.currentLyrics;

    if (lyrics == null || !lyrics.isSynced || lyrics.lines.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Text(
          lyrics?.rawPlainLyrics ?? (_service.isLoadingLyrics ? 'Loading lyrics...' : 'No synchronized lyrics found'),
          textAlign: TextAlign.center,
          style: widget.font.textStyleBuilder(
            fontSize: 13.5,
            color: widget.colors.textSecondary,
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0.0, 0.08, 0.92, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: lyrics.lines.length,
          padding: const EdgeInsets.symmetric(vertical: 20),
          itemBuilder: (context, index) {
            final line = lyrics.lines[index];
            final isCurrent = index == _service.currentLyricIndex;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _service.seekToLine(line);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  child: Row(
                    children: [
                      // Active bullet indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isCurrent ? 5 : 0,
                        height: isCurrent ? 18 : 0,
                        margin: EdgeInsets.only(right: isCurrent ? 8 : 0),
                        decoration: BoxDecoration(
                          color: widget.colors.activePill,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: widget.font.textStyleBuilder(
                            fontSize: isCurrent ? 15.5 : 13.5,
                            fontWeight:
                                isCurrent ? FontWeight.w800 : FontWeight.w500,
                            color: isCurrent
                                ? widget.colors.textPrimary
                                : widget.colors.textSecondary
                                    .withValues(alpha: 0.45),
                          ),
                          child: Text(
                            line.text.trim().isEmpty ? '♪ ♪ ♪' : line.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    double progress,
    Duration current,
    Duration total,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor:
                widget.colors.textPrimary.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.colors.activePill,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(current),
              style: widget.font.textStyleBuilder(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: widget.colors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
            Text(
              _formatDuration(total),
              style: widget.font.textStyleBuilder(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: widget.colors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous track
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _service.skipPrevious();
          },
          icon: Icon(
            Icons.skip_previous_rounded,
            size: 26,
            color: widget.colors.textPrimary,
          ),
        ),
        const SizedBox(width: 16),

        // Play/Pause button
        Material(
          color: widget.colors.activePill,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.mediumImpact();
              _service.togglePlayPause();
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                _service.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 28,
                color: widget.colors.onActivePill,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Next track
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _service.skipNext();
          },
          icon: Icon(
            Icons.skip_next_rounded,
            size: 26,
            color: widget.colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
