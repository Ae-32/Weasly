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
    Color accentColor;
    Color bgOverlay;

    if (account.colorHex != null && account.colorHex!.isNotEmpty) {
      final hex = account.colorHex!.replaceAll('#', '');
      final intVal = int.parse('FF$hex', radix: 16);
      accentColor = Color(intVal);
      bgOverlay = accentColor.withValues(alpha: 0.15);
    } else {
      switch (account.type.toLowerCase()) {
        case 'gcash':
        case 'e-wallet':
        case 'ewallet':
        case 'digital':
        case 'digital_stash':
          accentColor = const Color(0xFFE08B03);
          bgOverlay = const Color(0xFFFCE9D6);
          break;
        case 'bank':
        case 'bank_wallet':
          accentColor = const Color(0xFFF48423);
          bgOverlay = const Color(0xFFFBE4D2);
          break;
        case 'savings':
          accentColor = const Color(0xFFE05F03);
          bgOverlay = const Color(0xFFFBDCC6);
          break;
        case 'credit':
          accentColor = AppColors.stateError;
          bgOverlay = const Color(0xFFFFDAD6);
          break;
        case 'other':
          accentColor = const Color(0xFF8A7F73);
          bgOverlay = const Color(0xFFEDE0D9);
          break;
        case 'cash':
        default:
          accentColor = const Color(0xFFEE4818);
          bgOverlay = const Color(0xFFFCDED5);
          break;
      }
    }

    IconData iconData;
    String subtitle;
    switch (account.type.toLowerCase()) {
      case 'gcash':
      case 'e-wallet':
      case 'ewallet':
      case 'digital':
      case 'digital_stash':
        iconData = Icons.phone_iphone_rounded;
        subtitle = account.note ?? 'Digital Transaction';
        break;
      case 'bank':
      case 'bank_wallet':
        iconData = Icons.account_balance_rounded;
        subtitle = account.note ?? 'Saving & Salary';
        break;
      case 'savings':
        iconData = Icons.savings_rounded;
        subtitle = account.note ?? 'Long-term Savings';
        break;
      case 'credit':
        iconData = Icons.credit_card_rounded;
        subtitle = account.note ?? 'Credit Card';
        break;
      case 'other':
        iconData = Icons.more_horiz_rounded;
        subtitle = account.note ?? 'Custom Stash';
        break;
      case 'cash':
      default:
        iconData = Icons.account_balance_wallet_rounded;
        subtitle = account.note ?? 'Everyday Spending';
        break;
    }

    return (iconData, accentColor, bgOverlay, subtitle);
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

              // Balance (Highlighted red if negative)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currencyFormatter.format(account.balance),
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: account.balance < 0 ? AppColors.stateError : accentColor,
                    ),
                  ),
                  if (account.balance < 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Needs Adjustment',
                      style: GoogleFonts.quicksand(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.stateError,
                      ),
                    ),
                  ],
                ],
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
