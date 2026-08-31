import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/dashboard_provider.dart';
import '../utils/app_colors.dart';
import 'add_edit_recurring_bill_modal.dart';

/// Card showing a prominent countdown to the user's next expected income / payday,
/// featuring a large overlapping Weasly_Dashboard_PayCheck.png mascot.
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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // If no custom income rule exists, project standard 15th/end-of-month payday
    final DateTime targetDate;
    final int daysRemaining;
    final double? amount;
    final bool isProjectedDefault;

    if (paydayInfo != null && paydayInfo!.daysRemaining > 0) {
      targetDate = paydayInfo!.expectedDate;
      daysRemaining = paydayInfo!.daysRemaining;
      amount = paydayInfo!.expectedAmount;
      isProjectedDefault = false;
    } else {
      if (now.day < 15) {
        targetDate = DateTime(now.year, now.month, 15);
      } else if (now.day == 15) {
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        targetDate = nextMonth.subtract(const Duration(days: 1));
      } else {
        final lastDay = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
        if (now.day >= lastDay.day) {
          targetDate = DateTime(now.year, now.month + 1, 15);
        } else {
          targetDate = lastDay;
        }
      }
      daysRemaining = targetDate.difference(today).inDays;
      amount = paydayInfo?.expectedAmount ?? 5000.0; // Default matching Figma spec
      isProjectedDefault = paydayInfo == null;
    }

    final daysText = daysRemaining == 1
        ? '1 DAY'
        : '$daysRemaining DAYS';

    return Container(
      margin: const EdgeInsets.only(top: 25, bottom: 10),
      child: GestureDetector(
        onTap: isProjectedDefault ? () => AddEditRecurringBillModal.show(context) : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Card Gradient Background (Rectangle 4600)
            Container(
              width: double.infinity,
              height: 64,
              padding: const EdgeInsets.only(left: 120, right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
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
                        amount != null && amount > 0
                            ? currencyFormatter.format(amount)
                            : (isProjectedDefault ? 'Set Up' : currencyFormatter.format(0)),
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFormatter.format(targetDate).toUpperCase(),
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
