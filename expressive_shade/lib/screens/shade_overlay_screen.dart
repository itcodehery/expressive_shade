import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/shade_state_provider.dart';
import '../theme/m3_expressive_theme.dart';
import '../widgets/interactive_shade_canvas.dart';

class ShadeOverlayScreen extends StatefulWidget {
  final String initialTarget;

  const ShadeOverlayScreen({super.key, this.initialTarget = 'quick_settings'});

  @override
  State<ShadeOverlayScreen> createState() => _ShadeOverlayScreenState();
}

class _ShadeOverlayScreenState extends State<ShadeOverlayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  static const MethodChannel _overlayChannel = MethodChannel('com.expressive_shade/overlay_activity');

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 240),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _overlayChannel.setMethodCallHandler((call) async {
      if (call.method == 'onPanelTargetChanged') {
        final target = call.arguments?.toString();
        if (target != null && mounted) {
          final state = context.read<ShadeStateProvider>();
          state.setSplitTabIndex(target == 'notifications' ? 0 : 1);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<ShadeStateProvider>();
        state.setSplitTabIndex(widget.initialTarget == 'notifications' ? 0 : 1);
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _dismissOverlay() {
    _animController.reverse().then((_) {
      try {
        _overlayChannel.invokeMethod('dismissOverlay');
      } catch (_) {
        SystemNavigator.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShadeStateProvider>();
    final isPlatformDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    final themeColors = ExpressiveThemeColors.fromSettings(
      source: state.themeSource,
      preset: state.selectedPreset,
      custom: state.customTheme,
      systemMonetColor: state.systemMonetColor,
      isSystemDark: isPlatformDark,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _dismissOverlay();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
              // Fling upwards closes the shade
              _dismissOverlay();
            }
          },
          child: Stack(
            children: [
              // Darkened Backdrop
              FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: _dismissOverlay,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.50),
                  ),
                ),
              ),

              // Sliding Shade Canvas
              SlideTransition(
                position: _slideAnimation,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.94,
                  decoration: BoxDecoration(
                    color: themeColors.background,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.40),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: InteractiveShadeCanvas(colors: themeColors),
                      ),
                      // Bottom Grab Handle to pull up
                      GestureDetector(
                        onTap: _dismissOverlay,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          color: Colors.transparent,
                          child: Center(
                            child: Container(
                              width: 36,
                              height: 4.5,
                              decoration: BoxDecoration(
                                color: themeColors.textSecondary.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
