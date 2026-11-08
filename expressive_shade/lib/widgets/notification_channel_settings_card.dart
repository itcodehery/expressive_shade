import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/font_config.dart';
import '../models/notification_model.dart';
import '../providers/shade_state_provider.dart';
import '../services/system_hardware_service.dart';
import '../theme/m3_expressive_theme.dart';

class NotificationChannelSettingsCard extends StatefulWidget {
  final NotificationModel notification;
  final ExpressiveThemeColors colors;
  final FontConfig font;
  final VoidCallback onClose;
  final BorderRadius? borderRadius;

  const NotificationChannelSettingsCard({
    super.key,
    required this.notification,
    required this.colors,
    required this.font,
    required this.onClose,
    this.borderRadius,
  });

  @override
  State<NotificationChannelSettingsCard> createState() =>
      _NotificationChannelSettingsCardState();
}

class _NotificationChannelSettingsCardState
    extends State<NotificationChannelSettingsCard> {
  late bool _isSilent;
  late NotificationCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    final state = context.read<ShadeStateProvider>();
    _isSilent = state.isNotificationSilent(widget.notification);
    _selectedCategory = widget.notification.category;
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final font = widget.font;
    final notif = widget.notification;
    final state = context.watch<ShadeStateProvider>();

    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(24);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.95),
        borderRadius: effectiveRadius,
        border: Border.all(
          color: colors.inactivePill.withValues(alpha: 0.25),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Status Title ('Default' / 'Silent') & Close 'x' button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isSilent ? 'Silent' : 'Default',
                style: font.textStyleBuilder(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onClose();
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // App Header Row: Icon + Channel/Title + AppName + Settings Gear
          Row(
            children: [
              // App Icon / Avatar
              Container(
                width: 32,
                height: 32,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: notif.appColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: notif.appIconBytes != null
                    ? Image.memory(
                        notif.appIconBytes!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            notif.appIcon,
                            size: 16,
                            color: notif.appColor,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          notif.appIcon,
                          size: 16,
                          color: notif.appColor,
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // Title & App Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.title.isNotEmpty ? notif.title : notif.appName,
                      style: font.textStyleBuilder(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      notif.appName,
                      style: font.textStyleBuilder(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Gear Icon (Settings) -> Opens Android App Notification Settings
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact();
                  SystemHardwareService.openAppNotificationSettings(
                    notif.packageName,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.settings_outlined,
                    size: 22,
                    color: colors.activePill,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Option 1: Default
          _buildOptionTile(
            title: 'Default',
            subtitle: null,
            icon: Icons.notifications_none_rounded,
            isSelected: !_isSilent,
            colors: colors,
            font: font,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isSilent = false);
              state.setNotificationSilent(notif, false);
            },
          ),
          const SizedBox(height: 8),

          // Option 2: Silent
          _buildOptionTile(
            title: 'Silent',
            subtitle: 'No sound or vibration',
            icon: Icons.notifications_off_outlined,
            isSelected: _isSilent,
            colors: colors,
            font: font,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isSilent = true);
              state.setNotificationSilent(notif, true);
            },
          ),
          const SizedBox(height: 12),

          // Smart Category Override Selector
          Text(
            'Smart Category',
            style: font.textStyleBuilder(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final cat in [
                  NotificationCategory.urgent,
                  NotificationCategory.people,
                  NotificationCategory.updates,
                  NotificationCategory.social,
                  NotificationCategory.promotions,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = cat);
                        state.setNotificationCategoryOverride(notif, cat);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedCategory == cat
                              ? colors.activePill
                              : colors.background.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat.icon,
                              size: 13,
                              color: _selectedCategory == cat
                                  ? colors.onActivePill
                                  : colors.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              cat.displayName,
                              style: font.textStyleBuilder(
                                fontSize: 11.5,
                                fontWeight: _selectedCategory == cat
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _selectedCategory == cat
                                    ? colors.onActivePill
                                    : colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Bottom Action Buttons: 'Turn off notifications' & 'Done'
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  state.dismissAllForApp(notif.appName);
                  SystemHardwareService.openAppNotificationSettings(
                    notif.packageName,
                  );
                  widget.onClose();
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Text(
                    'Turn off notifications',
                    style: font.textStyleBuilder(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: colors.activePill,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact();
                  state.setNotificationSilent(notif, _isSilent);
                  widget.onClose();
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Text(
                    'Done',
                    style: font.textStyleBuilder(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: colors.activePill,
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

  Widget _buildOptionTile({
    required String title,
    required String? subtitle,
    required IconData icon,
    required bool isSelected,
    required ExpressiveThemeColors colors,
    required FontConfig font,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.activePill.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colors.activePill.withValues(alpha: 0.5)
                : colors.inactivePill.withValues(alpha: 0.2),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? colors.activePill : colors.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: font.textStyleBuilder(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: font.textStyleBuilder(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
