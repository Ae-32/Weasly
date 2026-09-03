import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/payday_provider.dart';
import '../screens/settings/payday_setup_modal.dart';
import '../utils/app_colors.dart';

/// Refactored Card showing the user's manual Payday Setup countdown,
/// friendly empty state, or expired custom payday reminder.
/// Features a prominent overlapping Weasly_Dashboard_PayCheck.png mascot.
class PaydayCountdownCard extends StatelessWidget {
  final PaydayInfo? paydayInfo;

  const PaydayCountdownCard({
    super.key,
    required this.paydayInfo,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final dateFormatter = DateFormat('MMM. dd');

    // Case 1: Unconfigured Payday Setup (Empty State)
    if (paydayInfo == null) {
      return Container(
        margin: const EdgeInsets.only(top: 25, bottom: 10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Card Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 110, right: 16, top: 12, bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFF9F6F1),
                    Color(0xFFEFD8C2),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(43, 36, 32, 0.04),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'DAYS UNTIL PAYDAY',
                          style: GoogleFonts.quicksand(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFA2A2A2),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Set up your payday to see a countdown here',
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => PaydaySetupModal.show(context),
                    child: Text(
                      'Set Up',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Large Mascot Illustration Overlapping Left
            Positioned(
              left: -12,
              top: -36,
              width: 139,
              height: 138,
              child: Image.asset(
                'assets/images/Weasly_Dashboard_PayCheck.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      );
    }

    final info = paydayInfo!;

    // Case 2: Custom Payday Expired State
    if (info.isCustomExpired) {
      return Container(
        margin: const EdgeInsets.only(top: 25, bottom: 10),
        child: GestureDetector(
          onTap: () => PaydaySetupModal.show(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 110, right: 16, top: 12, bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFFFFF4EC),
                      Color(0xFFFBE4D2),
                    ],
                  ),
                  border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.4)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(43, 36, 32, 0.04),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'CUSTOM PAYDAY PASSED',
                            style: GoogleFonts.quicksand(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.stateWarning,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to update your next payday date',
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_calendar_rounded, color: AppColors.accentPrimary, size: 20),
                  ],
                ),
              ),

              Positioned(
                left: -12,
                top: -36,
                width: 139,
                height: 138,
                child: Image.asset(
                  'assets/images/Weasly_Dashboard_PayCheck.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Case 3: Active Countdown State
    final daysRemaining = info.daysRemaining;
    final daysText = daysRemaining == 0
        ? 'TODAY!'
        : (daysRemaining == 1 ? '1 DAY' : '$daysRemaining DAYS');

    return Container(
      margin: const EdgeInsets.only(top: 25, bottom: 10),
      child: GestureDetector(
        onTap: () => PaydaySetupModal.show(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Card Gradient Background (Rectangle 4600)
            Container(
              width: double.infinity,
              height: 64,
              padding: const EdgeInsets.only(left: 120, right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFF9F6F1),
                    Color(0xFFEFD8C2),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(43, 36, 32, 0.04),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Days Countdown Details
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAYS UNTIL PAYDAY',
                        style: GoogleFonts.quicksand(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFA2A2A2),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        daysText,
                        style: GoogleFonts.quicksand(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),

                  // Date & Amount Section
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormatter.format(info.expectedAmount),
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFormatter.format(info.nextPaydayDate).toUpperCase(),
                        style: GoogleFonts.quicksand(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFA2A2A2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Large Mascot Illustration Overlapping Left, Top, and Bottom!
            Positioned(
              left: -12,
              top: -36,
              width: 139,
              height: 138,
              child: Image.asset(
                'assets/images/Weasly_Dashboard_PayCheck.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
