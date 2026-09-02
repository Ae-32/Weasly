import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';

/// Modal bottom sheet presenting a friendly "Insufficient Balance" warning
/// with account vs transaction shortfall visualizer and actionable controls.
class InsufficientBalanceModal extends StatelessWidget {
  final String accountName;
  final IconData accountIcon;
  final IconData categoryIcon;
  final double availableBalance;
  final double attemptedAmount;
  final bool isTransfer;

  const InsufficientBalanceModal({
    super.key,
    required this.accountName,
    this.accountIcon = Icons.account_balance_wallet_rounded,
    this.categoryIcon = Icons.shopping_bag_outlined,
    required this.availableBalance,
    required this.attemptedAmount,
    this.isTransfer = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final double safeAvailable = availableBalance < 0 ? 0.0 : availableBalance;
    final double shortfall = attemptedAmount - safeAvailable;
    final double availableRatio =
        attemptedAmount > 0 ? (safeAvailable / attemptedAmount).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E1D8),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Mascot Image
          SizedBox(
            height: 146,
            child: Image.asset(
              'assets/images/Weasly_Transaction_InsufficientBalance.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.account_balance_wallet_outlined,
                size: 80,
                color: AppColors.stateError,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Headline & Subtitle
          Text(
            'Whoops! Your stash is a bit low.',
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF211A16),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You don't have enough funds to cover this transaction.",
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8A7F73),
            ),
          ),
          const SizedBox(height: 24),

          // Balance vs Shortfall Comparison Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8E1D8), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Current Balance Row
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBE4D2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        accountIcon,
                        size: 18,
                        color: const Color(0xFFF48423),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Current Balance',
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8A7F73),
                        ),
                      ),
                    ),
                    Text(
                      currencyFormatter.format(availableBalance),
                      style: GoogleFonts.quicksand(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF211A16),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Color(0xFFF2ECE5), height: 1),
                ),

                // New Transaction Row
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDAD6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        categoryIcon,
                        size: 18,
                        color: AppColors.stateError,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'New Transaction',
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8A7F73),
                        ),
                      ),
                    ),
                    Text(
                      currencyFormatter.format(attemptedAmount),
                      style: GoogleFonts.quicksand(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.stateError,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Visual Progress Bar & Shortfall Indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 8,
                    width: double.infinity,
                    color: AppColors.stateError,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: availableRatio,
                      child: Container(
                        color: const Color(0xFFE08B03),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Short by text
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Short by ${currencyFormatter.format(shortfall > 0 ? shortfall : 0.0)}',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.stateError,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Action Buttons
          // 1. Adjust Amount (Primary Button)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop('adjust'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Adjust Amount',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Cancel (Secondary Button)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.bgSurface,
                side: const BorderSide(color: Color(0xFFE8E1D8), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.quicksand(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5A4E42),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
