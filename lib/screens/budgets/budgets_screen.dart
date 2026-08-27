import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/budget_model.dart';
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
        title: const Text(
          'Delete Budget',
          style: TextStyle(fontFamily: 'Quicksand', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete the budget for "${budget.categoryName}"?',
          style: const TextStyle(fontFamily: 'Quicksand'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
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
                      content: Text(err, style: const TextStyle(fontFamily: 'Quicksand')),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
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

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Text(
              'Weasly',
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddEditBudgetModal.show(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.onPrimary, size: 28),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              const Text(
                'Category Budgets',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Keep track of your acorns and stash responsibly.',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),

              // Budgets List
              if (budgetsWithSpent.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.savings_outlined,
                        size: 56,
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No budgets set yet',
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap + to set a spending limit for a category.',
                        style: TextStyle(
                          fontFamily: 'Quicksand',
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
                    final budget = item.budget;
                    final color = DefaultCategories.getColor(budget.categoryColorHex);
                    final iconData = DefaultCategories.getIcon(budget.categoryIcon);
                    final status = item.status;

                    final isOverBudget = status == BudgetStatus.overBudget;

                    return Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      color: AppColors.bgSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isOverBudget
                              ? AppColors.errorContainer
                              : AppColors.borderDefault,
                          width: isOverBudget ? 1.5 : 1.0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Category Icon, Name, Amounts, Popup Menu
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(iconData, color: color, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          budget.categoryName,
                                          style: const TextStyle(
                                            fontFamily: 'Quicksand',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                        Text(
                                          budget.periodType.name.toUpperCase(),
                                          style: const TextStyle(
                                            fontFamily: 'Quicksand',
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textMuted,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          currencyFormatter.format(item.spentAmount),
                                          style: TextStyle(
                                            fontFamily: 'Quicksand',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isOverBudget
                                                ? AppColors.stateError
                                                : AppColors.onSurface,
                                          ),
                                        ),
                                        Text(
                                          'of ${currencyFormatter.format(budget.amount)}',
                                          style: const TextStyle(
                                            fontFamily: 'Quicksand',
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert_rounded,
                                        color: AppColors.textMuted,
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
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 18, color: AppColors.onSurface),
                                              SizedBox(width: 8),
                                              Text('Edit', style: TextStyle(fontFamily: 'Quicksand')),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline, size: 18, color: AppColors.stateError),
                                              SizedBox(width: 8),
                                              Text('Delete', style: TextStyle(fontFamily: 'Quicksand', color: AppColors.stateError)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: item.progressRatio,
                                minHeight: 8,
                                backgroundColor: AppColors.borderDefault,
                                valueColor: AlwaysStoppedAnimation<Color>(status.color),
                              ),
                            ),

                            // Status Label (only shown if nearing limit or over budget)
                            if (status != BudgetStatus.safe) ...[
                              const SizedBox(height: 6),
                              Text(
                                status.label,
                                style: TextStyle(
                                  fontFamily: 'Quicksand',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: status.color,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
