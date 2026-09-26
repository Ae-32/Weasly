import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/financial_stats_model.dart';
import '../utils/statistics_calculator.dart';
import 'transaction_provider.dart';

/// StateProvider holding the active time range selection for statistics.
final statisticsTimeRangeProvider = StateProvider<StatsTimeRange>((ref) {
  return StatsTimeRange.thisMonth;
});

/// Computed provider calculating financial statistics based on active time range and transactions stream.
final financialStatisticsProvider = Provider<FinancialStatsModel>((ref) {
  final timeRange = ref.watch(statisticsTimeRangeProvider);
  final transactionsAsync = ref.watch(transactionsStreamProvider);

  return transactionsAsync.when(
    data: (transactions) {
      return StatisticsCalculator.computeStats(transactions, timeRange);
    },
    loading: () => FinancialStatsModel.empty(),
    error: (err, stack) => FinancialStatsModel.empty(),
  );
});

/// Computed provider generating dynamic Weasly mascot insights from live analytics.
final analyticsInsightMessagesProvider = Provider<List<String>>((ref) {
  final stats = ref.watch(financialStatisticsProvider);
  final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

  if (stats.totalIncome == 0 && stats.totalExpense == 0) {
    return [
      "No financial records found for this period. Start stashing to unlock deep insights!",
      "Tip: Add your daily expenses or income to track your cash flow trends over time.",
    ];
  }

  final List<String> messages = [];

  // 1. Net Cash Flow
  if (stats.netCashFlow > 0) {
    messages.add(
      "Awesome! You accumulated ${currencyFormatter.format(stats.netCashFlow)} in positive net cash flow!",
    );
  } else if (stats.netCashFlow < 0) {
    messages.add(
      "Heads up! Your expenses exceeded income by ${currencyFormatter.format(stats.netCashFlow.abs())}.",
    );
  } else {
    messages.add(
      "Your income and expenses balanced out perfectly during this period!",
    );
  }

  // 2. Savings Rate
  if (stats.savingsRate > 0) {
    messages.add(
      "Your savings rate reached ${stats.savingsRate.toStringAsFixed(1)}% of your total earnings!",
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

