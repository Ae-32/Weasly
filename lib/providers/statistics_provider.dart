import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/financial_stats_model.dart';
import '../utils/statistics_calculator.dart';
import 'transaction_provider.dart';

/// StateProvider holding the active time range selection for statistics.
final statisticsTimeRangeProvider = StateProvider<StatsTimeRange>((ref) {
  return StatsTimeRange.thisMonth;
});

/// StateProvider holding the selected month for past month analytics.
final statisticsSelectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

/// Computed provider calculating financial statistics based on active selected month and transactions stream.
final financialStatisticsProvider = Provider<FinancialStatsModel>((ref) {
  final timeRange = ref.watch(statisticsTimeRangeProvider);
  final selectedMonth = ref.watch(statisticsSelectedMonthProvider);
  final transactionsAsync = ref.watch(transactionsStreamProvider);

  return transactionsAsync.when(
    data: (transactions) {
      return StatisticsCalculator.computeStats(
        transactions,
        timeRange,
        selectedMonth: selectedMonth,
      );
    },
    loading: () => FinancialStatsModel.empty(),
    error: (err, stack) => FinancialStatsModel.empty(),
  );
});

/// Computed provider generating dynamic Weasly mascot insights from live analytics.
final analyticsInsightMessagesProvider = Provider<List<String>>((ref) {
  final stats = ref.watch(financialStatisticsProvider);
  final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 0);
  final monthLabel = DateFormat('MMMM yyyy').format(stats.selectedMonth);

  if (stats.totalIncome == 0 && stats.totalExpense == 0) {
    return [
      "No financial records found for $monthLabel. Start stashing to unlock deep insights!",
      "Tip: Log your daily expenses to view category breakdowns and cash flow trends.",
    ];
  }

  final List<String> messages = [];

  // Month-over-Month Spending Insight
  if (stats.previousMonthExpense > 0) {
    final changeAbs = stats.monthOverMonthChangePct.abs().toStringAsFixed(1);
    if (stats.monthOverMonthChangePct > 0) {
      messages.add(
        "In $monthLabel, spending increased by $changeAbs% compared to the previous month.",
      );
    } else if (stats.monthOverMonthChangePct < 0) {
      messages.add(
        "Great job! In $monthLabel, you spent $changeAbs% less than the previous month!",
      );
    }
  }

  // 1. Net Cash Flow
  if (stats.netCashFlow > 0) {
    messages.add(
      "Awesome! You accumulated ${currencyFormatter.format(stats.netCashFlow)} in positive net cash flow for $monthLabel!",
    );
  } else if (stats.netCashFlow < 0) {
    messages.add(
      "Heads up! Your expenses exceeded income by ${currencyFormatter.format(stats.netCashFlow.abs())} in $monthLabel.",
    );
  } else {
    messages.add(
      "Your income and expenses balanced out perfectly during $monthLabel!",
    );
  }

  // 2. Savings Rate
  if (stats.savingsRate > 0) {
    messages.add(
      "Your savings rate reached ${stats.savingsRate.toStringAsFixed(1)}% of total earnings!",
    );
  }

  // 3. Top Spending Category
  if (stats.topSpendingCategory != null) {
    messages.add(
      "${stats.topSpendingCategory!.categoryName} was your top expense category (${currencyFormatter.format(stats.topSpendingCategory!.amount)}).",
    );
  }

  // 4. Peak Day of Week
  if (stats.dayOfWeekSpending.isNotEmpty) {
    final peakDay = stats.dayOfWeekSpending.reduce((a, b) => a.totalExpense >= b.totalExpense ? a : b);
    if (peakDay.totalExpense > 0) {
      final dayFullName = _getDayFullName(peakDay.dayName);
      messages.add(
        "${dayFullName}s were your peak spending days (${currencyFormatter.format(peakDay.totalExpense)}).",
      );
    }
  }

  return messages.isEmpty
      ? ["Keep logging your daily stashes to build smarter money habits!"]
      : messages;
});

String _getDayFullName(String shortDay) {
  switch (shortDay) {
    case 'Mon':
      return 'Monday';
    case 'Tue':
      return 'Tuesday';
    case 'Wed':
      return 'Wednesday';
    case 'Thu':
      return 'Thursday';
    case 'Fri':
      return 'Friday';
    case 'Sat':
      return 'Saturday';
    case 'Sun':
      return 'Sunday';
    default:
      return shortDay;
  }
}

