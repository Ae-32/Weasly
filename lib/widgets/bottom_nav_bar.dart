import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Reusable Bottom Navigation Bar matching design-reference tokens.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: AppColors.bgSurface,
        indicatorColor: const Color(0xFFAFF1CD), // secondary-container tint
        surfaceTintColor: Colors.transparent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF317054)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: Color(0xFF317054)),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF317054)),
            label: 'Budgets',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance_rounded, color: Color(0xFF317054)),
            label: 'Accounts',
          ),
        ],
      ),
    );
  }
}
