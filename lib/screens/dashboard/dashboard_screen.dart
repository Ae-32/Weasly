import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/recurring_bill_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/chart_style_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/home_nav_provider.dart';
import '../../providers/recurring_bill_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/default_categories.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/income_expense_donut_chart.dart';
import '../../widgets/percentage_speech_bubble.dart';
import '../../widgets/weasly_app_header.dart';
import '../recurring_bills/recurring_bills_screen.dart';

/// Full live Dashboard screen matching exact Figma CSS export & redesign-v2 specifications
/// with large overlapping mascot illustrations that break container boundaries.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreetingPrefix() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final accountsCount = accountsAsync.value?.length ?? 0;
    final recurringBillsAsync = ref.watch(recurringBillsStreamProvider);
    final budgetsWithSpent = ref.watch(budgetsWithSpentProvider);

    // Dashboard Redesign Providers
    final activePeriod = ref.watch(dashboardPeriodProvider);
    final periodTransactions = ref.watch(periodTransactionsProvider);
    final periodSummary = ref.watch(periodSummaryProvider);
    final mascotInsight = ref.watch(mascotInsightProvider);

    final user = authState.value;
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final currencyFormatterShort = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

    final now = DateTime.now();
    final dateHeader = DateFormat('EEEE - MMMM d, yyyy').format(now).toUpperCase();
    final greetingPrefix = _getGreetingPrefix();
    final userName = user?.displayName ?? user?.email?.split('@').first ?? 'Ae';

    // Warning / Over budget alerts
    final warningBudgets = budgetsWithSpent
        .where((b) => b.status == BudgetStatus.nearingLimit || b.status == BudgetStatus.overBudget)
        .take(2)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Fixed Top Header Bar (Logo, Date, Greeting, Action Buttons)
            WeaslyAppHeader(
              topLabel: dateHeader,
              title: '$greetingPrefix, $userName!',
              inlineTitle: true,
            ),

            // 2. Scrollable Dashboard Body Area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mascot Insight Speech Bubble (Overlapping Band Stack)
                    _buildMascotSpeechBubbleBanner(
                      mascotInsight: mascotInsight,
                    ),

                    // Content Canvas Container
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2. Total Balance Summary Card (Overlapping Top-Right Mascot)
                          _buildTotalBalanceCard(totalBalance, accountsCount, currencyFormatter),
                          const SizedBox(height: 20),



                          // 3. Income and Expenses Card (with Period Toggle)
                          IncomeExpenseDonutChart(
                            summary: periodSummary,
                            period: activePeriod,
                            periodToggle: _buildPeriodToggleBar(ref, activePeriod),
                          ),
                          const SizedBox(height: 16),

                          // 4. Spending by Category Card
                          _buildCategorySpendingSection(
                            context,
                            ref,
                            periodTransactions,
                            activePeriod,
                            currencyFormatterShort,
                          ),
                          const SizedBox(height: 16),

                          // Budget Alerts (Hidden if no budgets in warning/over state)
                          if (warningBudgets.isNotEmpty) ...[
                            _buildBudgetAlertsSection(context, ref, warningBudgets, currencyFormatter),
                            const SizedBox(height: 16),
                          ],

                          // 6. Recent Transactions List
                          _buildRecentTransactionsSection(
                            context,
                            ref,
                            periodTransactions,
                            activePeriod,
                            currencyFormatter,
                          ),
                          const SizedBox(height: 20),

                          // Upcoming Bills Preview Section (Temporarily hidden)
                          // _buildRecurringBillsSection(context, ref, recurringBillsAsync, currencyFormatter),
                          // const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Orange Background Accent Band + Mascot Insight Bubble Stack (Figma Spec)
  Widget _buildMascotSpeechBubbleBanner({
    required String mascotInsight,
  }) {
    return SizedBox(
      height: 135,
      child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Orange Background Band (Rectangle 1)
              Positioned(
                left: 0,
                right: 0,
                top: 80,
                height: 60,
                child: Container(
                  color: AppColors.accentPrimary,
                ),
              ),

              // Pointer Tail for Speech Bubble
              Positioned(
                left: 106,
                top: 40,
                child: CustomPaint(
                  size: const Size(12, 18),
                  painter: _SpeechBubblePointerPainter(),
                ),
              ),

              // Speech Bubble Container (Union / Rectangle 2)
              Positioned(
                left: 116,
                right: 20,
                top: 10,
                height: 93,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC25814), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(43, 36, 32, 0.06),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weasly',
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentPrimary,
                          letterSpacing: -0.64,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          mascotInsight,
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Mascot Illustration on Left - Overlapping Band & Speech Bubble & Extending Below!
              Positioned(
                left: -4,
                top: 0,
                width: 145,
                height: 146,
                child: Image.asset(
                  'assets/images/Weasly_Dashboard_Welcome.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        );
  }

  /// Total Balance Summary Card (Overlapping Mascot Top-Right Corner)
  Widget _buildTotalBalanceCard(
    double totalBalance,
    int accountsCount,
    NumberFormat currencyFormatter,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // White Card Container
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 110),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Balance',
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 1),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          currencyFormatter.format(totalBalance),
                          style: GoogleFonts.quicksand(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Across $accountsCount ${accountsCount == 1 ? 'Stash' : 'Stashes'}',
                        style: GoogleFonts.quicksand(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9A9998),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 100), // Reserved space for overlapping mascot
              ],
            ),
          ),

          // Overlapping Mascot Illustration on Top-Right Corner (Flipped to face text)
          Positioned(
            right: -6,
            top: -40,
            width: 145,
            height: 146,
            child: Image.asset(
              'assets/images/Weasly_Dashboard_TotalBalance.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  /// Segmented period toggle pill (Day | Week | Month)
  Widget _buildPeriodToggleBar(WidgetRef ref, DashboardPeriod activePeriod) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE0D9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: DashboardPeriod.values.map((period) {
          final isSelected = period == activePeriod;
          final label = period == DashboardPeriod.today ? 'Day' : period.label;

          return GestureDetector(
            onTap: () {
              ref.read(dashboardPeriodProvider.notifier).state = period;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                label,
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.accentPrimary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Budget Alerts Warning Highlight Section
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
            Text(
              'Budget Alerts',
              style: GoogleFonts.quicksand(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                ref.read(homeNavIndexProvider.notifier).state = 2; // Switch to Budgets tab
              },
              child: Text(
                'View Budgets',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...warningBudgets.map((item) {
          final isOver = item.status == BudgetStatus.overBudget;
          final statusColor = item.status.color;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
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
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.budget.categoryName,
                            style: GoogleFonts.quicksand(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            item.status.label,
                            style: GoogleFonts.quicksand(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${currencyFormatter.format(item.spentAmount)} spent of ${currencyFormatter.format(item.budget.amount)}',
                        style: GoogleFonts.quicksand(fontSize: 11, color: AppColors.textMuted),
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

  Widget _buildPeriodBadgePill(DashboardPeriod activePeriod) {
    String label;
    switch (activePeriod) {
      case DashboardPeriod.today:
        label = 'Today';
        break;
      case DashboardPeriod.week:
        label = 'Week';
        break;
      case DashboardPeriod.month:
        label = 'Month';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE0D9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.quicksand(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.accentPrimary,
        ),
      ),
    );
  }

  /// Section - Category Spending Breakdown (Figma Spec)
  Widget _buildCategorySpendingSection(
    BuildContext context,
    WidgetRef ref,
    List<TransactionModel> transactions,
    DashboardPeriod activePeriod,
    NumberFormat currencyFormatterShort,
  ) {
    final periodExpenses = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .toList();

    final badgePill = _buildPeriodBadgePill(activePeriod);

    if (periodExpenses.isEmpty) {
      return _buildCardWrapper(
        title: 'SPENDING BY CATEGORY',
        actionWidget: badgePill,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Center(
            child: Text(
              'No expenses logged for this period.',
              style: GoogleFonts.quicksand(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    // Group expenses by category
    final Map<String, _CategoryExpenseAggregate> categoryMap = {};
    double totalExpensePeriod = 0.0;

    for (final tx in periodExpenses) {
      totalExpensePeriod += tx.amount;
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

    final showAll = ref.watch(categorySpendingShowAllProvider);
    final hasMoreCategories = sortedCategories.length > 4;
    final displayCategories = (showAll || !hasMoreCategories)
        ? sortedCategories
        : sortedCategories.take(4).toList();

    final pieChartStyle = ref.watch(pieChartStyleProvider);
    final isInteractive = pieChartStyle == PieChartStyle.interactive;

    final touchedIndex = ref.watch(touchedCategoryIndexProvider);
    final activeIndex = (touchedIndex >= 0 && touchedIndex < sortedCategories.length)
        ? touchedIndex
        : 0;

    final focusCat = sortedCategories.isNotEmpty ? sortedCategories[activeIndex] : null;
    final focusPct = (focusCat != null && totalExpensePeriod > 0)
        ? ((focusCat.total / totalExpensePeriod) * 100).round()
        : 0;
    final focusColor = focusCat != null
        ? DefaultCategories.getCategoryColorByName(focusCat.name, focusCat.colorHex)
        : AppColors.accentPrimary;

    return _buildCardWrapper(
      title: 'SPENDING BY CATEGORY',
      actionWidget: badgePill,
      child: Column(
        children: [
          // Donut Chart & Category Summary Row
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 22, top: 10, bottom: 10),
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                return;
                              }
                              final idx = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              if (idx >= 0 && idx < sortedCategories.length) {
                                ref.read(touchedCategoryIndexProvider.notifier).state = idx;
                              }
                            },
                          ),
                          sectionsSpace: 3,
                          centerSpaceRadius: isInteractive ? 38 : 34,
                          startDegreeOffset: -90,
                          sections: List.generate(sortedCategories.length, (index) {
                            final isTouched = isInteractive && (index == activeIndex);
                            final cat = sortedCategories[index];
                            final color = DefaultCategories.getCategoryColorByName(cat.name, cat.colorHex);
                            return PieChartSectionData(
                              color: color,
                              value: cat.total,
                              title: '',
                              radius: isTouched ? 20 : 15,
                            );
                          }),
                        ),
                      ),
                      // Center Interactive Category Focus Indicator (When Interactive Mode Enabled)
                      if (isInteractive && focusCat != null)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxWidth: 52),
                              child: Text(
                                focusCat.name,
                                style: GoogleFonts.quicksand(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Text(
                              '$focusPct%',
                              style: GoogleFonts.quicksand(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: focusColor,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),

                      // Dynamic Clockwise Slice-Anchored Speech Bubbles (When Bubble Mode Enabled)
                      if (!isInteractive)
                        ..._buildCategoryPercentageBubbles(sortedCategories, totalExpensePeriod),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spending by Category',
                      style: GoogleFonts.quicksand(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMutedAlt,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormatterShort.format(totalExpensePeriod),
                      style: GoogleFonts.quicksand(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Across ${sortedCategories.length} ${sortedCategories.length == 1 ? 'Category' : 'Categories'}',
                      style: GoogleFonts.quicksand(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMutedAlt,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // View All button positioned directly on top of the divider line
          if (hasMoreCategories) ...[
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  ref.read(categorySpendingShowAllProvider.notifier).state = !showAll;
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    showAll ? 'Show Less' : 'View All',
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ] else
            const SizedBox(height: 4),

          const Divider(height: 1, thickness: 0.5, color: AppColors.borderDefault),
          const SizedBox(height: 12),

          // Category Progress Bars List (Top 4 by default or all if expanded)
          ...displayCategories.map((cat) {
            final pct = (cat.total / totalExpensePeriod) * 100;
            final catColor = DefaultCategories.getCategoryColorByName(cat.name, cat.colorHex);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      CategoryIcon(
                        categoryName: cat.name,
                        iconName: cat.iconName,
                        size: 26,
                        containerSize: 26,
                        color: catColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: GoogleFonts.quicksand(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: catColor,
                          ),
                        ),
                      ),
                      Text(
                        currencyFormatterShort.format(cat.total),
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: catColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0),
                      backgroundColor: AppColors.accentPrimaryLight,
                      color: catColor,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Section - Recent Transactions (Figma Spec)
  Widget _buildRecentTransactionsSection(
    BuildContext context,
    WidgetRef ref,
    List<TransactionModel> transactions,
    DashboardPeriod activePeriod,
    NumberFormat currencyFormatter,
  ) {
    final recentList = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final displayTxs = recentList.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent',
              style: GoogleFonts.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                ref.read(homeNavIndexProvider.notifier).state = 1; // Switch to Transactions tab
              },
              child: Text(
                'See All',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentPrimary,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
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
          child: displayTxs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      'No recent transactions.',
                      style: GoogleFonts.quicksand(fontSize: 14, color: AppColors.textMuted),
                    ),
                  ),
                )
              : Column(
                  children: List.generate(displayTxs.length, (index) {
                    final tx = displayTxs[index];
                    final isIncome = tx.type == TransactionType.income;
                    final prefix = isIncome ? '+' : (tx.type == TransactionType.transfer ? '⇄ ' : '-');
                    final amountColor = isIncome ? AppColors.accentPrimary : AppColors.textPrimary;

                    return Column(
                      children: [
                        if (index > 0)
                          const Divider(height: 16, thickness: 0.5, color: AppColors.borderDefault),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.bgBase,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: CategoryIcon(
                                  categoryName: tx.categoryName,
                                  iconName: tx.categoryIcon,
                                  size: 20,
                                  containerSize: 40,
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0xFF534438),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.categoryName,
                                    style: GoogleFonts.quicksand(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tx.accountName,
                                    style: GoogleFonts.quicksand(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$prefix${currencyFormatter.format(tx.amount)}',
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: amountColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
        ),
      ],
    );
  }

  /// Section - Upcoming Bills Preview
  Widget _buildRecurringBillsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<RecurringBillModel>> billsAsync,
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
      child: billsAsync.when(
        data: (bills) {
          if (bills.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'No recurring bills added.',
                  style: GoogleFonts.quicksand(fontSize: 14, color: AppColors.textMuted),
                ),
              ),
            );
          }

          final sortedBills = List<RecurringBillModel>.from(bills)
            ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
          final upcomingList = sortedBills.take(3).toList();
          final dateFormatter = DateFormat('MMM dd');

          return Column(
            children: upcomingList.map((bill) {
              final daysLeft = bill.daysUntilDue;

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
                badgeColor = AppColors.accentPrimary;
                urgencyText = 'Due ${dateFormatter.format(bill.nextDueDate)}';
              }

              final iconColor = DefaultCategories.getCategoryColorByName(bill.categoryName, bill.categoryColorHex);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: CategoryIcon(
                          categoryName: bill.categoryName,
                          iconName: bill.categoryIcon,
                          size: 18,
                          containerSize: 36,
                          borderRadius: BorderRadius.circular(10),
                          color: iconColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.name,
                            style: GoogleFonts.quicksand(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  urgencyText,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                bill.frequency.displayName,
                                style: GoogleFonts.quicksand(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormatter.format(bill.amount),
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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
          style: GoogleFonts.quicksand(color: AppColors.stateError),
        ),
      ),
    );
  }

  /// Reusable Card Wrapper Widget
  Widget _buildCardWrapper({
    required String title,
    String? actionText,
    VoidCallback? onAction,
    Widget? actionWidget,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              if (actionWidget != null)
                actionWidget
              else if (actionText != null)
                GestureDetector(
                  onTap: onAction,
                  child: Text(
                    actionText,
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: onAction != null ? AppColors.accentPrimary : AppColors.textMuted,
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

class _SpeechBubblePointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    final fillPaint = Paint()
      ..color = AppColors.bgSurface
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFC25814)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dynamic Clockwise Slice-Anchored Speech Bubbles for Category Spending Pie Chart
List<Widget> _buildCategoryPercentageBubbles(
  List<_CategoryExpenseAggregate> sortedCategories,
  double totalExpensePeriod,
) {
  if (totalExpensePeriod <= 0 || sortedCategories.isEmpty) return [];

  final widgets = <Widget>[];
  double currentAngle = -90.0; // fl_chart startDegreeOffset (top center)
  double? lastTop;
  double? lastLeft;

  for (int i = 0; i < sortedCategories.length; i++) {
    final cat = sortedCategories[i];
    final fraction = cat.total / totalExpensePeriod;
    final pct = (fraction * 100).round();
    final angleSpan = fraction * 360.0;
    final midAngle = currentAngle + (angleSpan / 2.0);
    currentAngle += angleSpan;

    // Filter out tiny slices < 3% if there are many categories to avoid clutter
    final minThreshold = sortedCategories.length > 4 ? 3 : 2;
    if (pct < minThreshold) continue;

    final rad = midAngle * (math.pi / 180.0);
    const centerX = 70.0;
    const centerY = 70.0;
    const radius = 58.0;

    final targetX = centerX + radius * math.cos(rad);
    final targetY = centerY + radius * math.sin(rad);

    final normAngle = (midAngle % 360.0 + 360.0) % 360.0;
    double left;
    double top;

    if (normAngle >= 270 || normAngle < 0) {
      left = targetX;
      top = targetY - 18;
    } else if (normAngle >= 0 && normAngle < 90) {
      left = targetX;
      top = targetY;
    } else if (normAngle >= 90 && normAngle < 180) {
      left = targetX - 32;
      top = targetY;
    } else {
      left = targetX - 32;
      top = targetY - 18;
    }

    // De-collision adjustment for consecutive badges
    if (lastTop != null && lastLeft != null) {
      final vDiff = (top - lastTop).abs();
      final hDiff = (left - lastLeft).abs();

      if (vDiff < 18.0 && hDiff < 30.0) {
        if (left < 70.0) {
          // Left side of chart: stagger upwards/outwards
          top = math.min(top, lastTop - 18.0);
          left = math.max(2.0, left - 4.0);
        } else {
          // Right side of chart: stagger downwards/outwards
          top = math.max(top, lastTop + 18.0);
        }
      }
    }

    // Enforce strict left edge & top bounds inside Stack
    if (left < 2.0) left = 2.0;
    if (top < 2.0) top = 2.0;

    lastTop = top;
    lastLeft = left;

    final color = DefaultCategories.getCategoryColorByName(cat.name, cat.colorHex);

    widgets.add(
      Positioned(
        left: left,
        top: top,
        child: PercentageSpeechBubble(
          text: '$pct%',
          backgroundColor: color,
          textColor: Colors.white,
        ),
      ),
    );
  }

  return widgets;
}



