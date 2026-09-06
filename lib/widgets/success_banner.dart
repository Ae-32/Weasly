import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single reusable helper for displaying auto-dismissing success banners at the TOP of the screen.
/// Follows Weasly design tokens (stateSuccess background, rounded corners, white text & icon).
class SuccessBanner {
  static OverlayEntry? _currentOverlay;
  static Timer? _dismissTimer;

  /// Display a top success banner with a message and an optional checkmark icon.
  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_rounded,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    // Dismiss any active banner immediately before showing a new one
    _dismissTimer?.cancel();
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) return;

    _currentOverlay = OverlayEntry(
      builder: (context) => _SuccessBannerOverlayWidget(
        message: message,
        icon: icon,
        duration: duration,
        onDismiss: () {
          _dismissTimer?.cancel();
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );

    overlayState.insert(_currentOverlay!);

    _dismissTimer = Timer(duration, () {
      _currentOverlay?.remove();
      _currentOverlay = null;
    });
  }
}

class _SuccessBannerOverlayWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismiss;

  const _SuccessBannerOverlayWidget({
    required this.message,
    required this.icon,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_SuccessBannerOverlayWidget> createState() => _SuccessBannerOverlayWidgetState();
}

class _SuccessBannerOverlayWidgetState extends State<_SuccessBannerOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _progressController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeIn,
    );

    _slideController.forward();
    _progressController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 68;

    return Positioned(
      top: topPadding,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF006C1B),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.2),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF006C1B),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              widget.message,
                              style: GoogleFonts.quicksand(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Animated neon green progress bar at bottom
                    SizedBox(
                      height: 4,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          // Background track (muted grey)
                          Container(
                            width: double.infinity,
                            height: 4,
                            color: const Color(0xFF757575),
                          ),
                          // Filling progress bar (bright neon green)
                          AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              return FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _progressController.value,
                                child: Container(
                                  height: 4,
                                  color: const Color(0xFF00E676),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
