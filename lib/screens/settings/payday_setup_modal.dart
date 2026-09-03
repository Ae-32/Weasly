import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/payday_settings_model.dart';
import '../../providers/account_provider.dart';

import '../../providers/payday_provider.dart';
import '../../utils/app_colors.dart';

/// Modal bottom sheet allowing the user to configure or edit their Payday Setup.
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
  late TextEditingController _amountController;
  String? _selectedAccountId;
  String? _selectedAccountName;
  int _semiMonthlyDay1 = 15;
  int _semiMonthlyDay2 = 30;
  int _monthlyDay = 15;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _frequency = PaydayFrequency.semiMonthly;
    _nextPaydayDate = DateTime.now().add(const Duration(days: 7));
    _amountController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final currentSettings = ref.read(paydaySettingsStreamProvider).value;
      if (currentSettings != null) {
        _frequency = currentSettings.frequency;
        _nextPaydayDate = currentSettings.nextPaydayDate;
        _amountController.text = currentSettings.expectedAmount > 0
            ? currentSettings.expectedAmount.toStringAsFixed(2)
            : '';
        _selectedAccountId = currentSettings.linkedAccountId;
        _selectedAccountName = currentSettings.linkedAccountName;
        _semiMonthlyDay1 = currentSettings.semiMonthlyDay1 ?? 15;
        _semiMonthlyDay2 = currentSettings.semiMonthlyDay2 ?? 30;
        _monthlyDay = currentSettings.monthlyDay ?? currentSettings.nextPaydayDate.day;
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextPaydayDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accentPrimary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _nextPaydayDate = picked;
        if (_frequency == PaydayFrequency.monthly) {
          _monthlyDay = picked.day;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final newSettings = PaydaySettingsModel(
      frequency: _frequency,
      nextPaydayDate: _nextPaydayDate,
      expectedAmount: amount,
      linkedAccountId: _selectedAccountId,
      linkedAccountName: _selectedAccountName,
      semiMonthlyDay1: _frequency == PaydayFrequency.semiMonthly ? _semiMonthlyDay1 : null,
      semiMonthlyDay2: _frequency == PaydayFrequency.semiMonthly ? _semiMonthlyDay2 : null,
      monthlyDay: _frequency == PaydayFrequency.monthly ? _monthlyDay : null,
      updatedAt: DateTime.now(),
    );

    final success = await ref.read(paydayControllerProvider.notifier).saveSettings(newSettings);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payday setup saved successfully!',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.stateSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset Payday Setup', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove your payday configuration?',
          style: GoogleFonts.quicksand(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.quicksand(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.stateError),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Reset', style: GoogleFonts.quicksand(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(paydayControllerProvider.notifier).clearSettings();
      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payday setup cleared.', style: GoogleFonts.quicksand()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paydayState = ref.watch(paydayControllerProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final isConfigured = ref.watch(paydaySettingsStreamProvider).value != null;
    final dateFormatter = DateFormat('EEEE, MMM d, yyyy');

    return Padding(
      padding: EdgeInsets.only(
        top: 24.0,
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
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payday Setup',
                    style: GoogleFonts.quicksand(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(
                'Configure your expected payday schedule to keep track of your cash flow countdown.',
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),

              // Error banner if any
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
              Text(
                'PAYDAY FREQUENCY',
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PaydayFrequency.values.map((freq) {
                  final isSelected = _frequency == freq;
                  return ChoiceChip(
                    label: Text(freq.displayName),
                    labelStyle: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.accentPrimary,
                    backgroundColor: AppColors.bgBase,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppColors.accentPrimary : AppColors.borderDefault,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _frequency = freq;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 2. SEMI-MONTHLY / MONTHLY DAY PICKERS
              if (_frequency == PaydayFrequency.semiMonthly) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1st Payday Day',
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<int>(
                            initialValue: _semiMonthlyDay1,

                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.borderDefault),
                              ),
                            ),
                            items: List.generate(31, (i) => i + 1)
                                .map((day) => DropdownMenuItem(
                                      value: day,
                                      child: Text('$day${_getDaySuffix(day)} of month', style: GoogleFonts.quicksand(fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _semiMonthlyDay1 = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '2nd Payday Day',
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<int>(
                            initialValue: _semiMonthlyDay2,

                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.borderDefault),
                              ),
                            ),
                            items: List.generate(31, (i) => i + 1)
                                .map((day) => DropdownMenuItem(
                                      value: day,
                                      child: Text('$day${_getDaySuffix(day)} of month', style: GoogleFonts.quicksand(fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _semiMonthlyDay2 = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ] else if (_frequency == PaydayFrequency.monthly) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payday Day of Month',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      initialValue: _monthlyDay,

                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderDefault),
                        ),
                      ),
                      items: List.generate(31, (i) => i + 1)
                          .map((day) => DropdownMenuItem(
                                value: day,
                                child: Text('$day${_getDaySuffix(day)} of every month', style: GoogleFonts.quicksand(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _monthlyDay = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // 3. NEXT/ANCHOR PAYDAY DATE
              Text(
                _frequency == PaydayFrequency.custom
                    ? 'NEXT PAYDAY DATE'
                    : 'START/ANCHOR PAYDAY DATE',
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.bgBase,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateFormatter.format(_nextPaydayDate),
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.accentPrimary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. EXPECTED AMOUNT
              Text(
                'EXPECTED AMOUNT PER PAYDAY',
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                decoration: InputDecoration(
                  prefixText: '₱ ',
                  prefixStyle: GoogleFonts.quicksand(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentPrimary,
                  ),
                  hintText: '0.00',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderDefault),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accentPrimary, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter expected amount';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid positive amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 5. LINKED ACCOUNT STASH
              Text(
                'LINKED STASH ACCOUNT',
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              accountsAsync.when(
                data: (accounts) {
                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedAccountId,

                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderDefault),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'None (Unlinked)',
                          style: GoogleFonts.quicksand(fontSize: 14, color: AppColors.textMuted),
                        ),
                      ),
                      ...accounts.map(
                        (acc) => DropdownMenuItem<String?>(
                          value: acc.id,
                          child: Text(
                            acc.name,
                            style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (selectedId) {
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
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text(
                  'Could not load stashes',
                  style: GoogleFonts.quicksand(fontSize: 12, color: AppColors.stateError),
                ),
              ),
              const SizedBox(height: 28),

              // SAVE & CLEAR BUTTONS
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
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

              if (isConfigured) ...[
                const SizedBox(height: 12),
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
