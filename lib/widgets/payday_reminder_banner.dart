import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/payday_provider.dart';
import '../utils/app_colors.dart';
import 'payday_prompt_modal.dart';

/// StateProvider tracking session-level manual dismissal of the Payday Reminder Banner.
final paydayBannerDismissedSessionProvider = StateProvider<bool>((ref) => false);

/// Dismissible reminder banner displayed on Dashboard / Account screens
/// when today is payday and the user dismissed the initial popup without logging income.
class PaydayReminderBanner extends ConsumerWidget {
  const PaydayReminderBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShow = ref.watch(shouldShowPaydayReminderBannerProvider);
    final isSessionDismissed = ref.watch(paydayBannerDismissedSessionProvider);
    final settings = ref.watch(paydaySettingsStreamProvider).value;

    if (!shouldShow || isSessionDismissed || settings == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(43, 36, 32, 0.04),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mascot Icon
          Image.asset(
            'assets/images/Weasly_Dashboard_PayCheck.png',
            width: 44,
            height: 44,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.celebration_rounded,
              color: AppColors.accentPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: 10),

          // Message details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'It\'s Payday Today! 🎉',
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Don\'t forget to log your income to update your stashes.',
                  style: GoogleFonts.quicksand(
                    fontSize: 11.5,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Log Now Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () => PaydayPromptModal.show(context, settings),
            child: Text(
              'Log Now',
              style: GoogleFonts.quicksand(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Dismiss Button (X)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              ref.read(paydayBannerDismissedSessionProvider.notifier).state = true;
            },
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
