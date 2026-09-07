import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

enum AppToastType {
  success,
  delete,
  error,
  info,
  warning,
}

/// Unified App Toast / Pop Banner system matching card design with left accent bars.
class AppToast {
  static OverlayEntry? _currentOverlay;
  static Timer? _dismissTimer;

  static void showSuccess(
    BuildContext context,
    String message, {
    String title = 'Success',
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    show(
      context,
      type: AppToastType.success,
      title: title,
      message: message,
      duration: duration,
    );
  }

  static void showDelete(
    BuildContext context,
    String message, {
    String title = 'Deleted',
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    show(
      context,
      type: AppToastType.delete,
      title: title,
      message: message,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String title = 'Error',
    Duration duration = const Duration(milliseconds: 4000),
  }) {
    show(
      context,
      type: AppToastType.error,
      title: title,
      message: message,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String title = 'Info',
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    show(
      context,
      type: AppToastType.info,
      title: title,
      message: message,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String title = 'Warning',
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    show(
      context,
      type: AppToastType.warning,
      title: title,
      message: message,
      duration: duration,
    );
  }

  static void show(
    BuildContext context, {
    required AppToastType type,
    required String message,
    String? title,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    // Dismiss any active toast immediately before showing new one
    dismiss();

    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) return;

    final defaultTitle = switch (type) {
      AppToastType.success => 'Success',
      AppToastType.delete => 'Deleted',
      AppToastType.error => 'Error',
      AppToastType.info => 'Info',
      AppToastType.warning => 'Warning',
    };

    _currentOverlay = OverlayEntry(
      builder: (context) => _AppToastOverlayWidget(
        type: type,
        title: title ?? defaultTitle,
        message: message,
        duration: duration,
        onDismiss: dismiss,
      ),
    );

    overlayState.insert(_currentOverlay!);

    _dismissTimer = Timer(duration, () {
      dismiss();
    });
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_currentOverlay != null) {
      _currentOverlay?.remove();
      _currentOverlay = null;
    }
  }
}

class _AppToastOverlayWidget extends StatefulWidget {
  final AppToastType type;
  final String title;
  final String message;
  final Duration duration;
  final VoidCallback onDismiss;

  const _AppToastOverlayWidget({
    required this.type,
    required this.title,
    required this.message,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_AppToastOverlayWidget> createState() => _AppToastOverlayWidgetState();
}

class _AppToastOverlayWidgetState extends State<_AppToastOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0.0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    return switch (widget.type) {
      AppToastType.success => const Color(0xFF2ECC71),
      AppToastType.delete => const Color(0xFFE74C3C),
      AppToastType.error => const Color(0xFFC0392B),
      AppToastType.info => const Color(0xFF2196F3),
      AppToastType.warning => const Color(0xFFFFB300),
    };
  }

  IconData get _iconData {
    return switch (widget.type) {
      AppToastType.success => Icons.check_rounded,
      AppToastType.delete => Icons.check_rounded,
      AppToastType.error => Icons.close_rounded,
      AppToastType.info => Icons.info_rounded,
      AppToastType.warning => Icons.priority_high_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Position below header clearance (~76px offset)
    final topPadding = MediaQuery.of(context).padding.top + 76;

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Material(
                color: Colors.transparent,
                child: Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.up,
                  onDismissed: (_) => widget.onDismiss(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Accent Bar
                          Container(
                            width: 6,
                            color: _accentColor,
                          ),
                          // Card Main Contents
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Type Status Circle Icon
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _iconData,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Text Column
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.title,
                                          style: GoogleFonts.quicksand(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                            height: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          widget.message,
                                          style: GoogleFonts.quicksand(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textMuted,
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Close 'X' Button
                                  GestureDetector(
                                    onTap: widget.onDismiss,
                                    behavior: HitTestBehavior.opaque,
                                    child: const Padding(
                                      padding: EdgeInsets.all(6.0),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: AppColors.textMuted,
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
