import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/font_config.dart';
import '../models/shade_mode.dart';
import '../models/shade_theme.dart';
import '../models/slider_style.dart';
import '../providers/shade_state_provider.dart';
import '../services/system_permissions_service.dart';
import '../theme/m3_expressive_theme.dart';
import '../widgets/custom_theme_builder_sheet.dart';
import '../widgets/expressive_slider.dart';
import '../widgets/interactive_shade_canvas.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      context.read<ShadeStateProvider>().refreshPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShadeStateProvider>();
    final themeColors = ExpressiveThemeColors.fromSettings(
      source: state.themeSource,
      preset: state.selectedPreset,
      custom: state.customTheme,
      systemMonetColor: state.systemMonetColor,
      isSystemDark: Theme.of(context).brightness == Brightness.dark,
    );

    return Scaffold(
      backgroundColor: themeColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'ExpressiveShade',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: themeColors.textPrimary,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: themeColors.activePill.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.shadeMode == ShadeMode.split ? Icons.splitscreen_rounded : Icons.view_stream_rounded,
                  size: 16,
                  color: themeColors.activePill,
                ),
                const SizedBox(width: 6),
                Text(
                  state.shadeMode == ShadeMode.split ? 'Split' : 'Unified',
                  style: state.selectedFont.textStyleBuilder(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: themeColors.activePill,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          InteractiveShadeCanvas(colors: themeColors),
          _buildLayoutScreen(context, state, themeColors),
          _buildThemeScreen(context, state, themeColors),
          _buildFontScreen(context, state, themeColors),
          _buildServiceScreen(context, state, themeColors),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        backgroundColor: themeColors.surface,
        indicatorColor: themeColors.activePill.withValues(alpha: 0.25),
        onDestinationSelected: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.touch_app_outlined, color: themeColors.textSecondary),
            selectedIcon: Icon(Icons.touch_app_rounded, color: themeColors.textPrimary),
            label: 'Live Shade',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_customize_outlined, color: themeColors.textSecondary),
            selectedIcon: Icon(Icons.dashboard_customize_rounded, color: themeColors.textPrimary),
            label: 'Layout',
          ),
          NavigationDestination(
            icon: Icon(Icons.palette_outlined, color: themeColors.textSecondary),
            selectedIcon: Icon(Icons.palette_rounded, color: themeColors.textPrimary),
            label: 'Theming',
          ),
          NavigationDestination(
            icon: Icon(Icons.font_download_outlined, color: themeColors.textSecondary),
            selectedIcon: Icon(Icons.font_download_rounded, color: themeColors.textPrimary),
            label: 'Fonts',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined, color: themeColors.textSecondary),
            selectedIcon: Icon(Icons.shield_rounded, color: themeColors.textPrimary),
            label: 'Service',
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutScreen(
    BuildContext context,
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Shade Mode Architecture',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose between Android 17\'s separate notifications / control center, or the classic single pull-down shade.',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        ...ShadeMode.values.map((mode) {
          final isSelected = state.shadeMode == mode;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => state.setShadeMode(mode),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected ? colors.activePill.withValues(alpha: 0.15) : colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? colors.activePill : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      mode == ShadeMode.split ? Icons.splitscreen_rounded : Icons.view_stream_rounded,
                      size: 32,
                      color: isSelected ? colors.activePill : colors.textSecondary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode.displayName,
                            style: state.selectedFont.textStyleBuilder(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mode.description,
                            style: state.selectedFont.textStyleBuilder(
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? colors.activePill : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? colors.activePill : colors.textSecondary.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors.onActivePill,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 28),
        Text(
          'Slider Style',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Customize the visual ergonomic appearance of brightness and volume thick sliders.',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        ...SliderStyle.values.map((style) {
          final isSelected = state.sliderStyle == style;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                HapticFeedback.lightImpact();
                state.setSliderStyle(style);
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected ? colors.activePill.withValues(alpha: 0.15) : colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? colors.activePill : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                style.displayName,
                                style: state.selectedFont.textStyleBuilder(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                style.description,
                                style: state.selectedFont.textStyleBuilder(
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? colors.activePill : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? colors.activePill : colors.textSecondary.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colors.onActivePill,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    IgnorePointer(
                      child: ExpressiveSlider(
                        value: 0.72,
                        onChanged: (_) {},
                        leadingIcon: Icons.wb_sunny_rounded,
                        colors: colors,
                        height: 48,
                        style: style,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildThemeScreen(
    BuildContext context,
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Dynamic Theming Engine',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Adapts automatically to system wallpaper dynamic colors, curated Material 3 Expressive palettes, or custom user creations.',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // Active Palette Swatch Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colors.activePill.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CURRENT PALETTE',
                    style: state.selectedFont.textStyleBuilder(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.activePill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      state.themeSource == ThemeSource.system
                          ? 'Monet Dynamic'
                          : (state.themeSource == ThemeSource.custom
                              ? 'Custom Theme'
                              : state.selectedPreset.name),
                      style: state.selectedFont.textStyleBuilder(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.onActivePill,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildColorSample(colors.background, 'Background', colors.textSecondary, state),
                  const SizedBox(width: 10),
                  _buildColorSample(colors.activePill, 'Active Pill', colors.textSecondary, state),
                  const SizedBox(width: 10),
                  _buildColorSample(colors.inactivePill, 'Inactive Pill', colors.textSecondary, state),
                  const SizedBox(width: 10),
                  _buildColorSample(colors.sliderProgress, 'Accent', colors.textSecondary, state),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // System Theme Tile
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => state.setThemeSource(ThemeSource.system),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: state.themeSource == ThemeSource.system ? colors.activePill.withValues(alpha: 0.15) : colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: state.themeSource == ThemeSource.system ? colors.activePill : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 28,
                  color: state.themeSource == ThemeSource.system ? colors.activePill : colors.textSecondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Dynamic (Monet)',
                        style: state.selectedFont.textStyleBuilder(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pulls dynamic accent and tonal palettes directly from Android wallpaper',
                        style: state.selectedFont.textStyleBuilder(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.themeSource == ThemeSource.system)
                  Icon(Icons.check_circle_rounded, color: colors.activePill, size: 24),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Custom Theme Creator Tile
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            state.setThemeSource(ThemeSource.custom);
            CustomThemeBuilderSheet.show(context);
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: state.themeSource == ThemeSource.custom ? colors.activePill.withValues(alpha: 0.15) : colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: state.themeSource == ThemeSource.custom ? colors.activePill : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: state.customTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Custom Theme Studio',
                        style: state.selectedFont.textStyleBuilder(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.customTheme.isAmoled
                            ? 'AMOLED Black • Custom Accent Color'
                            : 'Personalized Accent & Blur Settings',
                        style: state.selectedFont.textStyleBuilder(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    CustomThemeBuilderSheet.show(context);
                  },
                  child: Text(
                    'Customize',
                    style: state.selectedFont.textStyleBuilder(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.activePill,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        Text(
          'Expressive Presets',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...ThemePreset.presets.map((preset) {
          final isSelected = state.themeSource == ThemeSource.preset && state.selectedPreset.id == preset.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => state.selectPreset(preset),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? colors.activePill.withValues(alpha: 0.15) : colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? colors.activePill : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: preset.activePill,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24, width: 1.5),
                      ),
                      child: Center(
                        child: Icon(Icons.circle, size: 14, color: preset.onActivePill),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preset.name,
                            style: state.selectedFont.textStyleBuilder(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            preset.description,
                            style: state.selectedFont.textStyleBuilder(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: colors.activePill, size: 24),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildColorSample(Color color, String label, Color textColor, ShadeStateProvider state) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24, width: 1),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: state.selectedFont.textStyleBuilder(
              fontSize: 10,
              color: textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFontScreen(
    BuildContext context,
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Typography & Font Selector',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose font family to be applied across the entire notification shade and control center.',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        ...FontConfig.availableFonts.map((font) {
          final isSelected = state.selectedFont.id == font.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => state.setFont(font),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected ? colors.activePill.withValues(alpha: 0.15) : colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? colors.activePill : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            font.name,
                            style: font.textStyleBuilder(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            font.sampleText,
                            style: font.textStyleBuilder(
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: colors.activePill, size: 24),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildServiceScreen(
    BuildContext context,
    ShadeStateProvider state,
    ExpressiveThemeColors colors,
  ) {
    final permissions = state.permissions;
    final isOverlay = permissions['overlay'] ?? false;
    final isAccessibility = permissions['accessibility'] ?? false;
    final isNotification = permissions['notification'] ?? false;
    final isWriteSettings = permissions['writeSettings'] ?? false;
    final canEnable = state.areCorePermissionsGranted;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'System Service & Permissions',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ExpressiveShade replaces the stock notification shade by combining an accessibility gesture listener with a hardware-accelerated overlay window.',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Master Service Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: state.isServiceEnabled
                ? colors.activePill.withValues(alpha: 0.18)
                : colors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: state.isServiceEnabled ? colors.activePill : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              if (state.isServiceEnabled)
                BoxShadow(
                  color: colors.activePill.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: state.isServiceEnabled ? colors.activePill : colors.inactivePill,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  state.isServiceEnabled ? Icons.power_settings_new_rounded : Icons.power_off_rounded,
                  color: state.isServiceEnabled ? colors.onActivePill : colors.onInactivePill,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.isServiceEnabled ? 'Shade Service Active' : 'Shade Service Stopped',
                      style: state.selectedFont.textStyleBuilder(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      canEnable
                          ? (state.isServiceEnabled
                              ? 'Pull down from top of screen to open'
                              : 'Ready to start service')
                          : 'Core permissions required to activate',
                      style: state.selectedFont.textStyleBuilder(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: state.isServiceEnabled,
                activeTrackColor: colors.activePill.withValues(alpha: 0.5),
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return colors.activePill;
                  }
                  return colors.inactivePill;
                }),
                onChanged: canEnable
                    ? (val) {
                        HapticFeedback.mediumImpact();
                        state.setServiceEnabled(val);
                      }
                    : (_) {
                        HapticFeedback.heavyImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please grant Overlay and Accessibility permissions first',
                              style: state.selectedFont.textStyleBuilder(color: Colors.white),
                            ),
                            backgroundColor: colors.surface,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        );
                      },
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Section Title: Required Permissions
        Text(
          'Required Permissions',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        // 1. Overlay Permission Card
        _buildPermissionItem(
          icon: Icons.layers_rounded,
          title: 'Draw Over Other Apps',
          description: 'Allows displaying the custom Material 3 Expressive shade above all apps and system UI.',
          isGranted: isOverlay,
          onTap: () => SystemPermissionsService.requestOverlayPermission(),
          state: state,
          colors: colors,
        ),
        const SizedBox(height: 12),

        // 2. Accessibility Service Card
        _buildPermissionItem(
          icon: Icons.accessibility_new_rounded,
          title: 'Accessibility Gesture Service',
          description: 'Detects top status bar pull-down gestures to deploy ExpressiveShade smoothly.',
          isGranted: isAccessibility,
          onTap: () => SystemPermissionsService.requestAccessibilityPermission(),
          state: state,
          colors: colors,
        ),
        const SizedBox(height: 24),

        // Section Title: Optional Enhancements
        Text(
          'Enhanced Features (Recommended)',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        // 3. Notification Access
        _buildPermissionItem(
          icon: Icons.notifications_active_rounded,
          title: 'Notification Listener Access',
          description: 'Intercepts incoming alerts to render them inside custom M3 cards with inline quick replies.',
          isGranted: isNotification,
          onTap: () => SystemPermissionsService.requestNotificationPermission(),
          state: state,
          colors: colors,
        ),
        const SizedBox(height: 12),

        // 4. Modify System Settings
        _buildPermissionItem(
          icon: Icons.brightness_medium_rounded,
          title: 'Modify System Settings',
          description: 'Enables the thick pill slider to adjust device hardware screen brightness directly.',
          isGranted: isWriteSettings,
          onTap: () => SystemPermissionsService.requestWriteSettingsPermission(),
          state: state,
          colors: colors,
        ),
        const SizedBox(height: 24),

        // Action Buttons: Refresh & App Info
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: colors.activePill,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                state.refreshPermissions();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Refresh Status',
                style: state.selectedFont.textStyleBuilder(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.activePill,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: colors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                SystemPermissionsService.openAppDetailsSettings();
              },
              icon: const Icon(Icons.info_outline_rounded, size: 18),
              label: Text(
                'App Info',
                style: state.selectedFont.textStyleBuilder(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
    required ShadeStateProvider state,
    required ExpressiveThemeColors colors,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isGranted ? Colors.green.withValues(alpha: 0.4) : colors.textSecondary.withValues(alpha: 0.15),
            width: isGranted ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isGranted
                    ? Colors.green.withValues(alpha: 0.18)
                    : colors.activePill.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: isGranted ? Colors.greenAccent.shade700 : colors.activePill,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: state.selectedFont.textStyleBuilder(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isGranted
                              ? Colors.green.withValues(alpha: 0.18)
                              : Colors.amber.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isGranted ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                              size: 13,
                              color: isGranted ? Colors.greenAccent.shade700 : Colors.amber.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isGranted ? 'Granted' : 'Setup',
                              style: state.selectedFont.textStyleBuilder(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isGranted ? Colors.greenAccent.shade700 : Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: state.selectedFont.textStyleBuilder(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
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
