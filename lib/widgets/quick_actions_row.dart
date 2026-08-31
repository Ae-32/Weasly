import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/home_nav_provider.dart';
import '../screens/recurring_bills/recurring_bills_screen.dart';
import '../utils/app_colors.dart';

/// Quick Action Item definition
class _QuickActionItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

/// Horizontal quick action buttons row (Budgets, Goals, Debt, Notes, Bills, More).
class QuickActionsRow extends ConsumerWidget {
  const QuickActionsRow({super.key});

  void _showComingSoonSnackBar(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('$featureName is coming soon!'),
          ],
        ),
        backgroundColor: AppColors.accentPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      _QuickActionItem(
        label: 'Budgets',
        icon: Icons.donut_large_rounded,
        onTap: () {
          ref.read(homeNavIndexProvider.notifier).state = 2; // Switch to Budgets tab
        },
      ),
      _QuickActionItem(
        label: 'Goals',
        icon: Icons.flag_rounded,
        onTap: () => _showComingSoonSnackBar(context, 'Goals'),
      ),
      _QuickActionItem(
        label: 'Debt',
        icon: Icons.account_balance_wallet_rounded,
        onTap: () => _showComingSoonSnackBar(context, 'Debt'),
      ),
      _QuickActionItem(
        label: 'Notes',
        icon: Icons.note_alt_rounded,
        onTap: () => _showComingSoonSnackBar(context, 'Notes'),
      ),
      _QuickActionItem(
        label: 'Bills',
        icon: Icons.calendar_month_rounded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const RecurringBillsScreen()),
          );
        },
      ),
      _QuickActionItem(
        label: 'More',
        icon: Icons.more_horiz_rounded,
        onTap: () => _showComingSoonSnackBar(context, 'More quick tools'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: actions.map((action) {
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: action.onTap,
                  child: Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderDefault),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.bgBase,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            action.icon,
                            color: AppColors.accentPrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
