import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../providers/statistics_provider.dart';
import '../../../utils/app_colors.dart';

class MonthSelectorHeader extends ConsumerWidget {
  const MonthSelectorHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(statisticsSelectedMonthProvider);
    final now = DateTime.now();
    final isCurrentMonth = selectedMonth.year == now.year && selectedMonth.month == now.month;

    void selectMonth(DateTime newMonth) {
      ref.read(statisticsSelectedMonthProvider.notifier).state = DateTime(newMonth.year, newMonth.month, 1);
    }

    void prevMonth() {
      selectMonth(DateTime(selectedMonth.year, selectedMonth.month - 1, 1));
    }

    void nextMonth() {
      selectMonth(DateTime(selectedMonth.year, selectedMonth.month + 1, 1));
    }

    Future<void> pickMonthFromCalendar() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedMonth,
        firstDate: DateTime(2020),
        lastDate: DateTime(now.year + 5),
        helpText: 'SELECT MONTH & YEAR',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.accentPrimary,
                onPrimary: Colors.white,
                surface: AppColors.bgSurface,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        selectMonth(DateTime(picked.year, picked.month, 1));
      }
    }

    final monthFormatter = DateFormat('MMMM yyyy');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(43, 36, 32, 0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Month Button
          IconButton(
            onPressed: prevMonth,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.textPrimary,
            tooltip: 'Previous Month',
            splashRadius: 20,
          ),

          // Center Month Title (Clickable)
          GestureDetector(
            onTap: pickMonthFromCalendar,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.accentPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  monthFormatter.format(selectedMonth),
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),

          // Right Controls: Next Month or Reset to Current Month Pill
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCurrentMonth)
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: InkWell(
                    onTap: () => selectMonth(DateTime(now.year, now.month, 1)),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimaryLight.withAlpha(120),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'This Month',
                        style: GoogleFonts.quicksand(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              IconButton(
                onPressed: nextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
                color: AppColors.textPrimary,
                tooltip: 'Next Month',
                splashRadius: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
