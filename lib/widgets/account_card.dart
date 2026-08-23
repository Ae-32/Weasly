import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import '../utils/app_colors.dart';

/// Reusable Card component for displaying an account item matching accounts_overview design.
class AccountCard extends StatelessWidget {
  final AccountModel account;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  /// Helper returning the appropriate Icon and background color for the account type.
  (IconData, Color, Color) _getAccountStyle() {
    switch (account.type.toLowerCase()) {
      case 'gcash':
        return (
          Icons.phone_iphone_rounded,
          const Color(0xFFFFDCC1), // primary-container
          const Color(0xFF512A00),
        );
      case 'bank':
        return (
          Icons.account_balance_rounded,
          const Color(0xFFAFF1CD), // secondary-container
          const Color(0xFF317054),
        );
      case 'savings':
        return (
          Icons.savings_rounded,
          const Color(0xFFFFDEA6), // tertiary-fixed
          const Color(0xFF453000),
        );
      case 'credit':
        return (
          Icons.credit_card_rounded,
          const Color(0xFFFFDAD6), // error-container
          const Color(0xFF93000A),
        );
      case 'cash':
      default:
        return (
          Icons.payments_rounded,
          const Color(0xFFC5942C), // tertiary container
          Colors.white,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final (iconData, bgColor, iconColor) = _getAccountStyle();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Account Icon Badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Account Name & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (account.note != null && account.note!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          account.note!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Account Balance
                Text(
                  currencyFormatter.format(account.balance),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),

                // Edit/Delete Popup Menu
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      if (value == 'edit' && onEdit != null) {
                        onEdit!();
                      } else if (value == 'delete' && onDelete != null) {
                        onDelete!();
                      }
                    },
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 18, color: AppColors.textPrimary),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.stateError),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: AppColors.stateError)),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
