import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../utils/app_colors.dart';
import '../utils/default_categories.dart';

/// Reusable Stash Icon component that renders custom PNG illustration for fixed stash types
/// and custom colored icon badge for 'Other' / custom stashes matching selected colorHex.
class StashIcon extends StatelessWidget {
  final String type;
  final String? name;
  final String? colorHex;
  final double size;

  const StashIcon({
    super.key,
    required this.type,
    this.name,
    this.colorHex,
    this.size = 24,
  });

  factory StashIcon.fromAccount(AccountModel account, {double size = 24}) {
    return StashIcon(
      type: account.type,
      name: account.name,
      colorHex: account.colorHex,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanType = type.trim().toLowerCase();
    final assetPath = AccountModel.getStashIconAsset(type, name);
    final isOtherStash = cleanType == AccountModel.typeOther ||
        cleanType == 'other' ||
        assetPath.endsWith('Other_Stash.png');

    if (isOtherStash) {
      final color = (colorHex != null && colorHex!.isNotEmpty)
          ? DefaultCategories.getColor(colorHex!)
          : const Color(0xFF8A7F73);
      final lightBgColor = Color.alphaBlend(color.withValues(alpha: 0.15), Colors.white);

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: lightBgColor,
          borderRadius: BorderRadius.circular(size * 0.24),
        ),
        child: Center(
          child: Icon(
            Icons.more_horiz_rounded,
            size: size * 0.55,
            color: color,
          ),
        ),
      );
    }

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.accentPrimary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(size * 0.24),
        ),
        child: Icon(
          Icons.account_balance_wallet_rounded,
          size: size * 0.55,
          color: AppColors.accentPrimary,
        ),
      ),
    );
  }
}
