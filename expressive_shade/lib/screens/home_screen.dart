import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';
import '../models/shade_mode.dart';
import '../providers/shade_state_provider.dart';
import '../services/system_permissions_service.dart';
import '../theme/m3_expressive_theme.dart';
import '../widgets/interactive_shade_canvas.dart';
import 'home/font_tab.dart';
import 'home/layout_tab.dart';
import 'home/service_tab.dart';
import 'home/theme_tab.dart';

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
    final isPlatformDark = Theme.of(context).brightness == Brightness.dark;
    final isDark = state.themeMode == ThemeMode.system
        ? isPlatformDark
        : (state.themeMode == ThemeMode.dark);

    final themeColors = ExpressiveThemeColors.fromSettings(
      source: state.themeSource,
      preset: state.selectedPreset,
      custom: state.customTheme,
      systemMonetColor: state.systemMonetColor,
      isDark: isDark,
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
          // Quick Dark/Light Toggle Action
          IconButton(
            tooltip: state.isDarkMode ? 'Switch to Caramel Light' : 'Switch to Forest Green Dark',
            icon: Icon(
              state.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: themeColors.textPrimary,
              size: 22,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              state.toggleDarkLightMode();
            },
          ),
          const SizedBox(width: 4),
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
          LayoutTab(colors: themeColors),
          ThemeTab(colors: themeColors),
          FontTab(colors: themeColors),
          ServiceTab(colors: themeColors),
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
      floatingActionButton: M3EExtendedFab(
        icon: const Icon(Icons.sync_rounded),
        label: 'Update Shade',
        color: M3EFabColor.primary,
        onPressed: () async {
          HapticFeedback.mediumImpact();
          await state.applyAndSyncToShade();
          await SystemPermissionsService.deployCustomShade('quick_settings');
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: themeColors.onActivePill, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Shade updated & opened with latest settings!',
                      style: state.selectedFont.textStyleBuilder(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: themeColors.onActivePill,
                      ),
                    ),
                  ],
                ),
                backgroundColor: themeColors.activePill,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            );
          }
        },
      ),
    );
  }
}
