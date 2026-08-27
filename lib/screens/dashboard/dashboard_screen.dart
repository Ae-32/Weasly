import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/recurring_bill_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/home_nav_provider.dart';
import '../../providers/recurring_bill_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/default_categories.dart';
import '../../widgets/add_edit_transaction_modal.dart';
import '../recurring_bills/recurring_bills_screen.dart';

/// Full live Dashboard screen matching design-reference/dashboard/code.html.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final recurringBillsAsync = ref.watch(recurringBillsStreamProvider);
    final budgetsWithSpent = ref.watch(budgetsWithSpentProvider);

    final user = authState.value;
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final currencyFormatterShort = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

    // Warning / Over budget alerts
    final warningBudgets = budgetsWithSpent
        .where((b) => b.status == BudgetStatus.nearingLimit || b.status == BudgetStatus.overBudget)
        .take(2)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFDCC1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bgBase, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset(
                  'assets/images/Weasly.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.pets_rounded,
                    size: 20,
                    color: Color(0xFF512A00),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  user?.displayName ?? user?.email?.split('@').first ?? 'Weasly User',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.stateError),
            tooltip: 'Log Out',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to sign out of Weasly?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.stateError),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authControllerProvider.notifier).signOut();
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Total Balance Summary Card
              _buildTotalBalanceCard(context, ref, totalBalance, currencyFormatter),
              const SizedBox(height: 24),

              // 2. Budget Alerts (Hidden if no budgets are in warning/over state)
              if (warningBudgets.isNotEmpty) ...[
                _buildBudgetAlertsSection(context, ref, warningBudgets, currencyFormatter),
                const SizedBox(height: 24),
              ],

              // 3. Spending by Category (Chart & List for current month)
              _buildCategorySpendingSection(context, transactionsAsync, currencyFormatterShort),
              const SizedBox(height: 24),

              // 4. Recent Transactions List
              _buildRecentTransactionsSection(context, ref, transactionsAsync, currencyFormatter),
              const SizedBox(height: 24),

              // 5. Upcoming Recurring Bills Preview
              _buildRecurringBillsSection(context, ref, recurringBillsAsync, currencyFormatter),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Total Balance Overview Card matching design reference tokens
  Widget _buildTotalBalanceCard(
    BuildContext context,
    WidgetRef ref,
    double totalBalance,
    NumberFormat currencyFormatter,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currencyFormatter.format(totalBalance),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    AddEditTransactionModal.show(context);
                  },
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    'Add Income',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentSecondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AddEditTransactionModal.show(context);
                  },
                  icon: const Icon(Icons.remove_rounded, size: 20),
                  label: const Text(
                    'Add Expense',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderDefault),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. Budget Alerts Section (Highlights nearing or over budget limits)
  Widget _buildBudgetAlertsSection(
    BuildContext context,
    WidgetRef ref,
    List<BudgetWithSpent> warningBudgets,
    NumberFormat currencyFormatter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Budget Alerts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                ref.read(homeNavIndexProvider.notifier).state = 2; // Switch to Budgets tab
              },
              child: const Text(
                'View Budgets',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...warningBudgets.map((item) {
          final isOver = item.status == BudgetStatus.overBudget;
          final statusColor = item.status.color;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  isOver ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.budget.categoryName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            item.status.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currencyFormatter.format(item.spentAmount)} spent of ${currencyFormatter.format(item.budget.amount)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// 3. Spending by Category Section (Pie chart & progress bar breakdown)
  Widget _buildCategorySpendingSection(
    BuildContext context,
    AsyncValue<List<TransactionModel>> transactionsAsync,
    NumberFormat currencyFormatterShort,
  ) {
    final now = DateTime.now();

    return transactionsAsync.when(
      data: (transactions) {
        // Filter current calendar month expense transactions
        final currentMonthExpenses = transactions.where((tx) {
          return tx.type == TransactionType.expense &&
              tx.date.year == now.year &&
              tx.date.month == now.month;
        }).toList();

        if (currentMonthExpenses.isEmpty) {
          return _buildCardWrapper(
            title: 'Spending by Category',
            actionText: 'Current Month',
            onAction: null,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 44, color: AppColors.textMuted),
                  SizedBox(height: 10),
                  Text(
                    'No expenses logged this month yet.',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          );
        }

        // Group expenses by category
        final Map<String, _CategoryExpenseAggregate> categoryMap = {};
        double totalExpenseMonth = 0.0;

        for (final tx in currentMonthExpenses) {
          totalExpenseMonth += tx.amount;
          if (categoryMap.containsKey(tx.categoryId)) {
            categoryMap[tx.categoryId]!.total += tx.amount;
          } else {
            categoryMap[tx.categoryId] = _CategoryExpenseAggregate(
              id: tx.categoryId,
              name: tx.categoryName,
              iconName: tx.categoryIcon,
              colorHex: tx.categoryColorHex,
              total: tx.amount,
            );
          }
        }

        final sortedCategories = categoryMap.values.toList()
          ..sort((a, b) => b.total.compareTo(a.total));

        // Color palette cycle from AppColors & DefaultCategories
        final chartColors = [
          AppColors.accentPrimary, // Amber #8E4E00
          AppColors.accentSecondary, // Green #2B694E
          const Color(0xFFC5942C), // Gold
          const Color(0xFF7B5800), // Dark Gold
          const Color(0xFF2E1500), // Deep Brown
          AppColors.textMuted,
        ];

        return _buildCardWrapper(
          title: 'Spending by Category',
          actionText: DateFormat('MMMM yyyy').format(now),
          onAction: null,
          child: Column(
            children: [
              // Pie Chart Representation
              SizedBox(
                height: 180,
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 36,
                          sections: sortedCategories.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final cat = entry.value;
                            final color = DefaultCategories.getColor(cat.colorHex) != AppColors.accentPrimary
                                ? DefaultCategories.getColor(cat.colorHex)
                                : chartColors[idx % chartColors.length];
                            final pct = (cat.total / totalExpenseMonth) * 100;

                            return PieChartSectionData(
                              color: color,
                              value: cat.total,
                              title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                              radius: 36,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Month Expense',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormatterShort.format(totalExpenseMonth),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Across ${sortedCategories.length} categories',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Category Progress Bar List
              ...sortedCategories.asMap().entries.map((entry) {
                final idx = entry.key;
                final cat = entry.value;
                final pct = totalExpenseMonth > 0 ? (cat.total / totalExpenseMonth) : 0.0;
                final color = DefaultCategories.getColor(cat.colorHex) != AppColors.accentPrimary
                    ? DefaultCategories.getColor(cat.colorHex)
                    : chartColors[idx % chartColors.length];
                final icon = DefaultCategories.getIcon(cat.iconName);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(icon, size: 15, color: color),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cat.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            currencyFormatterShort.format(cat.total),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: color.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => _buildCardWrapper(
        title: 'Spending by Category',
        actionText: null,
        onAction: null,
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, _) => _buildCardWrapper(
        title: 'Spending by Category',
        actionText: null,
        onAction: null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error loading spending: $err', style: const TextStyle(color: AppColors.stateError)),
        ),
      ),
    );
  }

  /// 4. Recent Transactions Section
  Widget _buildRecentTransactionsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<TransactionModel>> transactionsAsync,
    NumberFormat currencyFormatter,
  ) {
    return _buildCardWrapper(
      title: 'Recent Activity',
      actionText: 'See All',
      onAction: () {
        ref.read(homeNavIndexProvider.notifier).state = 1; // Switch to Transactions tab
      },
      child: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'No transactions recorded yet.',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
              ),
            );
          }

          // Show top 5 latest transactions
          final recentList = transactions.take(5).toList();
          final dateFormatter = DateFormat('MMM dd');

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentList.length,
            separatorBuilder: (context, index) => const Divider(
              height: 16,
              thickness: 0.5,
              color: AppColors.borderDefault,
            ),
            itemBuilder: (context, index) {
              final tx = recentList[index];
              final isIncome = tx.type == TransactionType.income;
              final isTransfer = tx.type == TransactionType.transfer;

              final icon = isTransfer
                  ? Icons.swap_horiz_rounded
                  : DefaultCategories.getIcon(tx.categoryIcon);
              final color = isTransfer
                  ? AppColors.accentSecondary
                  : DefaultCategories.getColor(tx.categoryColorHex);

              final amountPrefix = isIncome ? '+' : '-';
              final amountColor = isIncome ? AppColors.accentSecondary : AppColors.textPrimary;

              final titleText = (tx.note != null && tx.note!.isNotEmpty)
                  ? tx.note!
                  : (isTransfer ? 'Transfer to ${tx.toAccountName}' : tx.categoryName);

              final subtitleText = isTransfer
                  ? '${tx.accountName} ➔ ${tx.toAccountName} • ${dateFormatter.format(tx.date)}'
                  : '${tx.categoryName} • ${tx.accountName} • ${dateFormatter.format(tx.date)}';

              return Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitleText,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$amountPrefix${currencyFormatter.format(tx.amount)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Text(
          'Error: $err',
          style: const TextStyle(color: AppColors.stateError),
        ),
      ),
    );
  }

  /// 5. Upcoming Recurring Bills Section
  Widget _buildRecurringBillsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<RecurringBillModel>> recurringBillsAsync,
    NumberFormat currencyFormatter,
  ) {
    return _buildCardWrapper(
      title: 'Upcoming Bills',
      actionText: 'View All',
      onAction: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const RecurringBillsScreen()),
        );
      },
      child: recurringBillsAsync.when(
        data: (bills) {
          if (bills.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(
                  'No recurring bills added.',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
              ),
            );
          }

          // Sort by nextDueDate ascending & take 3
          final sortedBills = List<RecurringBillModel>.from(bills)
            ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
          final upcomingList = sortedBills.take(3).toList();
          final dateFormatter = DateFormat('MMM dd');

          return Column(
            children: upcomingList.map((bill) {
              final daysLeft = bill.daysUntilDue;

              // Urgency badge color matching Unit 06
              final Color badgeColor;
              final String urgencyText;

              if (bill.isOverdue) {
                badgeColor = AppColors.stateError;
                urgencyText = 'Overdue';
              } else if (daysLeft == 0) {
                badgeColor = AppColors.stateWarning;
                urgencyText = 'Due Today';
              } else if (daysLeft <= 3) {
                badgeColor = AppColors.stateWarning;
                urgencyText = 'Due in $daysLeft ${daysLeft == 1 ? "day" : "days"}';
              } else {
                badgeColor = AppColors.accentSecondary;
                urgencyText = 'Due ${dateFormatter.format(bill.nextDueDate)}';
              }

              final icon = DefaultCategories.getIcon(bill.categoryIcon);
              final iconColor = DefaultCategories.getColor(bill.categoryColorHex);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  urgencyText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                bill.frequency.displayName.toUpperCase(),
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormatter.format(bill.amount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Text(
          'Error loading bills: $err',
          style: const TextStyle(color: AppColors.stateError),
        ),
      ),
    );
  }

  /// Reusable Card Container for Dashboard Sections
  Widget _buildCardWrapper({
    required String title,
    required String? actionText,
    required VoidCallback? onAction,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (actionText != null)
                GestureDetector(
                  onTap: onAction,
                  child: Text(
                    actionText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Helper model for grouping current month category expenses
class _CategoryExpenseAggregate {
  final String id;
  final String name;
  final String iconName;
  final String colorHex;
  double total;

  _CategoryExpenseAggregate({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.total,
  });
}
