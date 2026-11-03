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
  bool _isDismissing = false;
  static const MethodChannel _overlayChannel = MethodChannel('com.expressive_shade/overlay_activity');

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 230),
      reverseDuration: const Duration(milliseconds: 180),
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

    // Slide down immediately without waiting or disk I/O blocking
    _animController.forward(from: 0.0);

    _overlayChannel.setMethodCallHandler((call) async {
      if (call.method == 'onPanelTargetChanged' || call.method == 'reloadSettings') {
        final target = call.arguments?.toString();
        if (mounted) {
          _isDismissing = false;
          final state = context.read<ShadeStateProvider>();
          if (target != null && target.isNotEmpty) {
            state.setSplitTabIndex(target == 'notifications' ? 0 : 1);
          }
          state.setUnifiedQsExpanded(false);
          state.markShadeOpened();
          if (_animController.value < 1.0) {
            _animController.forward(from: _animController.value);
          }
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<ShadeStateProvider>();
        state.setSplitTabIndex(widget.initialTarget == 'notifications' ? 0 : 1);
        state.setUnifiedQsExpanded(false);
        state.markShadeOpened();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _dismissOverlay() {
    if (_isDismissing) return;
    _isDismissing = true;
    try {
      context.read<ShadeStateProvider>().flushSave();
    } catch (_) {}
    _animController.animateTo(0.0, duration: const Duration(milliseconds: 150), curve: Curves.easeInCubic).then((_) {
      try {
        _overlayChannel.invokeMethod('dismissOverlay');
      } catch (_) {
        SystemNavigator.pop();
      }
    });
  }

  void _dismissOverlayAndExecute(VoidCallback action) {
    if (_isDismissing) return;
    _isDismissing = true;
    try {
      context.read<ShadeStateProvider>().flushSave();
    } catch (_) {}
    try {
      action();
    } catch (_) {}
    _animController.animateTo(0.0, duration: const Duration(milliseconds: 150), curve: Curves.easeInCubic).then((_) {
      try {
        _overlayChannel.invokeMethod('dismissOverlay');
      } catch (_) {
        SystemNavigator.pop();
      }
    });
  }

  void _handleShadeDragUpdate(double deltaDy) {
    if (_isDismissing) return;
    final screenHeight = MediaQuery.of(context).size.height;
    final delta = deltaDy / screenHeight;
    _animController.value = (_animController.value + delta).clamp(0.0, 1.0);
  }

  void _handleShadeDragEnd(double velocity) {
    if (_isDismissing) return;
    if (velocity < -120 || _animController.value < 0.75) {
      _dismissOverlay();
    } else {
      _animController.animateTo(1.0, curve: Curves.easeOutCubic, duration: const Duration(milliseconds: 150));
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _dismissOverlay();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Darkened Backdrop
            FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: _dismissOverlay,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.25),
                ),
              ),
            ),

            // Sliding Shade Canvas with curved bottom corners
            SlideTransition(
              position: _slideAnimation,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: themeColors.background,
                  child: Stack(
                    children: [
                      // Full-Height Interactive Shade Canvas
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: InteractiveShadeCanvas(
                            colors: themeColors,
                            onDismissAndExecute: _dismissOverlayAndExecute,
                            onDragShadeUpdate: _handleShadeDragUpdate,
                            onDragShadeEnd: _handleShadeDragEnd,
                          ),
                        ),
                      ),
                      // Bottom drag gesture area (Indicator hidden as requested)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: _dismissOverlay,
                          onVerticalDragUpdate: (details) {
                            final screenHeight = MediaQuery.of(context).size.height;
                            final delta = details.delta.dy / screenHeight;
                            _handleShadeDragUpdate(delta);
                          },
                          onVerticalDragEnd: (details) {
                            final velocity = details.primaryVelocity ?? 0;
                            _handleShadeDragEnd(velocity);
                          },
                          child: Container(
                            width: double.infinity,
                            height: 24,
                            color: Colors.transparent,
                          ),
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
    );
  }
}
