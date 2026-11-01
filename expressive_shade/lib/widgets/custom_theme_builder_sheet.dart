import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shade_theme.dart';
import '../providers/shade_state_provider.dart';
import '../theme/m3_expressive_theme.dart';

class CustomThemeBuilderSheet extends StatefulWidget {
  const CustomThemeBuilderSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CustomThemeBuilderSheet(),
    );
  }

  @override
  State<CustomThemeBuilderSheet> createState() => _CustomThemeBuilderSheetState();
}

class _CustomThemeBuilderSheetState extends State<CustomThemeBuilderSheet> {
  late Color _selectedSeed;
  late bool _isAmoled;
  late double _cardOpacity;
  late double _blurIntensity;

  // HSV variables for full spectrum color picker
  late double _currentHue;
  late double _currentSaturation;
  late double _currentValue;

  static const List<Color> _curatedSeedColors = [
    Color(0xFF2E7D32), // Forest Green
    Color(0xFF00897B), // Mint Teal
    Color(0xFF0284C7), // Glacial Sky
    Color(0xFF2563EB), // Cobalt Blue
    Color(0xFF7C3AED), // Expressive Violet
    Color(0xFFC026D3), // Fuchsia / Neon Pink
    Color(0xFFE11D48), // Rose Crimson
    Color(0xFFEA580C), // Tangelo Orange
    Color(0xFFD97706), // Warm Amber
    Color(0xFF65A30D), // Lime Grass
    Color(0xFF64748B), // Slate Modern
    Color(0xFF334155), // Charcoal Deep
  ];

  @override
  void initState() {
    super.initState();
    final current = context.read<ShadeStateProvider>().customTheme;
    _selectedSeed = current.primaryColor;
    _isAmoled = current.isAmoled;
    _cardOpacity = current.cardOpacity;
    _blurIntensity = current.blurIntensity;

    final hsv = HSVColor.fromColor(_selectedSeed);
    _currentHue = hsv.hue;
    _currentSaturation = hsv.saturation;
    _currentValue = hsv.value;
  }

  void _updateColorFromHsv() {
    setState(() {
      _selectedSeed = HSVColor.fromAHSV(1.0, _currentHue, _currentSaturation, _currentValue).toColor();
    });
  }

