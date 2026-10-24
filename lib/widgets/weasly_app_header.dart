import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/settings/settings_screen.dart';
import '../utils/app_colors.dart';
import 'app_toast.dart';

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

  /// Optional back button configuration
  final bool showBackButton;
  final VoidCallback? onBackTap;

  const WeaslyAppHeader({
    super.key,
    this.title,
    this.subtitle,
    this.topLabel,
    this.inlineTitle = false,
    this.showBrandName = true,
    this.showBackButton = false,
    this.onBackTap,
  });

  void _showComingSoonSnackBar(BuildContext context, String featureName) {
    AppToast.showInfo(
      context,
      '$featureName feature coming soon!',
      title: 'Coming Soon',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgBase,
        border: Border(
          bottom: BorderSide(
            color: colors.borderDefault,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
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
              // Left: Back Button or Weasly App Logo Badge & Brand Name
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showBackButton) ...[
                    _buildHeaderIconButton(
                      context,
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: onBackTap ?? () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 10),
                  ],
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
                        color: colors.accentPrimary,
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
                            color: colors.textMutedLight,
                            letterSpacing: -0.64,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                      ],
                      if (title != null)
                        _buildFormattedTitleWidget(context, title!, 16),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Action Buttons Row (Notifications, Settings)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeaderIconButton(
                    context,
                    icon: Icons.notifications_rounded,
                    onTap: () => _showComingSoonSnackBar(context, 'Notifications'),
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderIconButton(
                    context,
                    icon: Icons.settings_rounded,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Separate Title & Subtitle Below Top Row (only if provided)
          if (!inlineTitle && title != null && title!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildFormattedTitleWidget(context, title!, 26),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colors.textMuted,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.iconButtonBg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.cardShadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: colors.accentPrimary,
        ),
      ),
    );
  }

  /// Renders title with bold font weight (w700) specifically for the user name portion when greeting (e.g. "Good afternoon, Ae!").
  Widget _buildFormattedTitleWidget(BuildContext context, String text, double fontSize) {
    final colors = context.colors;
    final commaIndex = text.indexOf(', ');
    if (commaIndex != -1) {
      final prefix = text.substring(0, commaIndex + 2); // e.g. "Good afternoon, "
      final userName = text.substring(commaIndex + 2);   // e.g. "Ae!"

      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: prefix,
              style: GoogleFonts.quicksand(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
                letterSpacing: -0.64,
              ),
            ),
            TextSpan(
              text: userName,
              style: GoogleFonts.quicksand(
                fontSize: fontSize,
                fontWeight: FontWeight.w700, // Bold user name
                color: colors.textPrimary,
                letterSpacing: -0.64,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      text,
      style: GoogleFonts.quicksand(
        fontSize: fontSize,
        fontWeight: fontSize > 20 ? FontWeight.w700 : FontWeight.w500,
        color: colors.textPrimary,
        letterSpacing: -0.64,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
