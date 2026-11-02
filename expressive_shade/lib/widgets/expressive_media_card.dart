import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/font_config.dart';
import '../models/media_player_style.dart';
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
  final MediaPlayerStyle style;
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
    this.style = MediaPlayerStyle.expressiveWave,
    required this.onPlayPause,
    this.onSkipNext,
    this.onSkipPrevious,
    required this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasMedia = isPlaying ||
        (title.isNotEmpty &&
            title != 'No media playing' &&
            title != 'Lord I Know');

    final displayTitle = hasMedia ? title : 'No media playing';
    final displayArtist = hasMedia
        ? (artist.isNotEmpty &&
                artist != 'Tap to open media player' &&
                artist != 'Kid Cudi'
            ? artist
            : '')
        : '';
    final displaySource = appSource.isNotEmpty
        ? appSource
        : (hasMedia ? 'Media Player' : 'Media');

    switch (style) {
      case MediaPlayerStyle.compactPill:
        return _buildCompactPill(displayTitle, displayArtist, displaySource);
      case MediaPlayerStyle.vinylTurntable:
        return _buildVinylTurntable(displayTitle, displayArtist, displaySource);
      case MediaPlayerStyle.cyberCard:
        return _buildCyberCard(displayTitle, displayArtist, displaySource);
      case MediaPlayerStyle.expressiveWave:
        return _buildExpressiveWave(displayTitle, displayArtist, displaySource);
    }
  }

  // ===========================================================================
  // 1. STYLE 1: EXPRESSIVE WAVE (Default Android 17 with Play/Pause button on Title)
  // ===========================================================================
  Widget _buildExpressiveWave(
    String displayTitle,
    String displayArtist,
    String displaySource,
  ) {
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
                  : const _DefaultAlbumArtBackground(),
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
                      _buildPillBadge(displaySource, Icons.album_rounded),
                      _buildPillBadge('This phone', Icons.phone_android_rounded),
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
                              displayTitle,
                              style: font.textStyleBuilder(
                                fontSize: 19.0,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (displayArtist.isNotEmpty) ...[
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
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Large Spring Squircle Play/Pause Button
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
                      _MediaIconBtn(
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

                      _MediaIconBtn(
                        icon: Icons.skip_next_rounded,
                        onTap: onSkipNext,
                      ),
                      const SizedBox(width: 2),

                      _MediaIconBtn(
                        icon: Icons.repeat_rounded,
                        onTap: () => HapticFeedback.lightImpact(),
                      ),
                      const SizedBox(width: 2),

                      _MediaIconBtn(
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

  // ===========================================================================
  // 2. STYLE 2: COMPACT PILL CAPSULE (Minimal space-saver with spinning mini-vinyl)
  // ===========================================================================
  Widget _buildCompactPill(
    String displayTitle,
    String displayArtist,
    String displaySource,
  ) {
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
              _SpinningVinylDisc(
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
                      displayTitle,
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
                            displayArtist.isNotEmpty
                                ? (displaySource.isNotEmpty
                                    ? '$displayArtist • $displaySource'
                                    : displayArtist)
                                : (displaySource.isNotEmpty
                                    ? displaySource
                                    : 'Media'),
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
              _buildCirclePlayButton(
                42,
                colors.activePill,
                colors.onActivePill,
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
                  final newProg = (details.localPosition.dx /
                          constraints.maxWidth)
                      .clamp(0.0, 1.0);
                  onProgressChanged(newProg);
                },
                onTapDown: (details) {
                  final newProg = (details.localPosition.dx /
                          constraints.maxWidth)
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
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colors.activePill),
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

  // ===========================================================================
  // 3. STYLE 3: VINYL TURNTABLE PRO (Album sleeve + protruding vinyl disc)
  // ===========================================================================
  Widget _buildVinylTurntable(
    String displayTitle,
    String displayArtist,
    String displaySource,
  ) {
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
                      child: _SpinningVinylDisc(
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
                              : const _DefaultAlbumArtBackground(),
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
                          displaySource.toUpperCase(),
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
                      displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: font.textStyleBuilder(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (displayArtist.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        displayArtist,
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
              _buildCirclePlayButton(48, colors.activePill, colors.onActivePill),
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

  // ===========================================================================
  // 4. STYLE 4: CYBER CARD (Modern high-contrast capsule split layout)
  // ===========================================================================
  Widget _buildCyberCard(
    String displayTitle,
    String displayArtist,
    String displaySource,
  ) {
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
                          : const _DefaultAlbumArtBackground(),
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
                        'NOW PLAYING • $displaySource',
                        style: font.textStyleBuilder(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: colors.onActivePill,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: font.textStyleBuilder(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (displayArtist.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        displayArtist,
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
                  final newProg = (details.localPosition.dx /
                          constraints.maxWidth)
                      .clamp(0.0, 1.0);
                  onProgressChanged(newProg);
                },
                onTapDown: (details) {
                  final newProg = (details.localPosition.dx /
                          constraints.maxWidth)
                      .clamp(0.0, 1.0);
                  onProgressChanged(newProg);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: colors.inactivePill,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colors.activePill),
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

  // ===========================================================================
  // Helpers
  // ===========================================================================
  Widget _buildPillBadge(String text, IconData icon) {
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

  Widget _buildCirclePlayButton(double size, Color bgColor, Color iconColor) {
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

// -----------------------------------------------------------------------------
// Spring Play/Pause Pill Button
// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
// Spinning Vinyl Disc Widget with Realistic Grooves
// -----------------------------------------------------------------------------
class _SpinningVinylDisc extends StatefulWidget {
  final double size;
  final bool isPlaying;
  final Uint8List? artwork;

  const _SpinningVinylDisc({
    required this.size,
    required this.isPlaying,
    this.artwork,
  });

  @override
  State<_SpinningVinylDisc> createState() => _SpinningVinylDiscState();
}

class _SpinningVinylDiscState extends State<_SpinningVinylDisc>
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
  void didUpdateWidget(covariant _SpinningVinylDisc oldWidget) {
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
                    : const _DefaultAlbumArtBackground(),
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

// -----------------------------------------------------------------------------
// Interactive Squiggly Waveform Seeker
// -----------------------------------------------------------------------------
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
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
  });

  @override
  State<ExpressiveWaveformSeeker> createState() =>
      _ExpressiveWaveformSeekerState();
}

class _ExpressiveWaveformSeekerState extends State<ExpressiveWaveformSeeker>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _flattenAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _flattenAnimation = Tween<double>(
      begin: widget.isPlaying ? 1.0 : 0.0,
      end: widget.isPlaying ? 1.0 : 0.0,
    ).animate(CurvedAnimation(parent: _waveController, curve: Curves.easeInOut));

    if (widget.isPlaying) {
      _waveController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ExpressiveWaveformSeeker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _waveController.repeat();
        _flattenAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _waveController, curve: Curves.easeOutCubic),
        );
      } else {
        _flattenAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(parent: _waveController, curve: Curves.easeInCubic),
        );
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _handleDrag(DragUpdateDetails details, BoxConstraints constraints) {
    final newProgress =
        (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
    widget.onChanged(newProgress);
  }

  void _handleTapDown(TapDownDetails details, BoxConstraints constraints) {
    final newProgress =
        (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
    widget.onChanged(newProgress);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) =>
              _handleDrag(details, constraints),
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

    const wavelength = 25.0;
    final baseAmplitude = 2.4 * amplitudeFactor;

    if (thumbX > 0) {
      final activePath = Path();
      activePath.moveTo(0, centerY);

      const step = 1.0;
      for (double x = 0; x <= thumbX; x += step) {
        double envelope = 1.0;
        if (x < 12.0) {
          envelope = (x / 12.0);
        }
        if (thumbX - x < 12.0) {
          envelope = math.min(envelope, (thumbX - x) / 12.0);
        }

        final y = centerY +
            math.sin((x / wavelength * 2 * math.pi) - wavePhase) *
                baseAmplitude *
                envelope;
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
        oldDelegate.thumbColor != thumbColor;
  }
}

class _DefaultAlbumArtBackground extends StatelessWidget {
  const _DefaultAlbumArtBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C1E4A), Color(0xFF1E3A5F), Color(0xFF0F1E36)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 64,
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}
