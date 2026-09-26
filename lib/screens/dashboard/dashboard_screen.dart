import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/home_nav_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/default_categories.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/income_expense_donut_chart.dart';
import '../../widgets/payday_reminder_banner.dart';
import '../../widgets/weasly_app_header.dart';

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

    // Dashboard Redesign Providers
    final activePeriod = ref.watch(dashboardPeriodProvider);
    final periodTransactions = ref.watch(periodTransactionsProvider);
    final periodSummary = ref.watch(periodSummaryProvider);

    final user = authState.value;
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final currencyFormatterShort = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

    final now = DateTime.now();
    final dateHeader = DateFormat('EEEE - MMMM d, yyyy').format(now).toUpperCase();
    final greetingPrefix = _getGreetingPrefix();
    final userName = user?.displayName ?? user?.email?.split('@').first ?? 'Ae';

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
                    const _MascotSpeechBubbleBanner(),

                    // Content Canvas Container
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Payday Reminder Banner (if prompt was dismissed)
                          const PaydayReminderBanner(),

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
                padding: const EdgeInsets.only(left: 14, top: 10, bottom: 10),
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
                          centerSpaceRadius: 40,
                          startDegreeOffset: -90,
                          sections: List.generate(sortedCategories.length, (index) {
                            final isTouched = index == activeIndex;
                            final cat = sortedCategories[index];
                            final color = DefaultCategories.getCategoryColorByName(cat.name, cat.colorHex);
                            return PieChartSectionData(
                              color: color,
                              value: cat.total,
                              title: '',
                              radius: isTouched ? 18 : 14,
                            );
                          }),
                        ),
                      ),
                      // Center Interactive Category Focus Indicator
                      if (focusCat != null)
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
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 40),
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
                ref.read(homeNavIndexProvider.notifier).state = 2; // Switch to Transactions tab
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

/// Orange Background Accent Band + Mascot Insight Bubble Stack (Figma Spec) with Cycling Insights & Budget Alerts
class _MascotSpeechBubbleBanner extends ConsumerStatefulWidget {
  const _MascotSpeechBubbleBanner();

  @override
  ConsumerState<_MascotSpeechBubbleBanner> createState() => _MascotSpeechBubbleBannerState();
}

class _MascotSpeechBubbleBannerState extends ConsumerState<_MascotSpeechBubbleBanner> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) {
      final messages = ref.read(mascotInsightMessagesProvider);
      if (messages.length > 1 && mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % messages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(mascotInsightMessagesProvider);

    if (_currentIndex >= messages.length) {
      _currentIndex = 0;
    }

    final currentMessage = messages.isNotEmpty ? messages[_currentIndex] : '';

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      if (messages.length > 1)
                        Row(
                          children: List.generate(messages.length, (index) {
                            final isActive = index == _currentIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(left: 3),
                              width: isActive ? 12 : 5,
                              height: 2,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.accentPrimary
                                    : AppColors.accentPrimary.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            );
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.topLeft,
                          children: <Widget>[
                            ...previousChildren,
                            ?currentChild,
                          ],
                        );
                      },
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.15),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        currentMessage,
                        key: ValueKey<String>(currentMessage),
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





