import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/logout_confirmation_modal.dart';
import '../screens/auth/logout_success_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../utils/app_colors.dart';

/// Shared top header widget for Weasly app screens.
class WeaslyAppHeader extends ConsumerWidget {
  /// Primary title (e.g. "Good afternoon, Ae!" or optional page title)
  final String? title;

  /// Optional subtitle
  final String? subtitle;

  /// Optional top label (for Dashboard date header "TUESDAY - SEPTEMBER 1, 2026")
  final String? topLabel;

  /// If true, renders title & topLabel inline in the middle of top row (Dashboard style).
  final bool inlineTitle;

  /// Whether to display the "Weasly" brand name next to the logo badge.
  final bool showBrandName;

  const WeaslyAppHeader({
    super.key,
    this.title,
    this.subtitle,
    this.topLabel,
    this.inlineTitle = false,
    this.showBrandName = true,
  });

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await LogoutConfirmationModal.show(context);
    if (confirmed == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LogoutSuccessScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showComingSoonSnackBar(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName feature coming soon!'),
        backgroundColor: AppColors.accentPrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgBase,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE8E1D8),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(43, 36, 32, 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 12.0, bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Weasly App Logo Badge & Brand Name (Left) & Action Buttons (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Weasly App Logo Badge & Brand Name
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/images/Weasly_Logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (showBrandName && !inlineTitle) ...[
                    const SizedBox(width: 10),
                    Text(
                      'Weasly',
                      style: GoogleFonts.quicksand(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ],
              ),

              // Inline Title/Label for Dashboard layout
              if (inlineTitle) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (topLabel != null) ...[
                        Text(
                          topLabel!,
                          style: GoogleFonts.quicksand(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFBBB6B4),
                            letterSpacing: -0.64,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                      ],
                      if (title != null)
                        Text(
                          title!,
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF211A16),
                            letterSpacing: -0.64,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Action Buttons Row (Notification, Settings, Profile/Logout)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeaderIconButton(
                    icon: Icons.notifications_rounded,
                    onTap: () => _showComingSoonSnackBar(context, 'Notifications'),
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderIconButton(
                    icon: Icons.settings_rounded,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderIconButton(
                    icon: Icons.person_rounded,
                    onTap: () => _handleLogout(context, ref),
                  ),
                ],
              ),
            ],
          ),

          // Separate Title & Subtitle Below Top Row (only if provided)
          if (!inlineTitle && title != null && title!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              title!,
              style: GoogleFonts.quicksand(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF211A16),
                letterSpacing: -0.5,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF8A7F73),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFFEDE0D9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(43, 36, 32, 0.04),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: AppColors.accentPrimary,
        ),
      ),
    );
  }
}
