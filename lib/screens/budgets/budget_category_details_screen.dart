import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/budget_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/default_categories.dart';
import '../../widgets/add_edit_transaction_modal.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/success_banner.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/weasly_app_header.dart';

class BudgetCategoryDetailsScreen extends ConsumerStatefulWidget {
  final BudgetModel budget;

  const BudgetCategoryDetailsScreen({
    super.key,
    required this.budget,
  });

  @override
  ConsumerState<BudgetCategoryDetailsScreen> createState() =>
      _BudgetCategoryDetailsScreenState();
}

class _BudgetCategoryDetailsScreenState
    extends ConsumerState<BudgetCategoryDetailsScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  void _confirmDelete(BuildContext parentContext, TransactionModel tx) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Transaction',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this transaction? This will automatically adjust your account balance.',
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
                  .read(transactionControllerProvider.notifier)
                  .deleteTransaction(tx);
              if (parentContext.mounted) {
                if (success) {
                  SuccessBanner.show(parentContext, 'Transaction deleted!');
                } else {
                  final err = ref.read(transactionControllerProvider).errorMessage;
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

  Map<String, List<TransactionModel>> _groupTransactionsByDate(
      List<TransactionModel> transactions) {
    final Map<String, List<TransactionModel>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateFormatter = DateFormat('MMM dd, yyyy');

    for (final tx in transactions) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String label;
      if (txDate == today) {
        label = 'Today';
      } else if (txDate == yesterday) {
        label = 'Yesterday';
      } else {
        label = dateFormatter.format(tx.date);
      }

      if (!grouped.containsKey(label)) {
        grouped[label] = [];
      }
      grouped[label]!.add(tx);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final budget = widget.budget;
    final categoryColor = DefaultCategories.getCategoryColorByName(
      budget.categoryName,
      budget.categoryColorHex,
    );

    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final allTransactions = transactionsAsync.value ?? [];

    // Filter transactions for this budget's category and selected month
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    final endOfMonth = nextMonth.subtract(const Duration(milliseconds: 1));

    final categoryTransactions = allTransactions.where((tx) {
      if (tx.categoryId != budget.categoryId) return false;
      final isAfterStart = tx.date.isAfter(startOfMonth) || tx.date.isAtSameMomentAs(startOfMonth);
      final isBeforeEnd = tx.date.isBefore(endOfMonth) || tx.date.isAtSameMomentAs(endOfMonth);
      return isAfterStart && isBeforeEnd;
    }).toList();

    // Sort newest to oldest
    categoryTransactions.sort((a, b) => b.date.compareTo(a.date));

    // Calculate totals for selected month
    final totalSpent = categoryTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);

    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 0);
    final currencyFormatterDec = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final monthFormat = DateFormat('MMMM yyyy');

    // Budget status computations
    final progressRatio = budget.amount > 0
        ? (totalSpent / budget.amount > 1.0 ? 1.0 : totalSpent / budget.amount)
        : 0.0;
    final spentPct = budget.amount > 0 ? (totalSpent / budget.amount) * 100 : 0.0;
    final isOverBudget = spentPct >= 100.0;
    final isNearingLimit = spentPct >= budget.alertThreshold && !isOverBudget;

    final statusColor = isOverBudget
        ? AppColors.stateError
        : isNearingLimit
            ? const Color(0xFFE65100)
            : categoryColor;

    final statusText = isOverBudget
        ? 'Over Budget'
        : isNearingLimit
            ? 'Nearing Limit'
            : 'On Track';

    final groupedMap = _groupTransactionsByDate(categoryTransactions);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgBase,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [colors.cardBoxShadow],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => AddEditTransactionModal.show(context),
          backgroundColor: AppColors.accentPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          label: Text(
            'Add Transaction',
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar
            const WeaslyAppHeader(),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button & Category Header
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: CategoryIcon(
                                categoryName: budget.categoryName,
                                iconName: budget.categoryIcon,
                                color: categoryColor,
                                size: 22,
                                containerSize: 42,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  budget.categoryName,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Budget: ${currencyFormatter.format(budget.amount)} / month',
                                  style: GoogleFonts.quicksand(
                                    fontSize: 13,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Month Navigation Bar
                      Container(
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.borderDefault, width: 1.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: _previousMonth,
                              icon: Icon(Icons.chevron_left_rounded, color: colors.textPrimary),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.accentPrimary),
                                const SizedBox(width: 8),
                                Text(
                                  monthFormat.format(_selectedMonth),
                                  style: GoogleFonts.quicksand(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: _nextMonth,
                              icon: Icon(Icons.chevron_right_rounded, color: colors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Monthly Budget Spending Summary Card
                      Container(
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isOverBudget
                                ? (context.isDarkMode ? const Color(0xFF5A2A2A) : const Color(0xFFFFDAD6))
                                : colors.borderDefault,
                            width: 1.0,
                          ),
                          boxShadow: [colors.cardBoxShadow],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Spent',
                                      style: GoogleFonts.quicksand(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: colors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          currencyFormatterDec.format(totalSpent),
                                          style: GoogleFonts.quicksand(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: isOverBudget
                                                ? (context.isDarkMode ? const Color(0xFFEF5350) : const Color(0xFFC40707))
                                                : colors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'of ${currencyFormatter.format(budget.amount)}',
                                          style: GoogleFonts.quicksand(
                                            fontSize: 14,
                                            color: colors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: GoogleFonts.quicksand(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Progress Bar Track
                            Stack(
                              children: [
                                Container(
                                  height: 10,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: colors.iconButtonBg,
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: progressRatio,
                                  child: Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(9999),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Sub-metrics
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colors.iconButtonBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Transactions',
                                          style: GoogleFonts.quicksand(
                                            fontSize: 12,
                                            color: colors.textMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${categoryTransactions.length}',
                                          style: GoogleFonts.quicksand(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colors.iconButtonBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isOverBudget ? 'Over Budget By' : 'Remaining',
                                          style: GoogleFonts.quicksand(
                                            fontSize: 12,
                                            color: colors.textMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currencyFormatterDec.format(
                                            (budget.amount - totalSpent).abs(),
                                          ),
                                          style: GoogleFonts.quicksand(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isOverBudget
                                                ? AppColors.stateError
                                                : (context.isDarkMode ? const Color(0xFF66BB6A) : AppColors.accentSecondary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Transactions List Section Title
                      Text(
                        'Transactions',
                        style: GoogleFonts.quicksand(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (categoryTransactions.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                          decoration: BoxDecoration(
                            color: colors.bgSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colors.borderDefault, width: 1.0),
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/Weasly_NoTransaction.png',
                                width: 120,
                                height: 120,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.receipt_long_outlined,
                                  size: 56,
                                  color: colors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions yet',
                                style: GoogleFonts.quicksand(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'No expenses logged for ${budget.categoryName} in ${monthFormat.format(_selectedMonth)}.',
                                style: GoogleFonts.quicksand(
                                  fontSize: 13,
                                  color: colors.textMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: groupedMap.keys.length,
                          itemBuilder: (context, groupIndex) {
                            final dateHeader = groupedMap.keys.elementAt(groupIndex);
                            final dateTxs = groupedMap[dateHeader]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                  child: Text(
                                    dateHeader,
                                    style: GoogleFonts.quicksand(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ),
                                ...dateTxs.map(
                                  (tx) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10.0),
                                    child: _buildTransactionCard(context, tx, currencyFormatterDec, categoryColor),
                                  ),
                                ),
                              ],
                            );
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

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionModel tx,
    NumberFormat currencyFormatter,
    Color categoryColor,
  ) {
    final colors = context.colors;
    final isExpense = tx.type == TransactionType.expense;
    final isIncome = tx.type == TransactionType.income;

    final amountColor = isExpense
        ? (context.isDarkMode ? const Color(0xFFEF5350) : const Color(0xFFC40707))
        : isIncome
            ? (context.isDarkMode ? const Color(0xFF66BB6A) : AppColors.accentSecondary)
            : colors.textPrimary;

    final amountPrefix = isExpense ? '-' : isIncome ? '+' : '';
    final timeStr = DateFormat('h:mm a').format(tx.date);

    return InkWell(
      onTap: () => AddEditTransactionModal.show(context, transactionToEdit: tx),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderDefault, width: 1.0),
          boxShadow: [colors.cardBoxShadow],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CategoryIcon(
                  categoryName: tx.categoryName,
                  iconName: tx.categoryIcon,
                  color: categoryColor,
                  size: 20,
                  containerSize: 40,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.note != null && tx.note!.isNotEmpty ? tx.note! : tx.categoryName,
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        tx.accountName,
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('•', style: TextStyle(color: colors.textMuted, fontSize: 10)),
                      const SizedBox(width: 6),
                      Text(
                        timeStr,
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  '$amountPrefix${currencyFormatter.format(tx.amount)}',
                  style: GoogleFonts.quicksand(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 18, color: colors.textMuted),
                  color: colors.bgSurface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      AddEditTransactionModal.show(context, transactionToEdit: tx);
                    } else if (val == 'delete') {
                      _confirmDelete(context, tx);
                    }
                  },
                  itemBuilder: (context) => [
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
      ),
    );
  }
}
