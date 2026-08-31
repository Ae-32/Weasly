import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

/// Reusable Bottom Navigation Bar styled strictly per Figma CSS & design specifications.
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
    final navItems = [
      const _NavItemData(
        label: 'Home',
        selectedIcon: Icons.home_rounded,
        unselectedIcon: Icons.home_outlined,
      ),
      const _NavItemData(
        label: 'Transactions',
        selectedIcon: Icons.receipt_long_rounded,
        unselectedIcon: Icons.receipt_long_outlined,
      ),
      const _NavItemData(
        label: 'Budgets',
        selectedIcon: Icons.account_balance_wallet_rounded,
        unselectedIcon: Icons.account_balance_wallet_outlined,
      ),
      const _NavItemData(
        label: 'Accounts',
        selectedIcon: Icons.account_box_rounded,
        unselectedIcon: Icons.account_box_outlined,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(43, 36, 32, 0.06),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEFD8C2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected ? item.selectedIcon : item.unselectedIcon,
                            size: 20,
                            color: isSelected ? AppColors.accentPrimary : const Color(0xFF8A7F73),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: GoogleFonts.quicksand(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? AppColors.accentPrimary : const Color(0xFF8A7F73),
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData selectedIcon;
  final IconData unselectedIcon;

  const _NavItemData({
    required this.label,
    required this.selectedIcon,
    required this.unselectedIcon,
  });
}
