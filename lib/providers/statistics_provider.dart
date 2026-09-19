import 'package:flutter_riverpod/flutter_riverpod.dart';
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