  String _colorToHex(Color color) {
    final r = (color.r * 255).toInt().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).toInt().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).toInt().toRadixString(16).padLeft(2, '0');
    return '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShadeStateProvider>();
    final isSystemDark = Theme.of(context).brightness == Brightness.dark;

    final previewTheme = CustomThemeData(
      primaryColor: _selectedSeed,
      isAmoled: _isAmoled,
      cardOpacity: _cardOpacity,
      blurIntensity: _blurIntensity,
    );

    final colors = ExpressiveThemeColors.fromSettings(
      source: ThemeSource.custom,
      preset: state.selectedPreset,
      custom: previewTheme,
      systemMonetColor: state.systemMonetColor,
      isSystemDark: isSystemDark,
    );

    final cardGlassBg = (_isAmoled
            ? Colors.black
            : (colors.isDark ? const Color(0xFF1E1E24) : Colors.white))
        .withValues(alpha: _cardOpacity);

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Sheet Title
            Row(
              children: [
                Icon(Icons.palette_outlined, color: colors.activePill, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Custom Theme Studio',
                  style: state.selectedFont.textStyleBuilder(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Customize color accents, fine-tune card opacity, and live-preview acrylic backdrop blur.',
              style: state.selectedFont.textStyleBuilder(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Realistic Live Card Preview with Wallpaper Backdrop
            Text(
              'LIVE ACRYLIC CARD PREVIEW',
              style: state.selectedFont.textStyleBuilder(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            // Simulated Wallpaper Box
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colors.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    // Underlying Colorful Simulated Wallpaper (so blur and opacity are crystal clear)
                    Container(
                      height: 230,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1E3A8A), // Deep Blue
                            Color(0xFF7C3AED), // Violet
                            Color(0xFFDB2777), // Pink
                            Color(0xFFF59E0B), // Amber
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Abstract bokeh circles behind cards
                          Positioned(
                            left: 30,
                            top: 20,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.cyanAccent.withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 20,
                            bottom: 10,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.amberAccent.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 140,
                            bottom: 30,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.purpleAccent.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Translucent Tint Overlay
                    Positioned.fill(
                      child: Container(
                        color: colors.background.withValues(alpha: _isAmoled ? 0.75 : 0.35),
                      ),
                    ),

                    // Foreground Blurred Cards
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Acrylic Quick Settings Row
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: _blurIntensity,
                                sigmaY: _blurIntensity,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: cardGlassBg,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Wide Active Pill
                                    Expanded(
                                      child: Container(
                                        height: 48,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: colors.activePill,
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.wifi, color: colors.onActivePill, size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Internet',
                                                    style: state.selectedFont.textStyleBuilder(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w700,
                                                      color: colors.onActivePill,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Connected',
                                                    style: state.selectedFont.textStyleBuilder(
                                                      fontSize: 10,
                                                      color: colors.onActivePill.withValues(alpha: 0.75),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Inactive Squircle
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: colors.inactivePill.withValues(alpha: _cardOpacity),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Icon(Icons.bluetooth, color: colors.onInactivePill, size: 20),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 2. Acrylic Notification Card
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: _blurIntensity,
                                sigmaY: _blurIntensity,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: cardGlassBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: colors.activePill.withValues(alpha: 0.25),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.message_rounded, size: 12, color: colors.activePill),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Messages • now',
                                          style: state.selectedFont.textStyleBuilder(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Hey! Check out this acrylic blur and opacity...',
                                      style: state.selectedFont.textStyleBuilder(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: colors.activePill.withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Reply',
                                            style: state.selectedFont.textStyleBuilder(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: colors.activePill,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Color Picker Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Custom Color Spectrum',
                  style: state.selectedFont.textStyleBuilder(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                // Hex Code Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _selectedSeed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _selectedSeed, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _selectedSeed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _colorToHex(_selectedSeed),
                        style: state.selectedFont.textStyleBuilder(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Hue Slider with Rainbow Track
            Text(
              'Hue (${_currentHue.toInt()}°)',
              style: state.selectedFont.textStyleBuilder(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF0000), // Red
                    Color(0xFFFFFF00), // Yellow
                    Color(0xFF00FF00), // Green
                    Color(0xFF00FFFF), // Cyan
                    Color(0xFF0000FF), // Blue
                    Color(0xFFFF00FF), // Magenta
                    Color(0xFFFF0000), // Red
                  ],
                ),
              ),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 28,
                  trackShape: const RoundedRectSliderTrackShape(),
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12, elevation: 4),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: _currentHue,
                  min: 0,
                  max: 360,
                  onChanged: (val) {
                    setState(() {
                      _currentHue = val;
                      _updateColorFromHsv();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Saturation & Vibrancy Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saturation (${(_currentSaturation * 100).toInt()}%)',
                  style: state.selectedFont.textStyleBuilder(
                    fontSize: 13,
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  'Brightness (${(_currentValue * 100).toInt()}%)',
                  style: state.selectedFont.textStyleBuilder(
                    fontSize: 13,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            Slider(
              value: _currentSaturation,
              min: 0.2,
              max: 1.0,
              activeColor: _selectedSeed,
              inactiveColor: colors.sliderTrack,
              onChanged: (val) {
                setState(() {
                  _currentSaturation = val;
                  _updateColorFromHsv();
                });
              },
            ),
            const SizedBox(height: 12),

            // Curated Quick Color Chips
            Text(
              'Curated Presets',
              style: state.selectedFont.textStyleBuilder(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _curatedSeedColors.map((color) {
                final isSelected = _selectedSeed == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSeed = color;
                      final hsv = HSVColor.fromColor(color);
                      _currentHue = hsv.hue;
                      _currentSaturation = hsv.saturation;
                      _currentValue = hsv.value;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? colors.textPrimary : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: color.withValues(alpha: 0.45),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // AMOLED Pitch-Black Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'AMOLED Deep Black',
                style: state.selectedFont.textStyleBuilder(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Pure #000000 background for maximum OLED battery savings & deep contrast',
                style: state.selectedFont.textStyleBuilder(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
              value: _isAmoled,
              activeTrackColor: colors.activePill.withValues(alpha: 0.5),
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.activePill;
                }
                return colors.inactivePill;
              }),
              onChanged: (val) {
                setState(() {
                  _isAmoled = val;
                });
              },
            ),
            const SizedBox(height: 16),

            // Card Opacity Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Card Opacity',
                  style: state.selectedFont.textStyleBuilder(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '${(_cardOpacity * 100).toInt()}%',
                  style: state.selectedFont.textStyleBuilder(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.activePill,
                  ),
                ),
              ],
            ),
            Slider(
              value: _cardOpacity,
              min: 0.30,
              max: 1.0,
              activeColor: colors.activePill,
              inactiveColor: colors.sliderTrack,
              onChanged: (val) {
                setState(() {
                  _cardOpacity = val;
                });
              },
            ),
            const SizedBox(height: 12),

            // Acrylic Blur Intensity Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Acrylic Blur Intensity',
                  style: state.selectedFont.textStyleBuilder(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '${_blurIntensity.toInt()}px',
                  style: state.selectedFont.textStyleBuilder(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.activePill,
                  ),
                ),
              ],
            ),
            Slider(
              value: _blurIntensity,
              min: 0,
              max: 40,
              activeColor: colors.activePill,
              inactiveColor: colors.sliderTrack,
              onChanged: (val) {
                setState(() {
                  _blurIntensity = val;
                });
              },
            ),
            const SizedBox(height: 24),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.activePill,
                  foregroundColor: colors.onActivePill,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  state.updateCustomTheme(CustomThemeData(
                    primaryColor: _selectedSeed,
                    isAmoled: _isAmoled,
                    cardOpacity: _cardOpacity,
                    blurIntensity: _blurIntensity,
                  ));
                  Navigator.pop(context);
                },
                child: Text(
                  'Apply Custom Theme',
                  style: state.selectedFont.textStyleBuilder(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.onActivePill,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
