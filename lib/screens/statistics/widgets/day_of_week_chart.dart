import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/financial_stats_model.dart';
import '../../../utils/app_colors.dart';

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

    double maxVal = 100.0;
    int maxIdx = -1;
    double highest = -1;

    for (int i = 0; i < days.length; i++) {
      if (days[i].totalExpense > maxVal) maxVal = days[i].totalExpense;
      if (days[i].totalExpense > highest) {
        highest = days[i].totalExpense;
        maxIdx = i;
      }
    }
    maxVal = (maxVal * 1.2);

    final currencyFormatter = NumberFormat.compactCurrency(symbol: '₱');

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = days[groupIndex];
                final valStr = NumberFormat.currency(symbol: '₱').format(day.totalExpense);
                return BarTooltipItem(
                  '${day.dayName}\n$valStr',
                  GoogleFonts.quicksand(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
                reservedSize: 40,
                interval: maxVal > 0 ? maxVal / 3 : 100,
                getTitlesWidget: (value, meta) {
                  return Text(
                    currencyFormatter.format(value),
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
            horizontalInterval: maxVal > 0 ? maxVal / 3 : 100,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: Color(0xFFEDE0D9),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(days.length, (index) {
            final isPeak = index == maxIdx && highest > 0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: days[index].totalExpense,
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
