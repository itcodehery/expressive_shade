import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    final themeColors = ExpressiveThemeColors.fromSettings(
      source: state.themeSource,
      preset: state.selectedPreset,
      custom: state.customTheme,
      systemMonetColor: state.systemMonetColor,
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
                  switch (state.shadeMode) {
                    ShadeMode.split => Icons.splitscreen_rounded,
                    ShadeMode.smart => Icons.grid_view_rounded,
                    ShadeMode.nothingOs5 => Icons.dashboard_customize_rounded,
                    ShadeMode.unified => Icons.view_stream_rounded,
                  },
                  size: 16,
                  color: themeColors.activePill,
                ),
                const SizedBox(width: 6),
                Text(
                  switch (state.shadeMode) {
                    ShadeMode.split => 'Split',
                    ShadeMode.smart => 'Matrix',
                    ShadeMode.nothingOs5 => 'NothingOS 5',
                    ShadeMode.unified => 'Unified',
                  },
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
          InteractiveShadeCanvas(
            colors: themeColors,
            onOpenShadeApp: () {
              setState(() {
                _currentNavIndex = 1;
              });
            },
          ),
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
          HapticFeedback.selectionClick();
          setState(() {
            _currentNavIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.touch_app_outlined,
              color: themeColors.textSecondary,
            ),
            selectedIcon: Icon(
              Icons.touch_app_rounded,
              color: themeColors.textPrimary,
            ),
            label: 'Live Shade',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.dashboard_customize_outlined,
              color: themeColors.textSecondary,
            ),
            selectedIcon: Icon(
              Icons.dashboard_customize_rounded,
              color: themeColors.textPrimary,
            ),
            label: 'Layout',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.palette_outlined,
              color: themeColors.textSecondary,
            ),
            selectedIcon: Icon(
              Icons.palette_rounded,
              color: themeColors.textPrimary,
            ),
            label: 'Theming',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.font_download_outlined,
              color: themeColors.textSecondary,
            ),
            selectedIcon: Icon(
              Icons.font_download_rounded,
              color: themeColors.textPrimary,
            ),
            label: 'Fonts',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined, color: themeColors.textSecondary),
            selectedIcon: Icon(
              Icons.shield_rounded,
              color: themeColors.textPrimary,
            ),
            label: 'Service',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: themeColors.activePill,
        foregroundColor: themeColors.onActivePill,
        elevation: 4,
        icon: const Icon(Icons.sync_rounded),
        label: Text(
          'Update Shade',
          style: state.selectedFont.textStyleBuilder(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: themeColors.onActivePill,
          ),
        ),
        onPressed: () => _updateShade(state, themeColors),
      ),
    );
  }

  Future<void> _updateShade(
    ShadeStateProvider state,
    ExpressiveThemeColors themeColors,
  ) async {
    HapticFeedback.mediumImpact();
    await state.applyAndSyncToShade();
    await SystemPermissionsService.deployCustomShade('quick_settings');
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: themeColors.onActivePill,
                size: 20,
              ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }
}
