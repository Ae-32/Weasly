import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/payday_settings_model.dart';
import '../providers/account_provider.dart';
import '../providers/category_provider.dart';
import '../providers/payday_provider.dart';
import '../utils/app_colors.dart';
import 'stash_icon.dart';
import 'success_banner.dart';

/// Interactive modal presented automatically on Payday date (or triggered via reminder banner).
/// Allows the user to enter their actual paycheck amount, select a destination stash account,
/// and choose an income category (defaulting to Salary).
class PaydayPromptModal extends ConsumerStatefulWidget {
  final PaydaySettingsModel settings;

  const PaydayPromptModal({
    super.key,
    required this.settings,
  });

  static Future<void> show(BuildContext context, PaydaySettingsModel settings) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => PaydayPromptModal(settings: settings),
    );
  }

  @override
  ConsumerState<PaydayPromptModal> createState() => _PaydayPromptModalState();
}

class _PaydayPromptModalState extends ConsumerState<PaydayPromptModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;

  String? _selectedAccountId;
  String? _selectedAccountName;
  CategoryModel? _selectedCategory;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Pre-select linked account if configured
      _selectedAccountId = widget.settings.linkedAccountId;
      _selectedAccountName = widget.settings.linkedAccountName;

      // Pre-select Salary category if available
      final incomeCategories = ref.read(incomeCategoriesProvider);
      if (incomeCategories.isNotEmpty) {
        _selectedCategory = incomeCategories.firstWhere(
          (c) => c.name.toLowerCase() == 'salary',
          orElse: () => incomeCategories.first,
        );
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null || _selectedAccountName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a stash account to deposit into.',
            style: GoogleFonts.quicksand(),
          ),
          backgroundColor: AppColors.stateError,
        ),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select an income category.',
            style: GoogleFonts.quicksand(),
          ),
          backgroundColor: AppColors.stateError,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final success = await ref.read(paydayControllerProvider.notifier).confirmPayday(
          amount: amount,
          accountId: _selectedAccountId!,
          accountName: _selectedAccountName!,
          categoryId: _selectedCategory!.id,
          categoryName: _selectedCategory!.name,
          categoryIcon: _selectedCategory!.iconName,
          categoryColorHex: _selectedCategory!.colorHex,
          settings: widget.settings,
        );

    if (success && mounted) {
      SuccessBanner.show(context, 'It\'s official! Payday income logged to $_selectedAccountName 🎉');
      Navigator.of(context).pop();
    }
  }

  Future<void> _dismiss() async {
    await ref.read(paydayControllerProvider.notifier).dismissPayday(widget.settings);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final paydayState = ref.watch(paydayControllerProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final incomeCategories = ref.watch(incomeCategoriesProvider);

    // Auto fill account if none pre-selected and accounts load
    final accounts = accountsAsync.asData?.value ?? [];
    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
      _selectedAccountName = accounts.first.name;
    }

    // Auto fill category if none pre-selected and income categories load
    if (_selectedCategory == null && incomeCategories.isNotEmpty) {
      _selectedCategory = incomeCategories.firstWhere(
        (c) => c.name.toLowerCase() == 'salary',
        orElse: () => incomeCategories.first,
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        top: 20.0,
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
              // Top Mascot & Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/Weasly_Dashboard_PayCheck.png',
                    width: 64,
                    height: 64,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.celebration_rounded,
                      size: 44,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'It\'s Payday! 🎉',
                          style: GoogleFonts.quicksand(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Time to stash your fresh hard-earned money!',
                          style: GoogleFonts.quicksand(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: _dismiss,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Error notification if any
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

              // 1. AMOUNT RECEIVED INPUT
              Text(
                'HOW MUCH DID YOU RECEIVE?',
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
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                style: GoogleFonts.quicksand(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentPrimary,
                ),
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Text(
                      '₱',
                      style: GoogleFonts.quicksand(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  hintText: '0.00',
                  hintStyle: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMutedLight,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderDefault),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.accentPrimary, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your payday amount';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Please enter a valid amount greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 2. DESTINATION STASH ACCOUNT PICKER
              Text(
                'DEPOSIT INTO STASH',
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              accountsAsync.when(
                data: (accountsList) {
                  if (accountsList.isEmpty) {
                    return Text(
                      'No stashes found. Create a stash first.',
                      style: GoogleFonts.quicksand(fontSize: 12, color: AppColors.stateError),
                    );
                  }

                  final selectedAcc = accountsList.where((a) => a.id == _selectedAccountId).firstOrNull ?? accountsList.first;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return PopupMenuButton<AccountModel>(
                        position: PopupMenuPosition.under,
                        color: AppColors.bgSurface,
                        elevation: 4,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.borderDefault),
                        ),
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                          maxWidth: constraints.maxWidth,
                          maxHeight: 250,
                        ),
                        itemBuilder: (context) {
                          return accountsList.map((acc) {
                            final isSelected = acc.id == selectedAcc.id;
                            return PopupMenuItem<AccountModel>(
                              value: acc,
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
                          }).toList();
                        },
                        onSelected: (acc) {
                          setState(() {
                            _selectedAccountId = acc.id;
                            _selectedAccountName = acc.name;
                          });
                        },
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderDefault),
                            borderRadius: BorderRadius.circular(14),
                            color: AppColors.bgSurface,
                          ),
                          child: Row(
                            children: [
                              StashIcon.fromAccount(selectedAcc, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  selectedAcc.name,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
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
              const SizedBox(height: 20),

              // 3. CATEGORY SELECTOR (SALARY / INCOME)
              Text(
                'CATEGORY',
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              if (incomeCategories.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: incomeCategories.map((cat) {
                    final isSelected = _selectedCategory?.id == cat.id;
                    return ChoiceChip(
                      label: Text(cat.name),
                      avatar: Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.payments_rounded,
                        size: 16,
                        color: isSelected ? Colors.white : AppColors.accentPrimary,
                      ),
                      labelStyle: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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
                            _selectedCategory = cat;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 28),

              // 4. CONFIRM DEPOSIT & NOT NOW BUTTONS
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: paydayState.isLoading ? null : _confirm,
                  child: paydayState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Confirm Deposit',
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: paydayState.isLoading ? null : _dismiss,
                  child: Text(
                    'Not Now (Log Later Today)',
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
