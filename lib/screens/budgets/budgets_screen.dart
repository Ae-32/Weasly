import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/budget_model.dart';
import '../../providers/budget_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/default_categories.dart';
import '../../widgets/add_edit_budget_modal.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/success_banner.dart';
import '../../widgets/weasly_app_header.dart';
import 'budget_category_details_screen.dart';
import '../../widgets/app_toast.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  void _confirmDelete(BuildContext parentContext, WidgetRef ref, BudgetModel budget) {
    showDialog(
      context: parentContext,
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
              if (parentContext.mounted) {
                if (success) {
                  SuccessBanner.show(parentContext, 'Budget deleted!');
                } else {
                  final err = ref.read(budgetControllerProvider).errorMessage;
                  if (err != null) {
                    AppToast.showError(parentContext, err);
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsWithSpent = ref.watch(budgetsWithSpentProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 0);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgBase,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [colors.cardBoxShadow],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Fixed Top Header Bar (Logo Badge & Action Buttons)
            const WeaslyAppHeader(),

            // 2. Scrollable Budgets List Content Container
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Scrollable Page Title & Subtitle Section
                      Text(
                        'Monthly Budgets',
                        style: GoogleFonts.quicksand(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep track of your acorns and stash responsibly.',
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (budgetsWithSpent.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 160, horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/Weasly_NoTransaction.png',
                                width: 160,
                                height: 160,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.savings_outlined,
                                  size: 64,
                                  color: colors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No budget created yet.',
                                style: GoogleFonts.quicksand(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start setting monthly spending limits to keep your finances on track.',
                                style: GoogleFonts.quicksand(
                                  fontSize: 14,
                                  color: colors.textMuted,
                                ),
                                textAlign: TextAlign.center,
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
              ),
            ),
          ],
        ),
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
    final colors = context.colors;
    final budget = item.budget;
    final categoryColor = DefaultCategories.getCategoryColorByName(
      budget.categoryName,
      budget.categoryColorHex,
    );
    final status = item.status;
    final isOverBudget = status == BudgetStatus.overBudget;
    final isNearingLimit = status == BudgetStatus.nearingLimit;

    // Status colors: warning/error for alerts, category color for normal progress
    final statusColor = isOverBudget
        ? AppColors.stateError
        : isNearingLimit
            ? const Color(0xFFE65100)
            : categoryColor;

    final borderColor = isOverBudget
        ? (context.isDarkMode ? const Color(0xFF5A2A2A) : const Color(0xFFFFDAD6))
        : colors.borderDefault;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [colors.cardBoxShadow],
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
                    child: Center(
                      child: CategoryIcon(
                        categoryName: budget.categoryName,
                        iconName: budget.categoryIcon,
                        color: categoryColor,
                        size: 20,
                        containerSize: 40,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    budget.categoryName,
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
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
                          color: isOverBudget
                              ? (context.isDarkMode ? const Color(0xFFEF5350) : const Color(0xFFC40707))
                              : colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'of ${currencyFormatter.format(budget.amount)}',
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: colors.textMuted,
                      size: 20,
                    ),
                    color: colors.bgSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (val) {
                      if (val == 'view_transactions') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BudgetCategoryDetailsScreen(budget: budget),
                          ),
                        );
                      } else if (val == 'edit') {
                        AddEditBudgetModal.show(context, budgetToEdit: budget);
                      } else if (val == 'delete') {
                        _confirmDelete(context, ref, budget);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view_transactions',
                        child: Row(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 18, color: colors.textPrimary),
                            const SizedBox(width: 8),
                            Text('View Transactions', style: GoogleFonts.quicksand(color: colors.textPrimary)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: colors.textPrimary),
                            const SizedBox(width: 8),
                            Text('Edit', style: GoogleFonts.quicksand(color: colors.textPrimary)),
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
              // Track Background
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.iconButtonBg,
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
