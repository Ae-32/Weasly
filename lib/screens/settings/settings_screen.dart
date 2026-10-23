import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/balance_visibility_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../providers/payday_provider.dart';
import '../../providers/pin_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/success_banner.dart';
import '../../widgets/app_toast.dart';
import '../auth/logout_confirmation_modal.dart';
import '../auth/logout_success_screen.dart';
import '../auth/pin_setup_modal.dart';
import 'payday_setup_modal.dart';
import '../../widgets/send_feedback_modal.dart';


/// Screen allowing users to manage app preferences, including biometric login, PIN setup, Payday Setup, and Account Logout.
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


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBiometricEnabled = ref.watch(biometricEnabledProvider);
    final isPinSet = ref.watch(isPinSetProvider);
    final isBalanceHidden = ref.watch(balanceVisibilityProvider);
    final paydaySettings = ref.watch(paydaySettingsStreamProvider).value;


    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.quicksand(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
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
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),

              // Payday Setup Setting Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDefault),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(43, 36, 32, 0.04),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.payments_rounded,
                      color: AppColors.accentPrimary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Payday Setup',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    paydaySettings != null
                        ? '${paydaySettings.frequency.displayName} • Next: ${DateFormat('MMM d').format(paydaySettings.nextPaydayDate)}'
                        : 'Configure frequency, next date, and stash link',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                  onTap: () => PaydaySetupModal.show(context),
                ),
              ),
              const SizedBox(height: 24),

              // Security Section Header
              Text(
                'SECURITY & PRIVACY',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),

              // Hide Account Balances Setting Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDefault),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(43, 36, 32, 0.04),
                      blurRadius: 12,
                      offset: Offset(0, 4),
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
                  activeThumbColor: AppColors.accentPrimary,
                  secondary: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isBalanceHidden
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppColors.accentPrimary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Hide Account Balances',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Conceal balance amounts across dashboard and accounts screens',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Biometric Lock Setting Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDefault),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(43, 36, 32, 0.04),
                      blurRadius: 12,
                      offset: Offset(0, 4),
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
                  activeThumbColor: AppColors.accentPrimary,
                  secondary: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      color: AppColors.accentPrimary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Enable biometric login',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Require fingerprint or face unlock when reopening an active session',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // PIN Lock Setting Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDefault),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(43, 36, 32, 0.04),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isPinSet ? Icons.lock_rounded : Icons.lock_outline_rounded,
                      color: AppColors.accentPrimary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    isPinSet ? 'PIN Protection Active' : 'Set up PIN',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    isPinSet
                        ? '6 digit PIN active as app lock'
                        : 'Create a 6 digit PIN for device authentication',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  trailing: isPinSet
                      ? PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded,
                              color: AppColors.textPrimary),
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
                                  color: AppColors.stateError,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textMuted),
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
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDefault),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(43, 36, 32, 0.04),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.accentPrimary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Send Feedback',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Share comments, ideas, or report a bug',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
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
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDefault),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(43, 36, 32, 0.04),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.accentPrimary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Weasly App Version',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  trailing: Text(
                    'v1.0.0',
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
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
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),

              // Log Out Setting Card (Styled in Expense Orange palette)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDefault),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(43, 36, 32, 0.04),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.accentPrimary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Log Out',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Sign out of your Weasly account',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.accentPrimary,
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

