import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/home_nav_provider.dart';
import '../utils/app_colors.dart';
import 'app_toast.dart';

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
    AppToast.showInfo(
      context,
      '$featureName feature coming soon!',
      title: 'Coming Soon',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      _QuickActionItem(
        label: 'Budgets',
        icon: Icons.donut_large_rounded,
        onTap: () {
          ref.read(homeNavIndexProvider.notifier).state = 3; // Switch to Budgets tab
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
        onTap: () => _showComingSoonSnackBar(context, 'Bills'),
      ),
      _QuickActionItem(
        label: 'More',
        icon: Icons.more_horiz_rounded,
        onTap: () => _showComingSoonSnackBar(context, 'More quick tools'),
      ),
    ];

    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
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
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.borderDefault),
                      boxShadow: [
                        BoxShadow(
                          color: colors.cardShadow,
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
                            color: colors.bgBase,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            action.icon,
                            color: colors.accentPrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
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
