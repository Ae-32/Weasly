import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import '../utils/app_colors.dart';

/// Reusable Stash/Account Row component matching Figma CSS & design-reference specifications.
class AccountCard extends StatelessWidget {
  final AccountModel account;
  final double totalBalance;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AccountCard({
    super.key,
    required this.account,
    required this.totalBalance,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  (IconData, Color, Color, String) _getAccountStyle() {
    switch (account.type.toLowerCase()) {
      case 'gcash':
      case 'e-wallet':
        return (
          Icons.phone_iphone_rounded,
          const Color(0xFFE08B03),
          const Color(0xFFFCE9D6),
          account.note ?? 'Digital Transaction',
        );
      case 'bank':
        return (
          Icons.account_balance_rounded,
          const Color(0xFFF48423),
          const Color(0xFFFBE4D2),
          account.note ?? 'Saving & Salary',
        );
      case 'savings':
        return (
          Icons.savings_rounded,
          const Color(0xFFE05F03),
          const Color(0xFFFBDCC6),
          account.note ?? 'Long-term Savings',
        );
      case 'credit':
        return (
          Icons.credit_card_rounded,
          AppColors.stateError,
          const Color(0xFFFFDAD6),
          account.note ?? 'Credit Card',
        );
      case 'cash':
      default:
        return (
          Icons.account_balance_wallet_rounded,
          const Color(0xFFEE4818),
          const Color(0xFFFCDED5),
          account.note ?? 'Everyday Spending',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final (iconData, accentColor, bgOverlay, defaultSubtitle) = _getAccountStyle();
    final pct = totalBalance > 0 ? (account.balance / totalBalance).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              // Icon Badge Box
              Container(
                width: 32,
                height: 30,
                decoration: BoxDecoration(
                  color: bgOverlay,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(iconData, size: 16, color: accentColor),
              ),
              const SizedBox(width: 10),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: GoogleFonts.quicksand(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      account.note != null && account.note!.isNotEmpty ? account.note! : defaultSubtitle,
                      style: GoogleFonts.quicksand(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8A7F73),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Balance
              Text(
                currencyFormatter.format(account.balance),
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),

              // Popup Menu for Edit / Delete
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF8A7F73), size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'edit' && onEdit != null) {
                      onEdit!();
                    } else if (val == 'delete' && onDelete != null) {
                      onDelete!();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 16, color: AppColors.textPrimary),
                            SizedBox(width: 8),
                            Text('Edit Stash'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.stateError),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppColors.stateError)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Linear Progress Indicator Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: const Color.fromRGBO(43, 105, 78, 0.08),
              color: accentColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
