import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/budget_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/default_categories.dart';
import '../../widgets/add_edit_budget_modal.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  void _confirmDelete(BuildContext context, WidgetRef ref, BudgetModel budget) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Budget',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete the budget for "${budget.categoryName}"?',
          style: GoogleFonts.quicksand(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: GoogleFonts.quicksand(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await ref
                  .read(budgetControllerProvider.notifier)
                  .deleteBudget(budget.id);
              if (context.mounted && !success) {
                final err = ref.read(budgetControllerProvider).errorMessage;
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err, style: GoogleFonts.quicksand()),
                      backgroundColor: AppColors.stateError,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.stateError,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log Out',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to log out of Weasly?',
          style: GoogleFonts.quicksand(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: GoogleFonts.quicksand(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(authControllerProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonSnackBar(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!', style: GoogleFonts.quicksand()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsWithSpent = ref.watch(budgetsWithSpentProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(43, 36, 32, 0.08),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => AddEditBudgetModal.show(context),
          backgroundColor: AppColors.accentPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Bar
              _buildTopHeader(context, ref),

              // Budgets List Content Container
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (budgetsWithSpent.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8E1D8)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(43, 36, 32, 0.04),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.savings_outlined,
                              size: 56,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No budgets set yet',
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF211A16),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap + to set a spending limit for a category.',
                              style: GoogleFonts.quicksand(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: budgetsWithSpent.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final item = budgetsWithSpent[index];
                          return _buildBudgetCard(context, ref, item, currencyFormatter);
                        },
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top Header Bar matching Dashboard & Accounts header pattern
  Widget _buildTopHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 18.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Weasly App Logo Badge (Left) & Action Buttons (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Weasly App Logo Badge
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/images/Weasly_Logo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Action Buttons Row (Notification, Settings, Logout)
              Row(
                children: [
                  _buildHeaderIconButton(
                    icon: Icons.notifications_rounded,
                    onTap: () => _showComingSoonSnackBar(context, 'Notifications'),
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderIconButton(
                    icon: Icons.settings_rounded,
                    onTap: () => _showComingSoonSnackBar(context, 'Settings'),
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderIconButton(
                    icon: Icons.person_rounded,
                    onTap: () => _handleLogout(context, ref),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title: "Monthly Budgets"
          Text(
            'Monthly Budgets',
            style: GoogleFonts.quicksand(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF211A16),
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            'Keep track of your acorns and stash responsibly.',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8A7F73),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFFEDE0D9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(43, 36, 32, 0.04),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.accentPrimary),
      ),
    );
  }

  /// Individual Budget Card matching Figma CSS specs & redesign mockups
  Widget _buildBudgetCard(
    BuildContext context,
    WidgetRef ref,
    BudgetWithSpent item,
    NumberFormat currencyFormatter,
  ) {
    final budget = item.budget;
    final categoryColor = DefaultCategories.getCategoryColorByName(
      budget.categoryName,
      budget.categoryColorHex,
    );
    final iconData = DefaultCategories.getIcon(budget.categoryIcon);
    final status = item.status;
    final isOverBudget = status == BudgetStatus.overBudget;
    final isNearingLimit = status == BudgetStatus.nearingLimit;

    // Status colors from Figma redesign specs
    final statusColor = isOverBudget
        ? const Color(0xFFF6722F)
        : isNearingLimit
            ? const Color(0xFFF48423)
            : const Color(0xFFEE4818);

    final borderColor = isOverBudget ? const Color(0xFFFFDAD6) : const Color(0xFFE8E1D8);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(43, 36, 32, 0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category Icon, Name, Amounts, 3-dots popup menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon + Category Name
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(iconData, color: categoryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    budget.categoryName,
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF211A16),
                    ),
                  ),
                ],
              ),

              // Amounts & Popup Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormatter.format(item.spentAmount),
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isOverBudget ? const Color(0xFFC40707) : const Color(0xFF211A16),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'of ${currencyFormatter.format(budget.amount)}',
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF8A7F73),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Color(0xFF8A7F73),
                      size: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (val) {
                      if (val == 'edit') {
                        AddEditBudgetModal.show(context, budgetToEdit: budget);
                      } else if (val == 'delete') {
                        _confirmDelete(context, ref, budget);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF211A16)),
                            const SizedBox(width: 8),
                            Text('Edit', style: GoogleFonts.quicksand()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, size: 18, color: AppColors.stateError),
                            const SizedBox(width: 8),
                            Text('Delete', style: GoogleFonts.quicksand(color: AppColors.stateError)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Linear Progress Indicator Bar
          Stack(
            children: [
              // Track Background (#E8E1D8)
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E1D8),
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              // Progress Bar
              FractionallySizedBox(
                widthFactor: item.progressRatio,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
            ],
          ),

          // Status Label (shown for Nearing Limit & Over Budget)
          if (status != BudgetStatus.safe) ...[
            const SizedBox(height: 8),
            Text(
              status == BudgetStatus.nearingLimit ? 'Nearing limit' : 'Over budget',
              style: GoogleFonts.quicksand(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
