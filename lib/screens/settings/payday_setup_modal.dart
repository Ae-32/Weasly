import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/account_model.dart';
import '../../models/payday_settings_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/payday_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/stash_icon.dart';
import '../../widgets/success_banner.dart';

/// Modal bottom sheet allowing the user to configure or edit their Payday Setup
/// featuring an interactive visual calendar to manually select payday dates,
/// preset day chips, weekend adjustment toggle, and live countdown preview.
class PaydaySetupModal extends ConsumerStatefulWidget {
  const PaydaySetupModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const PaydaySetupModal(),
    );
  }

  @override
  ConsumerState<PaydaySetupModal> createState() => _PaydaySetupModalState();
}

class _PaydaySetupModalState extends ConsumerState<PaydaySetupModal> {
  final _formKey = GlobalKey<FormState>();

  late PaydayFrequency _frequency;
  late DateTime _nextPaydayDate;
  String? _selectedAccountId;
  String? _selectedAccountName;
  int _semiMonthlyDay1 = 15;
  int _semiMonthlyDay2 = 30;
  int _monthlyDay = 15;
  bool _adjustForWeekends = true;

  // Track which semi-monthly slot is being actively targeted by calendar clicks (1 or 2)
  int _activeSemiMonthlySlot = 1;

  // Calendar month currently shown in the interactive view
  late DateTime _calendarDisplayMonth;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _frequency = PaydayFrequency.semiMonthly;
    final now = DateTime.now();
    _nextPaydayDate = now.add(const Duration(days: 7));
    _calendarDisplayMonth = DateTime(now.year, now.month, 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final currentSettings = ref.read(paydaySettingsStreamProvider).value;
      if (currentSettings != null) {
        _frequency = currentSettings.frequency;
        _nextPaydayDate = currentSettings.nextPaydayDate;
        _selectedAccountId = currentSettings.linkedAccountId;
        _selectedAccountName = currentSettings.linkedAccountName;
        _semiMonthlyDay1 = currentSettings.semiMonthlyDay1 ?? 15;
        _semiMonthlyDay2 = currentSettings.semiMonthlyDay2 ?? 30;
        _monthlyDay = currentSettings.monthlyDay ?? currentSettings.nextPaydayDate.day;
        _adjustForWeekends = currentSettings.adjustForWeekends;

        // Sync calendar view month to the upcoming payday if valid
        _calendarDisplayMonth = DateTime(
          currentSettings.nextPaydayDate.year,
          currentSettings.nextPaydayDate.month,
          1,
        );
      }
      _isInitialized = true;
    }
  }

  void _prevMonth() {
    setState(() {
      _calendarDisplayMonth = DateTime(
        _calendarDisplayMonth.year,
        _calendarDisplayMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _calendarDisplayMonth = DateTime(
        _calendarDisplayMonth.year,
        _calendarDisplayMonth.month + 1,
        1,
      );
    });
  }

  void _resetCalendarToToday() {
    final now = DateTime.now();
    setState(() {
      _calendarDisplayMonth = DateTime(now.year, now.month, 1);
    });
  }

  void _onDayTapped(int day) {
    setState(() {
      if (_frequency == PaydayFrequency.semiMonthly) {
        if (_activeSemiMonthlySlot == 1) {
          _semiMonthlyDay1 = day;
          // Auto switch to slot 2 for snappy multi-selection
          _activeSemiMonthlySlot = 2;
        } else {
          _semiMonthlyDay2 = day;
          // Switch back to slot 1
          _activeSemiMonthlySlot = 1;
        }
      } else if (_frequency == PaydayFrequency.monthly) {
        _monthlyDay = day;
      } else {
        // Weekly, Biweekly, Custom: Set the specific anchor date
        _nextPaydayDate = DateTime(
          _calendarDisplayMonth.year,
          _calendarDisplayMonth.month,
          day,
        );
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final modelBeforeCalc = PaydaySettingsModel(
      frequency: _frequency,
      nextPaydayDate: _nextPaydayDate,
      linkedAccountId: _selectedAccountId,
      linkedAccountName: _selectedAccountName,
      semiMonthlyDay1: _frequency == PaydayFrequency.semiMonthly ? _semiMonthlyDay1 : null,
      semiMonthlyDay2: _frequency == PaydayFrequency.semiMonthly ? _semiMonthlyDay2 : null,
      monthlyDay: _frequency == PaydayFrequency.monthly ? _monthlyDay : null,
      adjustForWeekends: _adjustForWeekends,
      updatedAt: now,
    );

    // Calculate actual next upcoming payday with weekend adjustment
    final nextUpcoming = modelBeforeCalc.calculateNextUpcomingPayday(now);
    final newSettings = modelBeforeCalc.copyWith(nextPaydayDate: nextUpcoming);

    final success = await ref.read(paydayControllerProvider.notifier).saveSettings(newSettings);

    if (success && mounted) {
      SuccessBanner.show(context, 'Payday settings saved!');
      Navigator.of(context).pop();
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset Payday Setup',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove your payday configuration?',
          style: GoogleFonts.quicksand(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.quicksand(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Reset',
              style: GoogleFonts.quicksand(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(paydayControllerProvider.notifier).clearSettings();
      if (success && mounted) {
        SuccessBanner.show(context, 'Payday setup reset!');
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paydayState = ref.watch(paydayControllerProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final isConfigured = ref.watch(paydaySettingsStreamProvider).value != null;

    // Calculate live upcoming payday for preview
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tempSettings = PaydaySettingsModel(
      frequency: _frequency,
      nextPaydayDate: _nextPaydayDate,
      semiMonthlyDay1: _frequency == PaydayFrequency.semiMonthly ? _semiMonthlyDay1 : null,
      semiMonthlyDay2: _frequency == PaydayFrequency.semiMonthly ? _semiMonthlyDay2 : null,
      monthlyDay: _frequency == PaydayFrequency.monthly ? _monthlyDay : null,
      adjustForWeekends: _adjustForWeekends,
    );
    final upcomingDate = tempSettings.calculateNextUpcomingPayday(today);
    final daysRemaining = DateTime(upcomingDate.year, upcomingDate.month, upcomingDate.day)
        .difference(today)
        .inDays;

    return Padding(
      padding: EdgeInsets.only(
        top: 12.0,
        left: 20.0,
        right: 20.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle Indicator
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderDefault,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.accentPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Payday Setup',
                        style: GoogleFonts.quicksand(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(
                'Manually select your payday schedule on the calendar to track your cash flow countdown.',
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 18),

              // Error Banner if any
              if (paydayState.errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.stateError.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.stateError.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    paydayState.errorMessage!,
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.stateError,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. FREQUENCY SELECTOR
              _buildFrequencySelector(),
              const SizedBox(height: 16),

              // 2. SEMI-MONTHLY DUAL SLOTS & PRESETS
              if (_frequency == PaydayFrequency.semiMonthly) ...[
                _buildSemiMonthlySlotCards(),
                const SizedBox(height: 12),
                _buildSemiMonthlyPresets(),
                const SizedBox(height: 16),
              ] else if (_frequency == PaydayFrequency.monthly) ...[
                _buildMonthlySlotCard(),
                const SizedBox(height: 12),
                _buildMonthlyPresets(),
                const SizedBox(height: 16),
              ],

              // 3. INTERACTIVE VISUAL CALENDAR
              _buildInteractiveCalendar(upcomingDate),
              const SizedBox(height: 16),

              // 4. WEEKEND ADJUSTMENT TOGGLE CARD
              _buildWeekendAdjustmentCard(upcomingDate),
              const SizedBox(height: 16),

              // 5. LIVE NEXT PAYDAY PREVIEW
              _buildNextPaydayPreview(upcomingDate, daysRemaining),
              const SizedBox(height: 18),

              // 6. LINKED STASH ACCOUNT
              _buildAccountPicker(accountsAsync),
              const SizedBox(height: 24),

              // 7. SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: paydayState.isLoading ? null : _save,
                  child: paydayState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Save Payday Setup',
                          style: GoogleFonts.quicksand(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              // 8. RESET / CLEAR BUTTON
              if (isConfigured) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: paydayState.isLoading ? null : _clear,
                    child: Text(
                      'Clear / Reset Payday Setup',
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.stateError,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- COMPONENT: Frequency Dropdown Selector ---
  Widget _buildFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payday Frequency',
          style: GoogleFonts.quicksand(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return PopupMenuButton<PaydayFrequency>(
              position: PopupMenuPosition.under,
              color: AppColors.bgSurface,
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.borderDefault),
              ),
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth,
              ),
              itemBuilder: (context) {
                return PaydayFrequency.values.map((freq) {
                  final isSelected = _frequency == freq;
                  return PopupMenuItem<PaydayFrequency>(
                    value: freq,
                    height: 44,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            freq.displayName,
                            style: GoogleFonts.quicksand(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppColors.accentPrimary : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_rounded, size: 18, color: AppColors.accentPrimary),
                      ],
                    ),
                  );
                }).toList();
              },
              onSelected: (freq) {
                setState(() {
                  _frequency = freq;
                });
              },
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderDefault),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.bgSurface,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _frequency.displayName,
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Icon(Icons.expand_more, color: AppColors.textMuted, size: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- COMPONENT: Semi-Monthly Active Day Slots ---
  Widget _buildSemiMonthlySlotCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select 2 Paydays in the Calendar',
              style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Tap calendar date to set',
              style: GoogleFonts.quicksand(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.accentPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // 1st Payday Slot Card
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeSemiMonthlySlot = 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _activeSemiMonthlySlot == 1
                        ? AppColors.accentPrimary.withValues(alpha: 0.08)
                        : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _activeSemiMonthlySlot == 1
                          ? AppColors.accentPrimary
                          : AppColors.borderDefault,
                      width: _activeSemiMonthlySlot == 1 ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '1st',
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_semiMonthlyDay1${_getDaySuffix(_semiMonthlyDay1)}',
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _activeSemiMonthlySlot == 1 ? 'Tap date below' : '1st of month',
                              style: GoogleFonts.quicksand(
                                fontSize: 11,
                                color: _activeSemiMonthlySlot == 1
                                    ? AppColors.accentPrimary
                                    : AppColors.textMuted,
                                fontWeight: _activeSemiMonthlySlot == 1 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // 2nd Payday Slot Card
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeSemiMonthlySlot = 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _activeSemiMonthlySlot == 2
                        ? AppColors.accentPrimary.withValues(alpha: 0.08)
                        : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _activeSemiMonthlySlot == 2
                          ? AppColors.accentPrimary
                          : AppColors.borderDefault,
                      width: _activeSemiMonthlySlot == 2 ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.accentSecondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '2nd',
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_semiMonthlyDay2${_getDaySuffix(_semiMonthlyDay2)}',
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _activeSemiMonthlySlot == 2 ? 'Tap date below' : '2nd of month',
                              style: GoogleFonts.quicksand(
                                fontSize: 11,
                                color: _activeSemiMonthlySlot == 2
                                    ? AppColors.accentPrimary
                                    : AppColors.textMuted,
                                fontWeight: _activeSemiMonthlySlot == 2 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- COMPONENT: Semi-Monthly Quick Presets ---
  Widget _buildSemiMonthlyPresets() {
    final presets = [
      {'label': '15th & 30th', 'd1': 15, 'd2': 30},
      {'label': '10th & 25th', 'd1': 10, 'd2': 25},
      {'label': '1st & 15th', 'd1': 1, 'd2': 15},
      {'label': '15th & End of Month', 'd1': 15, 'd2': 31},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presets.map((p) {
          final isSelected = _semiMonthlyDay1 == p['d1'] && _semiMonthlyDay2 == p['d2'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(p['label'] as String),
              selected: isSelected,
              labelStyle: GoogleFonts.quicksand(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              selectedColor: AppColors.accentPrimary,
              backgroundColor: AppColors.bgSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? AppColors.accentPrimary : AppColors.borderDefault,
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _semiMonthlyDay1 = p['d1'] as int;
                    _semiMonthlyDay2 = p['d2'] as int;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- COMPONENT: Monthly Slot Card ---
  Widget _buildMonthlySlotCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentPrimary, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentPrimary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event_repeat_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_monthlyDay${_getDaySuffix(_monthlyDay)} of every month',
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Tap any day on the calendar below to change your monthly payday',
                  style: GoogleFonts.quicksand(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- COMPONENT: Monthly Quick Presets ---
  Widget _buildMonthlyPresets() {
    final presets = [
      {'label': '15th', 'd': 15},
      {'label': '20th', 'd': 20},
      {'label': '25th', 'd': 25},
      {'label': '30th', 'd': 30},
      {'label': 'End of month (31st)', 'd': 31},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presets.map((p) {
          final isSelected = _monthlyDay == p['d'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(p['label'] as String),
              selected: isSelected,
              labelStyle: GoogleFonts.quicksand(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              selectedColor: AppColors.accentPrimary,
              backgroundColor: AppColors.bgSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? AppColors.accentPrimary : AppColors.borderDefault,
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _monthlyDay = p['d'] as int;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- COMPONENT: Interactive Visual Calendar ---
  Widget _buildInteractiveCalendar(DateTime upcomingDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthFormat = DateFormat('MMMM yyyy');

    final year = _calendarDisplayMonth.year;
    final month = _calendarDisplayMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday; // 1 = Mon ... 7 = Sun
    final firstDayOffset = firstWeekday % 7; // Sunday = 0, Monday = 1 ...

    final isCurrentMonth = today.year == year && today.month == month;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Month Navigation Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: _prevMonth,
              ),
              GestureDetector(
                onTap: _resetCalendarToToday,
                child: Row(
                  children: [
                    Text(
                      monthFormat.format(_calendarDisplayMonth),
                      style: GoogleFonts.quicksand(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (!isCurrentMonth) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.bgBase,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: Text(
                          'Today',
                          style: GoogleFonts.quicksand(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Day of Week Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].asMap().entries.map((entry) {
              final isWeekend = entry.key == 0 || entry.key == 6;
              return Expanded(
                child: Center(
                  child: Text(
                    entry.value,
                    style: GoogleFonts.quicksand(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isWeekend ? AppColors.accentPrimary : AppColors.textMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.borderDefault),
          const SizedBox(height: 8),

          // Calendar Days Grid (Calculated rows)
          _buildCalendarGridRows(
            year: year,
            month: month,
            firstDayOffset: firstDayOffset,
            daysInMonth: daysInMonth,
            today: today,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGridRows({
    required int year,
    required int month,
    required int firstDayOffset,
    required int daysInMonth,
    required DateTime today,
  }) {
    final totalCells = firstDayOffset + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rowCount, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final day = cellIndex - firstDayOffset + 1;

              if (day < 1 || day > daysInMonth) {
                return const Expanded(child: SizedBox(height: 38));
              }

              final isToday = today.year == year && today.month == month && today.day == day;
              final isWeekend = colIndex == 0 || colIndex == 6;

              // Check selection status
              bool isSlot1 = false;
              bool isSlot2 = false;
              bool isMonthlySelected = false;
              bool isExactDate = false;

              if (_frequency == PaydayFrequency.semiMonthly) {
                isSlot1 = day == _semiMonthlyDay1;
                isSlot2 = day == _semiMonthlyDay2;
              } else if (_frequency == PaydayFrequency.monthly) {
                isMonthlySelected = day == _monthlyDay;
              } else {
                isExactDate = _nextPaydayDate.year == year &&
                    _nextPaydayDate.month == month &&
                    _nextPaydayDate.day == day;
              }

              final isSelected = isSlot1 || isSlot2 || isMonthlySelected || isExactDate;

              Color bgColor = Colors.transparent;
              Color textColor = isWeekend ? AppColors.textMuted : AppColors.textPrimary;
              String? badgeText;

              if (isSlot1) {
                bgColor = AppColors.accentPrimary;
                textColor = Colors.white;
                badgeText = '1st';
              } else if (isSlot2) {
                bgColor = AppColors.accentSecondary;
                textColor = Colors.white;
                badgeText = '2nd';
              } else if (isMonthlySelected || isExactDate) {
                bgColor = AppColors.accentPrimary;
                textColor = Colors.white;
                badgeText = 'Pay';
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onDayTapped(day),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: bgColor,
                            border: isToday && !isSelected
                                ? Border.all(color: AppColors.accentPrimary, width: 1.5)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '$day',
                              style: GoogleFonts.quicksand(
                                fontSize: 13,
                                fontWeight: isSelected || isToday
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),

                        // Badge overlay for selected slots
                        if (badgeText != null)
                          Positioned(
                            bottom: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSlot2 ? AppColors.accentSecondary : AppColors.accentPrimary,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              child: Text(
                                badgeText,
                                style: GoogleFonts.quicksand(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                        // Weekend indicator dot if weekend adjustment applies
                        if (_adjustForWeekends && isSelected && isWeekend)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.stateWarning,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  // --- COMPONENT: Weekend Adjustment Card ---
  Widget _buildWeekendAdjustmentCard(DateTime upcomingDate) {
    // Check if any selected days fall on a weekend in the current view
    final year = _calendarDisplayMonth.year;
    final month = _calendarDisplayMonth.month;

    String? shiftNotice;
    if (_frequency == PaydayFrequency.semiMonthly) {
      final daysInM = DateTime(year, month + 1, 0).day;
      final d1 = _semiMonthlyDay1 > daysInM ? daysInM : _semiMonthlyDay1;
      final d2 = _semiMonthlyDay2 > daysInM ? daysInM : _semiMonthlyDay2;

      final dt1 = DateTime(year, month, d1);
      final dt2 = DateTime(year, month, d2);

      if (dt1.weekday == DateTime.saturday || dt1.weekday == DateTime.sunday) {
        final adj = PaydaySettingsModel.adjustDateIfWeekend(dt1, true);
        shiftNotice = 'Day $d1 falls on a weekend ➔ Adjusted to ${DateFormat('EEE, MMM d').format(adj)}';
      } else if (dt2.weekday == DateTime.saturday || dt2.weekday == DateTime.sunday) {
        final adj = PaydaySettingsModel.adjustDateIfWeekend(dt2, true);
        shiftNotice = 'Day $d2 falls on a weekend ➔ Adjusted to ${DateFormat('EEE, MMM d').format(adj)}';
      }
    } else if (_frequency == PaydayFrequency.monthly) {
      final daysInM = DateTime(year, month + 1, 0).day;
      final d = _monthlyDay > daysInM ? daysInM : _monthlyDay;
      final dt = DateTime(year, month, d);
      if (dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday) {
        final adj = PaydaySettingsModel.adjustDateIfWeekend(dt, true);
        shiftNotice = 'Day $d falls on a weekend ➔ Adjusted to ${DateFormat('EEE, MMM d').format(adj)}';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.work_history_rounded,
                  color: AppColors.accentPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adjust for Weekends',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Shift payday to Friday if date falls on Saturday or Sunday',
                      style: GoogleFonts.quicksand(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _adjustForWeekends,
                activeThumbColor: AppColors.accentPrimary,
                onChanged: (val) {
                  setState(() => _adjustForWeekends = val);
                },
              ),
            ],
          ),
          if (_adjustForWeekends && shiftNotice != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.stateWarning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.stateWarning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      shiftNotice,
                      style: GoogleFonts.quicksand(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- COMPONENT: Next Payday Live Preview ---
  Widget _buildNextPaydayPreview(DateTime upcomingDate, int daysRemaining) {
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');

    String subtitle = 'Countdown active';
    if (daysRemaining == 0) {
      subtitle = 'Payday is TODAY! 🎉';
    } else if (daysRemaining == 1) {
      subtitle = '1 day remaining';
    } else {
      subtitle = '$daysRemaining days remaining';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFFFF7F0),
            Color(0xFFFBE4D2),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(224, 110, 3, 0.15),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.savings_rounded,
              color: AppColors.accentPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT EXPECTED PAYDAY',
                  style: GoogleFonts.quicksand(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormatter.format(upcomingDate),
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- COMPONENT: Linked Stash Account Dropdown ---
  Widget _buildAccountPicker(AsyncValue<List<AccountModel>> accountsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Linked Stash Account',
          style: GoogleFonts.quicksand(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        accountsAsync.when(
          data: (accounts) {
            final selectedAccount = accounts.where((a) => a.id == _selectedAccountId).firstOrNull;
            final displayText = selectedAccount?.name ?? 'None (Unlinked)';

            return LayoutBuilder(
              builder: (context, constraints) {
                return PopupMenuButton<String?>(
                  position: PopupMenuPosition.under,
                  color: AppColors.bgSurface,
                  elevation: 4,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.borderDefault),
                  ),
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                    maxWidth: constraints.maxWidth,
                    maxHeight: 250,
                  ),
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem<String?>(
                        value: null,
                        height: 44,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'None (Unlinked)',
                                style: GoogleFonts.quicksand(
                                  fontSize: 14,
                                  color: AppColors.textMuted,
                                  fontWeight: _selectedAccountId == null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (_selectedAccountId == null)
                              const Icon(Icons.check_rounded, size: 16, color: AppColors.accentPrimary),
                          ],
                        ),
                      ),
                      ...accounts.map(
                        (acc) {
                          final isSelected = acc.id == _selectedAccountId;
                          return PopupMenuItem<String?>(
                            value: acc.id,
                            child: Row(
                              children: [
                                StashIcon.fromAccount(acc, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    acc.name,
                                    style: GoogleFonts.quicksand(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? AppColors.accentPrimary : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_rounded, size: 16, color: AppColors.accentPrimary),
                              ],
                            ),
                          );
                        },
                      ),
                    ];
                  },
                  onSelected: (selectedId) {
                    setState(() {
                      _selectedAccountId = selectedId;
                      if (selectedId != null) {
                        final match = accounts.firstWhere((a) => a.id == selectedId);
                        _selectedAccountName = match.name;
                      } else {
                        _selectedAccountName = null;
                      }
                    });
                  },
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderDefault),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.bgSurface,
                    ),
                    child: Row(
                      children: [
                        if (selectedAccount != null) ...[
                          StashIcon.fromAccount(selectedAccount, size: 22),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            displayText,
                            style: GoogleFonts.quicksand(
                              fontSize: 14,
                              color: selectedAccount != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontWeight: selectedAccount != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        const Icon(Icons.expand_more, color: AppColors.textMuted, size: 20),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (err, _) => Text(
            'Could not load stashes',
            style: GoogleFonts.quicksand(fontSize: 12, color: AppColors.stateError),
          ),
        ),
      ],
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
