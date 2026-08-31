import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction_model.dart';
import 'recurring_bill_provider.dart';
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

/// Computed provider generating data-driven mascot insights from actual user transactions.
final mascotInsightProvider = Provider<String>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);

  return transactionsAsync.when(
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
});

/// Model holding computed payday countdown details.
class PaydayInfo {
  final int daysRemaining;
  final DateTime expectedDate;
  final double? expectedAmount;
  final String title;
  final String sourceDescription;

  const PaydayInfo({
    required this.daysRemaining,
    required this.expectedDate,
    this.expectedAmount,
    required this.title,
    required this.sourceDescription,
  });
}

/// Computed provider calculating the countdown to the user's next expected income/payday.
final paydayCountdownProvider = Provider<PaydayInfo?>((ref) {
  final recurringBillsAsync = ref.watch(recurringBillsStreamProvider);
  final transactionsAsync = ref.watch(transactionsStreamProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // 1. Check recurring bills/income entries for upcoming income
  final recurringBills = recurringBillsAsync.asData?.value ?? [];
  final upcomingIncomeBills = recurringBills.where((bill) {
    final catName = bill.categoryName.toLowerCase();
    final billName = bill.name.toLowerCase();
    final isIncomeType = catName.contains('salary') ||
        catName.contains('income') ||
        billName.contains('salary') ||
        billName.contains('payday') ||
        billName.contains('income');
    final isUpcoming = !bill.nextDueDate.isBefore(today);
    return isIncomeType && isUpcoming;
  }).toList();

  if (upcomingIncomeBills.isNotEmpty) {
    upcomingIncomeBills.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    final earliest = upcomingIncomeBills.first;
    final dueDateOnly = DateTime(earliest.nextDueDate.year, earliest.nextDueDate.month, earliest.nextDueDate.day);
    final days = dueDateOnly.difference(today).inDays;

    return PaydayInfo(
      daysRemaining: days < 0 ? 0 : days,
      expectedDate: earliest.nextDueDate,
      expectedAmount: earliest.amount,
      title: earliest.name,
      sourceDescription: 'From recurring schedule',
    );
  }

  // 2. Check past salary/income transactions pattern
  final transactions = transactionsAsync.asData?.value ?? [];
  final salaryTxs = transactions.where((tx) {
    final catName = tx.categoryName.toLowerCase();
    final note = (tx.note ?? '').toLowerCase();
    return tx.type == TransactionType.income &&
        (catName.contains('salary') || catName.contains('income') || note.contains('salary') || note.contains('payday'));
  }).toList();

  if (salaryTxs.isNotEmpty) {
    salaryTxs.sort((a, b) => b.date.compareTo(a.date));
    final latestSalary = salaryTxs.first;

    // Project next payday date based on monthly/semi-monthly frequency
    DateTime projected = DateTime(latestSalary.date.year, latestSalary.date.month + 1, latestSalary.date.day);
    while (projected.isBefore(today)) {
      projected = DateTime(projected.year, projected.month + 1, projected.day);
    }

    final days = projected.difference(today).inDays;
    return PaydayInfo(
      daysRemaining: days < 0 ? 0 : days,
      expectedDate: projected,
      expectedAmount: latestSalary.amount,
      title: latestSalary.categoryName,
      sourceDescription: 'Estimated from past salary',
    );
  }

  return null;
});
