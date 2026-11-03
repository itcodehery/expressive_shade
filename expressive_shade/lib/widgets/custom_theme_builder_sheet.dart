import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shade_theme.dart';
import '../providers/shade_state_provider.dart';
import '../theme/m3_expressive_theme.dart';

enum ThemeColorRole {
  background('Background'),
  activePill('Active Pill'),
  inactivePill('Inactive Pill'),
  accent('Accent');

  final String label;
  const ThemeColorRole(this.label);
}

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
  late Color _backgroundColor;
  late Color _activePillColor;
  late Color _inactivePillColor;
  late Color _accentColor;
  late bool _isAmoled;
  ThemeColorRole _selectedRole = ThemeColorRole.background;

  late TextEditingController _hexController;
  late double _currentHue;
  late double _currentSaturation;
  late double _currentValue;

  static const List<Color> _curatedSeedColors = [
    Color(0xFF141416), // Dark Slate
    Color(0xFF000000), // Pure Black
    Color(0xFF101712), // Deep Forest
    Color(0xFF0E1A22), // Arctic Night
    Color(0xFF1E130B), // Sunset Dusk
    Color(0xFF1C0E13), // Ruby Velvet
    Color(0xFF140D24), // Cosmic Violet
    Color(0xFF2E7D32), // Forest Green
    Color(0xFF059669), // Emerald
    Color(0xFF0284C7), // Glacial Sky
    Color(0xFF2563EB), // Cobalt Blue
    Color(0xFF7C3AED), // Expressive Violet
    Color(0xFFE11D48), // Rose Crimson
    Color(0xFFEA580C), // Tangelo Orange
    Color(0xFFD97706), // Warm Amber
    Color(0xFFFB923C), // Amber Glow
    Color(0xFFB2DEC3), // Sage Green
    Color(0xFF90DCF8), // Ice Cyan
    Color(0xFFC7D2FE), // Soft Lavender
    Color(0xFF272930), // Inactive Pill Dark
    Color(0xFF33363E), // Inactive Pill M3
    Color(0xFFE5E7EB), // Inactive Pill Light
    Color(0xFFF8FAFC), // Off-white Clean
    Color(0xFFFFFFFF), // Pure White
  ];

  @override
  void initState() {
    super.initState();
    final current = context.read<ShadeStateProvider>().customTheme;
    _isAmoled = current.isAmoled;
    _backgroundColor = current.customBackground ??
        (_isAmoled ? Colors.black : const Color(0xFF141416));
    _activePillColor = current.customActivePill ?? current.primaryColor;
    _inactivePillColor = current.customInactivePill ?? const Color(0xFF272930);
    _accentColor = current.customAccent ?? current.primaryColor;

    final hsv = HSVColor.fromColor(_backgroundColor);
    _currentHue = hsv.hue;
    _currentSaturation = hsv.saturation;
    _currentValue = hsv.value;
    _hexController = TextEditingController(text: _colorToHex(_backgroundColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color get _currentRoleColor {
    switch (_selectedRole) {
      case ThemeColorRole.background:
        return _backgroundColor;
      case ThemeColorRole.activePill:
        return _activePillColor;
      case ThemeColorRole.inactivePill:
        return _inactivePillColor;
      case ThemeColorRole.accent:
        return _accentColor;
    }
  }

  void _setCurrentRoleColor(Color color) {
    setState(() {
      switch (_selectedRole) {
        case ThemeColorRole.background:
          _backgroundColor = color;
          break;
        case ThemeColorRole.activePill:
          _activePillColor = color;
          break;
        case ThemeColorRole.inactivePill:
          _inactivePillColor = color;
          break;
        case ThemeColorRole.accent:
          _accentColor = color;
          break;
      }
      final hsv = HSVColor.fromColor(color);
      _currentHue = hsv.hue;
      _currentSaturation = hsv.saturation;
      _currentValue = hsv.value;
      _hexController.text = _colorToHex(color);
    });
  }

  void _switchRole(ThemeColorRole role) {
    setState(() {
      _selectedRole = role;
      final c = _currentRoleColor;
      final hsv = HSVColor.fromColor(c);
      _currentHue = hsv.hue;
      _currentSaturation = hsv.saturation;
      _currentValue = hsv.value;
      _hexController.text = _colorToHex(c);
    });
  }

  void _updateColorFromHsv() {
    final color = HSVColor.fromAHSV(1.0, _currentHue, _currentSaturation, _currentValue).toColor();
    setState(() {
      switch (_selectedRole) {
        case ThemeColorRole.background:
          _backgroundColor = color;
          break;
        case ThemeColorRole.activePill:
          _activePillColor = color;
          break;
        case ThemeColorRole.inactivePill:
          _inactivePillColor = color;
          break;
        case ThemeColorRole.accent:
          _accentColor = color;
          break;
      }
      _hexController.text = _colorToHex(color);
    });
  }

  void _onHexSubmitted(String text) {
    String clean = text.replaceAll('#', '').trim();
    if (clean.length == 6) {
      try {
        final color = Color(int.parse('0xFF$clean'));
        _setCurrentRoleColor(color);
      } catch (_) {}
    } else if (clean.length == 8) {
      try {
        final color = Color(int.parse('0x$clean'));
        _setCurrentRoleColor(color);
      } catch (_) {}
    }
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

    final previewTheme = CustomThemeData(
      primaryColor: _accentColor,
      isAmoled: _isAmoled,
      cardOpacity: 1.0,
      blurIntensity: 0.0,
      customBackground: _isAmoled ? Colors.black : _backgroundColor,
      customActivePill: _activePillColor,
      customInactivePill: _inactivePillColor,
      customAccent: _accentColor,
    );

    final colors = ExpressiveThemeColors.fromSettings(
      source: ThemeSource.custom,
      preset: state.selectedPreset,
      custom: previewTheme,
      systemMonetColor: state.systemMonetColor,
    );

    final currentColor = _currentRoleColor;

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
              'Customize Background, Active Pill, Inactive Pill, and Accent individually with live preview.',
              style: state.selectedFont.textStyleBuilder(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),

            // Live Realistic Card Preview (Solid, fully opaque)
            Text(
              'LIVE THEME PREVIEW',
              style: state.selectedFont.textStyleBuilder(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.textSecondary.withValues(alpha: 0.2),
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row of simulated Quick Settings Pills
                  Row(
                    children: [
                      // Active Pill
                      Expanded(
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: colors.activePill,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.wifi_rounded, color: colors.onActivePill, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Wi-Fi',
                                      style: state.selectedFont.textStyleBuilder(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: colors.onActivePill,
                                      ),
                                    ),
                                    Text(
                                      'Connected',
                                      style: state.selectedFont.textStyleBuilder(
                                        fontSize: 10.5,
                                        color: colors.onActivePill.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Inactive Pill
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: colors.inactivePill,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.bluetooth_rounded, color: colors.onInactivePill, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Simulated Notification Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colors.textSecondary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notifications_active_rounded, size: 14, color: colors.activePill),
                            const SizedBox(width: 6),
                            Text(
                              'Expressive Preview',
                              style: state.selectedFont.textStyleBuilder(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Individual color styling is live and responsive.',
                          style: state.selectedFont.textStyleBuilder(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Action Text Button (No bg)
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Text(
                                'Reply',
                                style: state.selectedFont.textStyleBuilder(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w700,
                                  color: colors.activePill,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Text(
                                'Dismiss',
                                style: state.selectedFont.textStyleBuilder(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Color Role Selector Tabs
            Text(
              'SELECT COLOR PROPERTY TO EDIT',
              style: state.selectedFont.textStyleBuilder(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ThemeColorRole.values.map((role) {
                  final isSelected = _selectedRole == role;
                  final roleColor = switch (role) {
                    ThemeColorRole.background => _backgroundColor,
                    ThemeColorRole.activePill => _activePillColor,
                    ThemeColorRole.inactivePill => _inactivePillColor,
                    ThemeColorRole.accent => _accentColor,
                  };

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _switchRole(role),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.activePill.withValues(alpha: 0.18)
                              : colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? colors.activePill : colors.textSecondary.withValues(alpha: 0.2),
                            width: isSelected ? 1.6 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: roleColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.textSecondary.withValues(alpha: 0.3),
                                  width: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              role.label,
                              style: state.selectedFont.textStyleBuilder(
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? colors.activePill : colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // Direct Hex Code Input & Indicator
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editing ${_selectedRole.label} Color',
                        style: state.selectedFont.textStyleBuilder(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Type hex code or use spectrum slider below',
                        style: state.selectedFont.textStyleBuilder(
                          fontSize: 11.5,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Hex Code Input Field
                Container(
                  width: 120,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: currentColor, width: 1.5),
                  ),
                  child: TextField(
                    controller: _hexController,
                    onChanged: _onHexSubmitted,
                    onSubmitted: _onHexSubmitted,
                    textAlign: TextAlign.center,
                    style: state.selectedFont.textStyleBuilder(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Color Spectrum Hue Slider
            Text(
              'Hue (${_currentHue.toInt()}°)',
              style: state.selectedFont.textStyleBuilder(
                fontSize: 12.5,
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
                    Color(0xFFFF0000),
                    Color(0xFFFFFF00),
                    Color(0xFF00FF00),
                    Color(0xFF00FFFF),
                    Color(0xFF0000FF),
                    Color(0xFFFF00FF),
                    Color(0xFFFF0000),
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
                    _currentHue = val;
                    _updateColorFromHsv();
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Saturation & Brightness Sliders
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saturation (${(_currentSaturation * 100).toInt()}%)',
                  style: state.selectedFont.textStyleBuilder(
                    fontSize: 12.5,
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  'Brightness (${(_currentValue * 100).toInt()}%)',
                  style: state.selectedFont.textStyleBuilder(
                    fontSize: 12.5,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _currentSaturation,
                    min: 0.0,
                    max: 1.0,
                    activeColor: currentColor,
                    inactiveColor: colors.sliderTrack,
                    onChanged: (val) {
                      _currentSaturation = val;
                      _updateColorFromHsv();
                    },
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _currentValue,
                    min: 0.0,
                    max: 1.0,
                    activeColor: currentColor,
                    inactiveColor: colors.sliderTrack,
                    onChanged: (val) {
                      _currentValue = val;
                      _updateColorFromHsv();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Curated Quick Palette Swatches
            Text(
              'Quick Color Swatches',
              style: state.selectedFont.textStyleBuilder(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _curatedSeedColors.map((color) {
                final isSelected = currentColor.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () => _setCurrentRoleColor(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? colors.textPrimary : Colors.white.withValues(alpha: 0.2),
                        width: isSelected ? 2.5 : 1.0,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // AMOLED Pitch-Black Toggle (only relevant for Background)
            if (_selectedRole == ThemeColorRole.background) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'AMOLED Deep Black',
                  style: state.selectedFont.textStyleBuilder(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Pure #000000 background for OLED battery savings',
                  style: state.selectedFont.textStyleBuilder(
                    fontSize: 11.5,
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
                    if (val) {
                      _backgroundColor = Colors.black;
                      _setCurrentRoleColor(Colors.black);
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.activePill,
                  foregroundColor: colors.onActivePill,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  state.updateCustomTheme(CustomThemeData(
                    primaryColor: _accentColor,
                    isAmoled: _isAmoled,
                    cardOpacity: 1.0,
                    blurIntensity: 0.0,
                    customBackground: _isAmoled ? Colors.black : _backgroundColor,
                    customActivePill: _activePillColor,
                    customInactivePill: _inactivePillColor,
                    customAccent: _accentColor,
                  ));
                  Navigator.pop(context);
                },
                child: Text(
                  'Apply Custom Theme',
                  style: state.selectedFont.textStyleBuilder(
                    fontSize: 15.5,
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
