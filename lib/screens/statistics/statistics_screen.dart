import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/statistics_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/weasly_app_header.dart';
import 'widgets/cash_flow_line_chart.dart';
import 'widgets/day_of_week_chart.dart';

/// Full Financial Statistics & Analytics Screen
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(financialStatisticsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed Top Header Bar (Logo Badge & Action Buttons)
            const WeaslyAppHeader(),

            // Scrollable Analytics Canvas Container
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scrollable Page Title & Subtitle Section
                    Text(
                      'Analytics Overview',
                      style: GoogleFonts.quicksand(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF211A16),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Insights, trends, and spending patterns.',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8A7F73),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cash Flow Line Chart Card
                    _buildCardWrapper(
                      title: 'CASH FLOW TREND (INCOME VS EXPENSE)',
                      child: CashFlowLineChart(points: stats.monthlyTrends),
                    ),
                    const SizedBox(height: 16),

                    // Day of Week Behavior Card
                    _buildCardWrapper(
                      title: 'SPENDING BY DAY OF WEEK',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Identifies which days you tend to spend the most.',
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMutedAlt,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DayOfWeekChart(days: stats.dayOfWeekSpending),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable Card Wrapper Widget
  Widget _buildCardWrapper({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(43, 36, 32, 0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.quicksand(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMutedAlt,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

