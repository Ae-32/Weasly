import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/financial_stats_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/chart_utils.dart';

class DayOfWeekChart extends StatelessWidget {
  final List<DayOfWeekStat> days;

  const DayOfWeekChart({
    super.key,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    int maxIdx = -1;
    double highest = -1;

    for (int i = 0; i < days.length; i++) {
      if (days[i].totalExpense > highest) {
        highest = days[i].totalExpense;
        maxIdx = i;
      }
    }

    final axisConfig = ChartAxisHelper.computeNiceYAxis(
      maxValue: highest > 0 ? highest : 0,
      targetSteps: 4,
    );

    return SizedBox(
      height: 190,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          minY: 0,
          maxY: axisConfig.maxY,
          barTouchData: BarTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.transparent,
              tooltipPadding: EdgeInsets.zero,
              tooltipMargin: 4,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = days[groupIndex];
                if (day.totalExpense <= 0) return null;
                final valStr = formatCompactCurrency(day.totalExpense);
                final isPeak = groupIndex == maxIdx && highest > 0;
                return BarTooltipItem(
                  valStr,
                  GoogleFonts.quicksand(
                    fontSize: 10,
                    fontWeight: isPeak ? FontWeight.w800 : FontWeight.w600,
                    color: isPeak ? AppColors.accentPrimary : AppColors.textMutedAlt,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: axisConfig.interval,
                getTitlesWidget: (value, meta) {
                  if (value < -0.01 || value > axisConfig.maxY + 0.01) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    formatCompactCurrency(value),
                    style: GoogleFonts.quicksand(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMutedAlt,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < days.length) {
                    final isPeak = idx == maxIdx && highest > 0;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        days[idx].dayName,
                        style: GoogleFonts.quicksand(
                          fontSize: 11,
                          fontWeight: isPeak ? FontWeight.w800 : FontWeight.w600,
                          color: isPeak ? AppColors.accentPrimary : AppColors.textMuted,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: axisConfig.interval,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: Color(0xFFEDE0D9),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(days.length, (index) {
            final isPeak = index == maxIdx && highest > 0;
            final day = days[index];
            return BarChartGroupData(
              x: index,
              showingTooltipIndicators: day.totalExpense > 0 ? [0] : [],
              barRods: [
                BarChartRodData(
                  toY: day.totalExpense,
                  color: isPeak ? AppColors.accentPrimary : AppColors.accentPrimaryLight,
                  width: 18,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
