import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/font_config.dart';
import '../../models/media_player_style.dart';
import '../../models/notification_model.dart';
import '../../models/notification_style.dart';
import '../../models/qs_tile_model.dart';
import '../../models/shade_mode.dart';
import '../../models/shade_theme.dart';
import '../../models/slider_style.dart';
import '../../providers/shade_state_provider.dart';
import '../../theme/m3_expressive_theme.dart';
import '../../features/notifications/notification_card.dart';
import '../../widgets/expressive_media_card.dart';
import '../../widgets/expressive_slider.dart';
import 'font_tab.dart';
import 'theme_tab.dart';

/// Pixel / Android Settings styled Layout & Customization Tab.
/// Organizes all shade options (Theming, Typography, Architecture, Sliders,
/// Media Player, and Notifications) into grouped Material 3 cards with
/// dedicated submenus for rich interactive previews and selectors.
class LayoutTab extends StatefulWidget {
  final ExpressiveThemeColors colors;

  const LayoutTab({super.key, required this.colors});

  @override
  State<LayoutTab> createState() => _LayoutTabState();
}

/// Alias for LayoutTab renamed to Settings
typedef SettingsTab = LayoutTab;

class _LayoutTabState extends State<LayoutTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShadeStateProvider>();
    final font = state.selectedFont;
    final colors = widget.colors;

    final query = _searchQuery.trim().toLowerCase();

    // Define all setting items for filtering and navigation
    final allItems = [
      // 1. Theming & Colors
      _LayoutSettingItem(
        id: 'theming',
        group: 'Display & Styling',
        title: 'Theming & Colors',
        subtitle: switch (state.themeSource) {
          ThemeSource.preset => 'Preset • ${state.selectedPreset.name}',
          ThemeSource.system => 'Dynamic Monet • System wallpaper color',
          ThemeSource.custom => 'Custom Studio • ${((state.customTheme.backgroundOpacity ?? 1.0) * 100).toInt()}% opacity',
        },
        icon: Icons.palette_rounded,
        badgeBg: colors.isDark ? const Color(0xFF4C2A3C) : const Color(0xFFFFD8E4),
        badgeFg: colors.isDark ? const Color(0xFFFFB0CD) : const Color(0xFFB31B5B),
        keywords: ['theme', 'theming', 'colors', 'monet', 'palette', 'custom', 'opacity', 'blur', 'dark', 'light'],
        onTap: () => _navigateTo(context, ThemingSubmenu(colors: colors)),
      ),

      // 2. Typography & Fonts
      _LayoutSettingItem(
        id: 'fonts',
        group: 'Display & Styling',
        title: 'Typography & Fonts',
        subtitle: '${state.selectedFont.name} • ${state.selectedFont.sampleText}',
        icon: Icons.font_download_rounded,
        badgeBg: colors.isDark ? const Color(0xFF1E3A4A) : const Color(0xFFD0E8F2),
        badgeFg: colors.isDark ? const Color(0xFF70C5E8) : const Color(0xFF00678F),
        keywords: ['font', 'fonts', 'typography', 'sans', 'google sans', 'outfit', 'dot', 'text'],
        onTap: () => _navigateTo(context, FontsSubmenu(colors: colors)),
      ),

      // 3. Shade Mode Architecture
      _LayoutSettingItem(
        id: 'shade_mode',
        group: 'Architecture & System',
        title: 'Shade Mode Architecture',
        subtitle: '${state.shadeMode.displayName} • ${state.shadeMode.description}',
        icon: Icons.splitscreen_rounded,
        badgeBg: colors.isDark ? const Color(0xFF1B3B6F) : const Color(0xFFD3E3FD),
        badgeFg: colors.isDark ? const Color(0xFFA8C7FA) : const Color(0xFF0454D6),
        keywords: ['shade', 'split', 'unified', 'matrix', 'nothing', 'architecture', 'mode', 'panel'],
        onTap: () => _navigateTo(context, ShadeModeSubmenu(colors: colors)),
      ),

      // 4. Network Tile Configuration
      _LayoutSettingItem(
        id: 'network_tile',
        group: 'Architecture & System',
        title: 'Network Tile Configuration',
        subtitle: state.networkTileStyle == NetworkTileStyle.unified
            ? 'Unified Internet pill (Wi-Fi + Mobile data)'
            : 'Separate Wi-Fi & Mobile Data tiles',
        icon: Icons.wifi_rounded,
        badgeBg: colors.isDark ? const Color(0xFF144B48) : const Color(0xFFCCE8E7),
        badgeFg: colors.isDark ? const Color(0xFF80D5D4) : const Color(0xFF006A67),
        keywords: ['network', 'wifi', 'internet', 'cellular', 'mobile', 'data', 'tiles'],
        onTap: () => _navigateTo(context, NetworkTileSubmenu(colors: colors)),
      ),

      // 5. Slider Style
      _LayoutSettingItem(
        id: 'slider_style',
        group: 'Ergonomics & Controls',
        title: 'Slider Style',
        subtitle: '${state.sliderStyle.displayName} • ${state.sliderStyle.description}',
        icon: Icons.tune_rounded,
        badgeBg: colors.isDark ? const Color(0xFF4A3810) : const Color(0xFFFFECC4),
        badgeFg: colors.isDark ? const Color(0xFFFFBA39) : const Color(0xFF825500),
        keywords: ['slider', 'brightness', 'volume', 'controls', 'pill', 'minimal', 'outline'],
        onTap: () => _navigateTo(context, SliderStyleSubmenu(colors: colors)),
      ),

      // 6. Media Player Style
      _LayoutSettingItem(
        id: 'media_player',
        group: 'Media & Notifications',
        title: 'Media Player Layout Style',
        subtitle: '${state.mediaPlayerStyle.displayName}${state.inlineLyricsEnabled ? ' • Lyrics on' : ''}',
        icon: Icons.play_circle_filled_rounded,
        badgeBg: colors.isDark ? const Color(0xFF382A52) : const Color(0xFFE8DEF8),
        badgeFg: colors.isDark ? const Color(0xFFD0BCFF) : const Color(0xFF6750A4),
        keywords: ['media', 'player', 'music', 'lyrics', 'compact', 'expanded', 'wave', 'capsule'],
        onTap: () => _navigateTo(context, MediaPlayerSubmenu(colors: colors)),
      ),

      // 7. Notification Card Style
      _LayoutSettingItem(
        id: 'notifications',
        group: 'Media & Notifications',
        title: 'Notification Card Style',
        subtitle: '${state.notificationStyle.displayName} • ${state.notificationStyle.description}',
        icon: Icons.notifications_active_rounded,
        badgeBg: colors.isDark ? const Color(0xFF50252D) : const Color(0xFFFFD9DF),
        badgeFg: colors.isDark ? const Color(0xFFFFB1C1) : const Color(0xFF8F123A),
        keywords: ['notification', 'card', 'joined', 'ios', 'oneui', 'hyperos', 'compact', 'android 17'],
        onTap: () => _navigateTo(context, NotificationStyleSubmenu(colors: colors)),
      ),
    ];

    // Filter items based on search query
    final filteredItems = query.isEmpty
        ? allItems
        : allItems.where((item) {
            final inTitle = item.title.toLowerCase().contains(query);
            final inSubtitle = item.subtitle.toLowerCase().contains(query);
            final inKeywords = item.keywords.any((kw) => kw.contains(query));
            return inTitle || inSubtitle || inKeywords;
          }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 1. Android Settings Pill Search Bar
        _buildSearchBar(colors, font),
        const SizedBox(height: 16),

        if (query.isNotEmpty && filteredItems.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: colors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No matching settings found',
                    style: font.textStyleBuilder(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else if (query.isNotEmpty) ...[
          // Flat list of matching results
          _buildGroupCard(
            colors: colors,
            font: font,
            items: filteredItems,
          ),
        ] else ...[
          // Group 1: Display & Styling (Theming & Fonts)
          _buildGroupCard(
            colors: colors,
            font: font,
            items: [
              allItems[0], // Theming & Colors
              allItems[1], // Typography & Fonts
            ],
          ),
          const SizedBox(height: 14),

          // Group 2: Architecture & System (Shade Mode & Network Tiles)
          _buildGroupCard(
            colors: colors,
            font: font,
            items: [
              allItems[2], // Shade Mode Architecture
              allItems[3], // Network Tile Configuration
            ],
          ),
          const SizedBox(height: 14),

          // Group 3: Controls & Ergonomics (Slider Style)
          _buildGroupCard(
            colors: colors,
            font: font,
            items: [
              allItems[4], // Slider Style
            ],
          ),
          const SizedBox(height: 14),

          // Group 4: Media & Notifications (Media Player & Notification Card Style)
          _buildGroupCard(
            colors: colors,
            font: font,
            items: [
              allItems[5], // Media Player Layout Style
              allItems[6], // Notification Card Style
            ],
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildSearchBar(ExpressiveThemeColors colors, FontConfig font) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colors.textSecondary.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        style: font.textStyleBuilder(
          fontSize: 15,
          color: colors.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search settings',
          hintStyle: font.textStyleBuilder(
            fontSize: 15,
            color: colors.textSecondary.withValues(alpha: 0.8),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 22,
            color: colors.textSecondary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildGroupCard({
    required ExpressiveThemeColors colors,
    required FontConfig font,
    required List<_LayoutSettingItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: colors.textSecondary.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildSettingTile(
              item: items[i],
              colors: colors,
              font: font,
              isFirst: i == 0,
              isLast: i == items.length - 1,
            ),
            if (i < items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 72,
                endIndent: 18,
                color: colors.textSecondary.withValues(alpha: 0.10),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required _LayoutSettingItem item,
    required ExpressiveThemeColors colors,
    required FontConfig font,
    required bool isFirst,
    required bool isLast,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          item.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Circular colored icon badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.badgeBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    size: 22,
                    color: item.badgeFg,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and dynamic subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: font.textStyleBuilder(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: font.textStyleBuilder(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Submenu navigation indicator
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: colors.textSecondary.withValues(alpha: 0.60),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _LayoutSettingItem {
  final String id;
  final String group;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color badgeBg;
  final Color badgeFg;
  final List<String> keywords;
  final VoidCallback onTap;

  const _LayoutSettingItem({
    required this.id,
    required this.group,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeBg,
    required this.badgeFg,
    required this.keywords,
    required this.onTap,
  });
}

// ============================================================================
// --- SUBMENUS ---
// ============================================================================

/// Submenu 1: Theming & Colors Submenu (wrapping ThemeTab)
class ThemingSubmenu extends StatelessWidget {
  final ExpressiveThemeColors colors;

  const ThemingSubmenu({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShadeStateProvider>();
    final font = state.selectedFont;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Theming & Colors',
          style: font.textStyleBuilder(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: ThemeTab(colors: colors),
    );
  }
}

/// Submenu 2: Typography & Fonts Submenu (wrapping FontTab)
class FontsSubmenu extends StatelessWidget {
  final ExpressiveThemeColors colors;

  const FontsSubmenu({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShadeStateProvider>();
    final font = state.selectedFont;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Typography & Fonts',
          style: font.textStyleBuilder(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: FontTab(colors: colors),
    );
  }
}

/// Submenu 3: Shade Mode Architecture
class ShadeModeSubmenu extends StatelessWidget {
  final ExpressiveThemeColors colors;

  const ShadeModeSubmenu({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShadeStateProvider>();
    final font = state.selectedFont;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Shade Mode Architecture',
          style: font.textStyleBuilder(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          Text(
            'Architecture Overview',
            style: font.textStyleBuilder(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose between Android 17\'s separate notifications / control center, or the classic single pull-down shade.',
            style: font.textStyleBuilder(
              fontSize: 13.5,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ...ShadeMode.values.map((mode) {
            final isSelected = state.shadeMode == mode;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  HapticFeedback.selectionClick();
                  state.setShadeMode(mode);
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.activePill.withValues(alpha: 0.12)
                        : colors.surface,
                    borderRadius: BorderRadius.circular(28),
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
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.activePill
                                  : colors.inactivePill,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Icon(
                                switch (mode) {
                                  ShadeMode.split => Icons.splitscreen_rounded,
                                  ShadeMode.smart => Icons.grid_view_rounded,
                                  ShadeMode.nothingOs5 =>
                                    Icons.dashboard_customize_rounded,
                                  ShadeMode.unified => Icons.view_stream_rounded,
                                },
                                size: 24,
                                color: isSelected
                                    ? colors.onActivePill
                                    : colors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mode.displayName,
                                  style: font.textStyleBuilder(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  mode.description,
                                  style: font.textStyleBuilder(
                                    fontSize: 12.5,
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
                              color: isSelected
                                  ? colors.activePill
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? colors.activePill
                                    : colors.textSecondary.withValues(alpha: 0.5),
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
                      const SizedBox(height: 14),
                      _buildShadeModePreview(
                        mode,
                        colors,
                        font,
                        isSelected,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildShadeModePreview(
    ShadeMode mode,
    ExpressiveThemeColors colors,
    FontConfig font,
    bool isSelected,
  ) {
    return Container(
      height: 104,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? colors.activePill.withValues(alpha: 0.35)
              : colors.inactivePill.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: switch (mode) {
        ShadeMode.split => _buildSplitPreview(colors, font),
        ShadeMode.unified => _buildUnifiedPreview(colors, font),
        ShadeMode.smart => _buildMatrixPreview(colors, font),
        ShadeMode.nothingOs5 => _buildNothingOs5Preview(colors, font),
      },
    );
  }

  Widget _buildSplitPreview(ExpressiveThemeColors colors, FontConfig font) {
    return Column(
      children: [
        Container(
          height: 20,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
                decoration: BoxDecoration(
                  color: colors.activePill,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Alerts',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: colors.onActivePill,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Controls',
                style: TextStyle(fontSize: 9, color: colors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.mail_outline_rounded, size: 12, color: colors.activePill),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color: colors.textPrimary.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 12, color: colors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color: colors.textSecondary.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: colors.activePill,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(Icons.wifi_rounded, size: 12, color: colors.onActivePill),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: colors.inactivePill,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(Icons.bluetooth_rounded, size: 12, color: colors.onInactivePill),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.volume_up_rounded, size: 11, color: colors.activePill),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: colors.activePill,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedPreview(ExpressiveThemeColors colors, FontConfig font) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('10:00', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            Row(
              children: [
                Icon(Icons.wifi_rounded, size: 9, color: colors.textPrimary),
                const SizedBox(width: 3),
                Icon(Icons.battery_full_rounded, size: 9, color: colors.activePill),
              ],
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 22,
                decoration: BoxDecoration(color: colors.activePill, borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.wifi_rounded, size: 11, color: colors.onActivePill),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 22,
                decoration: BoxDecoration(color: colors.activePill, borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.bluetooth_rounded, size: 11, color: colors.onActivePill),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 22,
                decoration: BoxDecoration(color: colors.inactivePill, borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.flashlight_on_rounded, size: 11, color: colors.onInactivePill),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 22,
                decoration: BoxDecoration(color: colors.inactivePill, borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.do_not_disturb_on_rounded, size: 11, color: colors.onInactivePill),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active_rounded, size: 12, color: colors.activePill),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 4.5,
                        width: 70,
                        decoration: BoxDecoration(
                          color: colors.textPrimary,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                      const SizedBox(height: 2.5),
                      Container(
                        height: 3.5,
                        width: 110,
                        decoration: BoxDecoration(
                          color: colors.textSecondary.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatrixPreview(ExpressiveThemeColors colors, FontConfig font) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(6)),
              child: Text(
                '3:28 pm • 12/04',
                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: colors.activePill),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  Icon(Icons.battery_charging_full_rounded, size: 9, color: colors.activePill),
                  const SizedBox(width: 2),
                  Text('20%', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(color: colors.inactivePill, borderRadius: BorderRadius.circular(1.5)),
            ),
            Container(
              width: 44,
              height: 14,
              decoration: BoxDecoration(color: colors.activePill, borderRadius: BorderRadius.circular(5)),
              child: Icon(Icons.wb_sunny_rounded, size: 9, color: colors.onActivePill),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 20,
                decoration: BoxDecoration(color: colors.activePill, borderRadius: BorderRadius.circular(5)),
                child: Icon(Icons.wifi_rounded, size: 11, color: colors.onActivePill),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Container(
                height: 20,
                decoration: BoxDecoration(color: colors.activePill, borderRadius: BorderRadius.circular(5)),
                child: Icon(Icons.signal_cellular_alt_rounded, size: 11, color: colors.onActivePill),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Container(
                height: 20,
                decoration: BoxDecoration(color: colors.inactivePill, borderRadius: BorderRadius.circular(5)),
                child: Icon(Icons.bluetooth_rounded, size: 11, color: colors.onInactivePill),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(6)),
            child: Row(
              children: [
                Icon(Icons.call_missed_rounded, size: 11, color: colors.activePill),
                const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    height: 3.5,
                    decoration: BoxDecoration(color: colors.textPrimary, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(color: colors.activePill, borderRadius: BorderRadius.circular(1.5)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNothingOs5Preview(ExpressiveThemeColors colors, FontConfig font) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(color: const Color(0xFF1E2028), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.music_note_rounded, size: 10, color: Colors.white70),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 16,
                      height: 11,
                      decoration: BoxDecoration(color: const Color(0xFFDDE1FF), borderRadius: BorderRadius.circular(6)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: colors.activePill, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(color: colors.textPrimary.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(width: 14, height: 8, decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 3),
                  Container(width: 14, height: 8, decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(4))),
                  const Spacer(),
                  Container(width: 24, height: 8, decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              Container(
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: colors.activePill, borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 3.5,
                        decoration: BoxDecoration(color: colors.textPrimary.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Icon(Icons.pause_rounded, size: 10, color: colors.textPrimary),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(color: colors.activePill, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(color: colors.inactivePill, borderRadius: BorderRadius.circular(9)),
                        child: Center(
                          child: Text('2×2', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: colors.onInactivePill)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(color: colors.activePill.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(99)),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(color: colors.activePill, borderRadius: BorderRadius.circular(99)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Submenu 4: Network Tile Configuration
class NetworkTileSubmenu extends StatelessWidget {
  final ExpressiveThemeColors colors;

  const NetworkTileSubmenu({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShadeStateProvider>();
    final font = state.selectedFont;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Network Tile Configuration',
          style: font.textStyleBuilder(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          Text(
            'Layout Preference',
            style: font.textStyleBuilder(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toggle between the unified Internet pill or separate dedicated Wi-Fi and Mobile Data tiles.',
            style: font.textStyleBuilder(
              fontSize: 13.5,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          _buildNetworkTileOption(
            title: 'Unified Internet Tile',
            subtitle: 'Combined Wi-Fi & Mobile Data in a single expandable 1x2 pill.',
            icon: Icons.wifi_find_rounded,
            isSelected: state.networkTileStyle == NetworkTileStyle.unified,
            colors: colors,
            font: font,
            onTap: () {
              HapticFeedback.lightImpact();
              state.setNetworkTileStyle(NetworkTileStyle.unified);
            },
          ),
          const SizedBox(height: 16),

          _buildNetworkTileOption(
            title: 'Separate Wi-Fi & Mobile Data',
            subtitle: 'Individual tiles for Wi-Fi and Mobile Data with direct one-tap toggles.',
            icon: Icons.signal_cellular_alt_rounded,
            isSelected: state.networkTileStyle == NetworkTileStyle.separate,
            colors: colors,
            font: font,
            onTap: () {
              HapticFeedback.lightImpact();
              state.setNetworkTileStyle(NetworkTileStyle.separate);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkTileOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required ExpressiveThemeColors colors,
    required FontConfig font,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.activePill.withValues(alpha: 0.15)
              : colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? colors.activePill : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? colors.activePill : colors.inactivePill,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? colors.onActivePill : colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: font.textStyleBuilder(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: font.textStyleBuilder(
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
                  color: isSelected
                      ? colors.activePill
                      : colors.textSecondary.withValues(alpha: 0.5),
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
    );
  }
}

/// Submenu 5: Slider Style
class SliderStyleSubmenu extends StatelessWidget {
  final ExpressiveThemeColors colors;

  const SliderStyleSubmenu({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShadeStateProvider>();
    final font = state.selectedFont;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Slider Style',
          style: font.textStyleBuilder(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          Text(
            'Ergonomic Appearance',
            style: font.textStyleBuilder(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Customize the visual and ergonomic appearance of brightness and volume thick sliders.',
            style: font.textStyleBuilder(
              fontSize: 13.5,
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
                    color: isSelected
                        ? colors.activePill.withValues(alpha: 0.15)
                        : colors.surface,
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
                                  style: font.textStyleBuilder(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  style.description,
                                  style: font.textStyleBuilder(
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
                              color: isSelected
                                  ? colors.activePill
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? colors.activePill
                                    : colors.textSecondary.withValues(alpha: 0.5),
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
      ),
    );
  }
}

/// Submenu 6: Media Player Style
class MediaPlayerSubmenu extends StatelessWidget {
  final ExpressiveThemeColors colors;

  const MediaPlayerSubmenu({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShadeStateProvider>();
    final font = state.selectedFont;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Media Player Layout Style',
          style: font.textStyleBuilder(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          Text(
            'Media Player Appearance',
            style: font.textStyleBuilder(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose from 5 distinct expressive media card styles for your Quick Settings shade.',
            style: font.textStyleBuilder(
              fontSize: 13.5,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          ...MediaPlayerStyle.values.map((style) {
            final isSelected = state.mediaPlayerStyle == style;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  HapticFeedback.selectionClick();
                  state.setMediaPlayerStyle(style);
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.activePill.withValues(alpha: 0.12)
                        : colors.surface,
                    borderRadius: BorderRadius.circular(28),
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
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.activePill
                                  : colors.inactivePill,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.play_circle_filled_rounded,
                                size: 24,
                                color: isSelected
                                    ? colors.onActivePill
                                    : colors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  style.displayName,
                                  style: font.textStyleBuilder(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  style.description,
                                  style: font.textStyleBuilder(
                                    fontSize: 12.5,
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
                              color: isSelected
                                  ? colors.activePill
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? colors.activePill
                                    : colors.textSecondary.withValues(alpha: 0.5),
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
                      const SizedBox(height: 14),
                      IgnorePointer(
                        child: ExpressiveMediaCard(
                          title: 'Blinding Lights',
                          artist: 'The Weeknd',
                          appSource: 'Spotify',
                          isPlaying: true,
                          progress: 0.45,
                          colors: colors,
                          font: font,
                          style: style,
                          onPlayPause: () {},
                          onProgressChanged: (_) {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),

          InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () {
              HapticFeedback.selectionClick();
              state.setInlineLyricsEnabled(!state.inlineLyricsEnabled);
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: state.inlineLyricsEnabled
                    ? colors.activePill.withValues(alpha: 0.12)
                    : colors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: state.inlineLyricsEnabled
                      ? colors.activePill
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: state.inlineLyricsEnabled
                          ? colors.activePill
                          : colors.inactivePill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.lyrics_rounded,
                        size: 24,
                        color: state.inlineLyricsEnabled
                            ? colors.onActivePill
                            : colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inline Integration',
                          style: font.textStyleBuilder(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Show minimalist synchronized lyrics below the media player.',
                          style: font.textStyleBuilder(
                            fontSize: 12.5,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: state.inlineLyricsEnabled,
                    activeThumbColor: colors.activePill,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      state.setInlineLyricsEnabled(val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Submenu 7: Notification Card Style
class NotificationStyleSubmenu extends StatelessWidget {
  final ExpressiveThemeColors colors;

  const NotificationStyleSubmenu({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShadeStateProvider>();
    final font = state.selectedFont;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Card Style',
          style: font.textStyleBuilder(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          Text(
            'Card Aesthetics',
            style: font.textStyleBuilder(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Customize your notification appearance: Android 17 Expressive, iOS Notification Center, Samsung OneUI Stadium, HyperOS Floating Pill, Joined Multi-Column, or Compact Mode.',
            style: font.textStyleBuilder(
              fontSize: 13.5,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          ...NotificationStyle.values.map((style) {
            final isSelected = state.notificationStyle == style;
            final sampleNotif = NotificationModel(
              id: 'preview_${style.name}',
              packageName: 'com.google.android.apps.messaging',
              appName: 'Messages',
              title: 'Tim Cook',
              content:
                  'Hey! Look at this notification styling preview. It looks clean and tactile!',
              timeAgo: '2m ago',
              postTime: DateTime.now().subtract(const Duration(minutes: 2)).millisecondsSinceEpoch,
              appIcon: Icons.chat_bubble_rounded,
              appColor: const Color(0xFF2563EB),
              actions: const [
                NotificationAction(index: 0, title: 'Reply', hasRemoteInput: true),
                NotificationAction(index: 1, title: 'Mark as read', hasRemoteInput: false),
              ],
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  HapticFeedback.selectionClick();
                  state.setNotificationStyle(style);
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.activePill.withValues(alpha: 0.12)
                        : colors.surface,
                    borderRadius: BorderRadius.circular(28),
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
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.activePill
                                  : colors.inactivePill,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.notifications_active_rounded,
                                size: 24,
                                color: isSelected
                                    ? colors.onActivePill
                                    : colors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  style.displayName,
                                  style: font.textStyleBuilder(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  style.description,
                                  style: font.textStyleBuilder(
                                    fontSize: 12.5,
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
                              color: isSelected
                                  ? colors.activePill
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? colors.activePill
                                    : colors.textSecondary.withValues(alpha: 0.5),
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
                      const SizedBox(height: 14),
                      IgnorePointer(
                        child: NotificationCard(
                          notification: sampleNotif,
                          colors: colors,
                          font: font,
                          style: style,
                          onDismiss: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
