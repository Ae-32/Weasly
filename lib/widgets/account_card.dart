import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import '../providers/balance_visibility_provider.dart';
import '../utils/app_colors.dart';
import 'stash_icon.dart';

/// Reusable Stash/Account Row component matching Figma CSS & design-reference specifications.
class AccountCard extends ConsumerWidget {
  final AccountModel account;
  final double totalBalance;
  final bool? isBalanceHidden;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AccountCard({
    super.key,
    required this.account,
    required this.totalBalance,
    this.isBalanceHidden,
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
        case AccountModel.typeDigital:
        case 'gcash':
        case 'e-wallet':
        case 'ewallet':
        case 'digital_stash':
          accentColor = const Color(0xFFE08B03);
          bgOverlay = const Color(0xFFFCE9D6);
          break;
        case AccountModel.typeBank:
        case 'bank_wallet':
          accentColor = const Color(0xFFF48423);
          bgOverlay = const Color(0xFFFBE4D2);
          break;
        case AccountModel.typeOther:
          accentColor = AppColors.textMuted;
          bgOverlay = AppColors.iconButtonBg;
          break;
        case AccountModel.typeCash:
        default:
          accentColor = const Color(0xFFEE4818);
          bgOverlay = const Color(0xFFFCDED5);
          break;
      }
    }

    IconData iconData;
    String subtitle;
    switch (account.type.toLowerCase()) {
      case AccountModel.typeDigital:
      case 'gcash':
      case 'e-wallet':
      case 'ewallet':
      case 'digital_stash':
        iconData = Icons.phone_iphone_rounded;
        subtitle = account.note ?? 'Digital transactions';
        break;
      case AccountModel.typeBank:
      case 'bank_wallet':
        iconData = Icons.account_balance_rounded;
        subtitle = account.note ?? 'Savings & salary';
        break;
      case AccountModel.typeOther:
        iconData = Icons.more_horiz_rounded;
        subtitle = account.note ?? 'Custom stash';
        break;
      case AccountModel.typeCash:
      default:
        iconData = Icons.account_balance_wallet_rounded;
        subtitle = account.note ?? 'Everyday spending';
        break;
    }

    return (iconData, accentColor, bgOverlay, subtitle);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final (iconData, accentColor, bgOverlay, defaultSubtitle) = _getAccountStyle();
    final pct = totalBalance > 0 ? (account.balance / totalBalance).clamp(0.0, 1.0) : 0.0;
    final bool hideBalance = isBalanceHidden ?? ref.watch(balanceVisibilityProvider);

    final Widget iconWidget = StashIcon.fromAccount(account, size: 34);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              // Icon Badge Box
              iconWidget,
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
                        color: colors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Balance (Highlighted red if negative and not hidden)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: Text(
                      hideBalance
                          ? '${currencyFormatter.currencySymbol} $kHiddenBalanceMask'
                          : currencyFormatter.format(account.balance),
                      key: ValueKey<bool>(hideBalance),
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: (account.balance < 0 && !hideBalance)
                            ? AppColors.stateError
                            : accentColor,
                      ),
                    ),
                  ),
                  if (account.balance < 0 && !hideBalance) ...[
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
                  icon: Icon(Icons.more_vert_rounded, color: colors.textMuted, size: 18),
                  color: colors.bgSurface,
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
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 16, color: colors.textPrimary),
                            const SizedBox(width: 8),
                            Text('Edit Stash', style: TextStyle(color: colors.textPrimary)),
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
              backgroundColor: colors.iconButtonBg,
              color: accentColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
