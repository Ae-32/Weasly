import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/balance_visibility_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../providers/payday_provider.dart';
import '../../providers/pin_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/success_banner.dart';
import '../../widgets/app_toast.dart';
import '../auth/logout_confirmation_modal.dart';
import '../auth/logout_success_screen.dart';
import '../auth/pin_setup_modal.dart';
import 'payday_setup_modal.dart';
import '../../widgets/send_feedback_modal.dart';

/// Screen allowing users to manage app preferences, including Theme appearance, biometric login, PIN setup, Payday Setup, and Account Logout.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await LogoutConfirmationModal.show(context);
    if (confirmed == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LogoutSuccessScreen()),
        );
      }
    }
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required ThemeMode mode,
    required ThemeMode activeMode,
    required IconData icon,
    required String label,
  }) {
    final colors = context.colors;
    final isSelected = mode == activeMode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(themeModeProvider.notifier).setThemeMode(mode);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.accentPrimary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? (context.isDarkMode ? colors.bgBase : Colors.white)
                    : colors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? (context.isDarkMode ? colors.bgBase : Colors.white)
                      : colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final themeMode = ref.watch(themeModeProvider);
    final isBiometricEnabled = ref.watch(biometricEnabledProvider);
    final isPinSet = ref.watch(isPinSetProvider);
    final isBalanceHidden = ref.watch(balanceVisibilityProvider);
    final paydaySettings = ref.watch(paydaySettingsStreamProvider).value;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.quicksand(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payday Setup Section Header
              Text(
                'PAYDAY PREFERENCES',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),

              // Payday Setup Setting Card
              Container(
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderDefault),
                  boxShadow: [
                    BoxShadow(
                      color: colors.cardShadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.accentPrimaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.payments_rounded,
                      color: colors.accentPrimary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Payday Setup',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    paydaySettings != null
                        ? '${paydaySettings.frequency.displayName} • Next: ${DateFormat('MMM d').format(paydaySettings.nextPaydayDate)}'
                        : 'Configure frequency, next date, and stash link',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textMuted,
                  ),
                  onTap: () => PaydaySetupModal.show(context),
                ),
              ),
              const SizedBox(height: 24),

              // Appearance Section Header
              Text(
                'APPEARANCE',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),

              // Appearance Theme Card
              Container(
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderDefault),
                  boxShadow: [
                    BoxShadow(
                      color: colors.cardShadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.accentPrimaryLight.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            themeMode == ThemeMode.dark
                                ? Icons.dark_mode_rounded
                                : (themeMode == ThemeMode.light
                                    ? Icons.light_mode_rounded
                                    : Icons.brightness_auto_rounded),
                            color: colors.accentPrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Theme Mode',
                                style: GoogleFonts.quicksand(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              Text(
                                themeMode == ThemeMode.system
                                    ? 'Follows device system settings'
                                    : (themeMode == ThemeMode.dark
                                        ? 'Warm Espresso dark palette'
                                        : 'Warm Cream light palette'),
                                style: GoogleFonts.quicksand(
                                  fontSize: 12,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // 3-way Segmented Control (System, Light, Dark)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.bgBase,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.borderDefault),
                      ),
                      child: Row(
                        children: [
                          _buildThemeOption(
                            context,
                            ref,
                            mode: ThemeMode.system,
                            activeMode: themeMode,
                            icon: Icons.brightness_auto_rounded,
                            label: 'System',
                          ),
                          _buildThemeOption(
                            context,
                            ref,
                            mode: ThemeMode.light,
                            activeMode: themeMode,
                            icon: Icons.light_mode_rounded,
                            label: 'Light',
                          ),
                          _buildThemeOption(
                            context,
                            ref,
                            mode: ThemeMode.dark,
                            activeMode: themeMode,
                            icon: Icons.dark_mode_rounded,
                            label: 'Dark',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Security Section Header
              Text(
                'SECURITY & PRIVACY',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),

              // Hide Account Balances Setting Card
              Container(
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderDefault),
                  boxShadow: [
                    BoxShadow(
                      color: colors.cardShadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SwitchListTile(
                  value: isBalanceHidden,
                  onChanged: (val) async {
                    await ref
                        .read(balanceVisibilityProvider.notifier)
                        .setHideBalance(val);
                    if (context.mounted) {
                      SuccessBanner.show(
                        context,
                        val ? 'Account balances hidden!' : 'Account balances visible!',
                      );
                    }
                  },
                  activeThumbColor: colors.accentPrimary,
                  secondary: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.accentPrimaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isBalanceHidden
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: colors.accentPrimary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Hide Account Balances',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Conceal balance amounts across dashboard and accounts screens',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Biometric Lock Setting Card
              Container(
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderDefault),
                  boxShadow: [
                    BoxShadow(
                      color: colors.cardShadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SwitchListTile(
                  value: isBiometricEnabled,
                  onChanged: (val) async {
                    final (success, errorMsg) = await ref
                        .read(biometricEnabledProvider.notifier)
                        .setBiometricEnabled(val);
                    if (context.mounted) {
                      if (success) {
                        SuccessBanner.show(
                          context,
                          val ? 'Biometric login enabled!' : 'Biometric login disabled!',
                        );
                      } else {
                        AppToast.showError(
                          context,
                          errorMsg ?? 'Biometrics not available on this device.',
                        );
                      }
                    }
                  },
                  activeThumbColor: colors.accentPrimary,
                  secondary: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.accentPrimaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.fingerprint_rounded,
                      color: colors.accentPrimary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Enable biometric login',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Require fingerprint or face unlock when reopening an active session',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // PIN Lock Setting Card
              Container(
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderDefault),
                  boxShadow: [
                    BoxShadow(
                      color: colors.cardShadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.accentPrimaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isPinSet ? Icons.lock_rounded : Icons.lock_outline_rounded,
                      color: colors.accentPrimary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    isPinSet ? 'PIN Protection Active' : 'Set up PIN',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    isPinSet
                        ? '6 digit PIN active as app lock'
                        : 'Create a 6 digit PIN for device authentication',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                  trailing: isPinSet
                      ? PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded,
                              color: colors.textPrimary),
                          onSelected: (choice) async {
                            if (choice == 'change') {
                              PinSetupModal.show(context,
                                  mode: PinSetupMode.change);
                            } else if (choice == 'remove') {
                              PinSetupModal.show(context,
                                  mode: PinSetupMode.remove);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'change',
                              child: Text(
                                'Change PIN',
                                style: GoogleFonts.quicksand(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'remove',
                              child: Text(
                                'Remove PIN',
                                style: GoogleFonts.quicksand(
                                  fontWeight: FontWeight.w600,
                                  color: colors.stateError,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Icon(Icons.chevron_right_rounded,
                          color: colors.textMuted),
                  onTap: () {
                    if (!isPinSet) {
                      PinSetupModal.show(context, mode: PinSetupMode.setup);
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Help & Feedback Section
              Text(
                'HELP & FEEDBACK',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderDefault),
                  boxShadow: [
                    BoxShadow(
                      color: colors.cardShadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.accentPrimaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: colors.accentPrimary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Send Feedback',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Share comments, ideas, or report a bug',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textMuted,
                  ),
                  onTap: () => SendFeedbackModal.show(context),
                ),
              ),
              const SizedBox(height: 24),

              // About Section
              Text(
                'ABOUT',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderDefault),
                  boxShadow: [
                    BoxShadow(
                      color: colors.cardShadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.accentPrimaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: colors.accentPrimary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Weasly App Version',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  trailing: Text(
                    'v1.0.0',
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Account & Session Section Header
              Text(
                'ACCOUNT & SESSION',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),

              // Log Out Setting Card (Styled in Expense Orange palette)
              Container(
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderDefault),
                  boxShadow: [
                    BoxShadow(
                      color: colors.cardShadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.accentPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: colors.accentPrimary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Log Out',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.accentPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Sign out of your Weasly account',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: colors.accentPrimary,
                  ),
                  onTap: () => _handleLogout(context, ref),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
