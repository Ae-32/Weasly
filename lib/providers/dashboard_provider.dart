import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import 'budget_provider.dart';
import 'transaction_provider.dart';

/// Enum representing the active period filter on the Dashboard.
enum DashboardPeriod {
  today,
  week,
  month;

  String get label {
    switch (this) {
      case DashboardPeriod.today:
        return 'Today';
      case DashboardPeriod.week:
        return 'Week';
      case DashboardPeriod.month:
        return 'Month';
    }
  }
}

/// Active period selection provider.
final dashboardPeriodProvider = StateProvider<DashboardPeriod>((ref) => DashboardPeriod.month);

/// Provider for toggling show all categories in Spending by Category section
final categorySpendingShowAllProvider = StateProvider<bool>((ref) => false);

/// Active touched category index on the Donut Chart (-1 means top category/default)
final touchedCategoryIndexProvider = StateProvider.autoDispose<int>((ref) => -1);

/// Helper function checking if a DateTime falls within the given DashboardPeriod.
bool isDateInDashboardPeriod(DateTime date, DashboardPeriod period, DateTime referenceNow) {
  final d = DateTime(date.year, date.month, date.day);
  final now = DateTime(referenceNow.year, referenceNow.month, referenceNow.day);

  switch (period) {
    case DashboardPeriod.today:
      return d.year == now.year && d.month == now.month && d.day == now.day;
    case DashboardPeriod.week:
      // Current calendar week (Monday to Sunday)
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      return (d.isAfter(monday.subtract(const Duration(milliseconds: 1))) &&
          d.isBefore(sunday.add(const Duration(days: 1))));
    case DashboardPeriod.month:
      return d.year == now.year && d.month == now.month;
  }
}

/// Computed provider returning transactions filtered by the active DashboardPeriod.
final periodTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final period = ref.watch(dashboardPeriodProvider);
  final transactionsAsync = ref.watch(transactionsStreamProvider);

  return transactionsAsync.when(
    data: (transactions) {
      final now = DateTime.now();
      return transactions.where((tx) => isDateInDashboardPeriod(tx.date, period, now)).toList();
    },
    loading: () => [],
    error: (err, stack) => [],
  );
});

/// Summary model for Income vs. Expense metrics.
class PeriodSummary {
  final double totalIncome;
  final double totalExpense;
  final double netCashFlow;

  const PeriodSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashFlow,
  });

  double get totalFlow => totalIncome + totalExpense;

  double get incomePercentage {
    if (totalFlow <= 0) return 0.0;
    return (totalIncome / totalFlow) * 100;
  }

  double get expensePercentage {
    if (totalFlow <= 0) return 0.0;
    return (totalExpense / totalFlow) * 100;
  }
}

/// Computed provider calculating income, expense, and ratio metrics for the selected period.
final periodSummaryProvider = Provider<PeriodSummary>((ref) {
  final periodTransactions = ref.watch(periodTransactionsProvider);

  double income = 0.0;
  double expense = 0.0;

  for (final tx in periodTransactions) {
    if (tx.type == TransactionType.income) {
      income += tx.amount;
    } else if (tx.type == TransactionType.expense) {
      expense += tx.amount;
    }
  }

  return PeriodSummary(
    totalIncome: income,
    totalExpense: expense,
    netCashFlow: income - expense,
  );
});

/// Computed provider generating data-driven mascot insights and active budget alert messages.
final mascotInsightMessagesProvider = Provider<List<String>>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final budgetsWithSpent = ref.watch(budgetsWithSpentProvider);

  // 1. Calculate general spending insight string
  final String spendingInsight = transactionsAsync.when(
    data: (transactions) {
      final now = DateTime.now();

      // Current month expense transactions
      final monthExpenses = transactions.where((tx) {
        return tx.type == TransactionType.expense &&
            tx.date.year == now.year &&
            tx.date.month == now.month;
      }).toList();

      if (monthExpenses.isEmpty) {
        return "Log a few transactions and I'll start sharing insights!";
      }

      double totalMonthExpense = 0.0;
      final Map<String, ({String name, double total})> categoryTotals = {};

      for (final tx in monthExpenses) {
        totalMonthExpense += tx.amount;
        if (categoryTotals.containsKey(tx.categoryId)) {
          final current = categoryTotals[tx.categoryId]!;
          categoryTotals[tx.categoryId] = (name: current.name, total: current.total + tx.amount);
        } else {
          categoryTotals[tx.categoryId] = (name: tx.categoryName, total: tx.amount);
        }
      }

      if (totalMonthExpense == 0 || categoryTotals.isEmpty) {
        return "Log a few transactions and I'll start sharing insights!";
      }

      // Find top expense category
      final sortedCategories = categoryTotals.values.toList()
        ..sort((a, b) => b.total.compareTo(a.total));
      final topCategory = sortedCategories.first;
      final topPercentage = (topCategory.total / totalMonthExpense) * 100;

      if (topPercentage >= 20) {
        return "${topCategory.name} makes up about ${topPercentage.toStringAsFixed(0)}% of your spending this month.";
      }

      return "Your highest spending category this month is ${topCategory.name}. Keep an eye on it!";
    },
    loading: () => "Log a few transactions and I'll start sharing insights!",
    error: (err, stack) => "Log a few transactions and I'll start sharing insights!",
  );

  final List<String> messages = [spendingInsight];

  // 2. Collect any active budget alerts
  for (final item in budgetsWithSpent) {
    if (item.status == BudgetStatus.overBudget) {
      final overAmount = item.spentAmount - item.budget.amount;
      final overFormatted = NumberFormat.currency(
        symbol: '₱',
        decimalDigits: overAmount % 1 == 0 ? 0 : 2,
      ).format(overAmount);

      messages.add("You've gone over your ${item.budget.categoryName} budget by $overFormatted.");
    } else if (item.status == BudgetStatus.nearingLimit) {
      final pctStr = item.spentPercentage.toStringAsFixed(0);

      messages.add("Your ${item.budget.categoryName} budget is at $pctStr% — getting close to the limit!");
    }
  }

  return messages;
});

/// Legacy single string mascot insight provider (returns first message).
final mascotInsightProvider = Provider<String>((ref) {
  final messages = ref.watch(mascotInsightMessagesProvider);
  return messages.isNotEmpty ? messages.first : "Log a few transactions and I'll start sharing insights!";
});

