import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/account_provider.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/default_categories.dart';
import 'category_icon.dart';
import 'insufficient_balance_modal.dart';

class AddEditTransactionModal extends ConsumerStatefulWidget {
  final TransactionModel? transactionToEdit;

  const AddEditTransactionModal({
    super.key,
    this.transactionToEdit,
  });

  static Future<void> show(BuildContext context, {TransactionModel? transactionToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditTransactionModal(transactionToEdit: transactionToEdit),
    );
  }

  @override
  ConsumerState<AddEditTransactionModal> createState() =>
      _AddEditTransactionModalState();
}

class _AddEditTransactionModalState
    extends ConsumerState<AddEditTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  final FocusNode _amountFocusNode = FocusNode();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TransactionType _selectedType;
  late DateTime _selectedDate;

  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;
  AccountModel? _selectedToAccount;

  @override
  void initState() {
    super.initState();
    final tx = widget.transactionToEdit;
    final isEditing = tx != null;

    _amountController = TextEditingController(
      text: isEditing ? tx.amount.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: tx?.note ?? '');
    _selectedType = isEditing ? tx.type : TransactionType.expense;
    _selectedDate = isEditing ? tx.date : DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amountVal = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amountVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than zero.', style: TextStyle(fontFamily: 'Quicksand')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an account.', style: TextStyle(fontFamily: 'Quicksand')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedType == TransactionType.transfer) {
      if (_selectedToAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a destination account for the transfer.', style: TextStyle(fontFamily: 'Quicksand')),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (_selectedAccount!.id == _selectedToAccount!.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Source and destination accounts must be different.', style: TextStyle(fontFamily: 'Quicksand')),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    } else {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a category.', style: TextStyle(fontFamily: 'Quicksand')),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final isEditing = widget.transactionToEdit != null;
    final controller = ref.read(transactionControllerProvider.notifier);

    final catId = _selectedCategory?.id ?? 'transfer';
    final catName = _selectedType == TransactionType.transfer
        ? 'Transfer'
        : (_selectedCategory?.name ?? 'General');
    final catIcon = _selectedType == TransactionType.transfer
        ? 'swap_horiz'
        : (_selectedCategory?.iconName ?? 'category');
    final catColorHex = _selectedType == TransactionType.transfer
        ? '#4E8C6E'
        : (_selectedCategory?.colorHex ?? '#8E4E00');

    bool success;
    if (isEditing) {
      final oldTx = widget.transactionToEdit!;
      final newTx = oldTx.copyWith(
        type: _selectedType,
        amount: amountVal,
        categoryId: catId,
        categoryName: catName,
        categoryIcon: catIcon,
        categoryColorHex: catColorHex,
        accountId: _selectedAccount!.id,
        accountName: _selectedAccount!.name,
        toAccountId: _selectedType == TransactionType.transfer ? _selectedToAccount!.id : null,
        toAccountName: _selectedType == TransactionType.transfer ? _selectedToAccount!.name : null,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      success = await controller.updateTransaction(oldTx: oldTx, newTx: newTx);
    } else {
      success = await controller.addTransaction(
        type: _selectedType,
        amount: amountVal,
        categoryId: catId,
        categoryName: catName,
        categoryIcon: catIcon,
        categoryColorHex: catColorHex,
        accountId: _selectedAccount!.id,
        accountName: _selectedAccount!.name,
        toAccountId: _selectedType == TransactionType.transfer ? _selectedToAccount!.id : null,
        toAccountName: _selectedType == TransactionType.transfer ? _selectedToAccount!.name : null,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else {
        final err = ref.read(transactionControllerProvider).errorMessage;
        if (err != null && (err.contains("INSUFFICIENT_BALANCE") || err.toLowerCase().contains("insufficient balance"))) {
          double availBal = 0.0;
          if (err.contains("INSUFFICIENT_BALANCE")) {
            final parts = err.split('|');
            if (parts.length >= 3) {
              final rawAvail = parts[2].replaceAll('₱', '').replaceAll(',', '').trim();
              availBal = double.tryParse(rawAvail) ?? 0.0;
            }
          } else {
            availBal = _selectedAccount?.balance ?? 0.0;
          }

          final result = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => InsufficientBalanceModal(
              accountName: _selectedAccount?.name ?? 'Account',
              accountIcon: _getAccountIconData(_selectedAccount?.type),
              categoryIcon: _getCategoryIconData(_selectedCategory?.iconName),
              availableBalance: availBal,
              attemptedAmount: amountVal,
              isTransfer: _selectedType == TransactionType.transfer,
            ),
          );

          if (mounted) {
            if (result == 'adjust') {
              _amountFocusNode.requestFocus();
              _amountController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _amountController.text.length,
              );
            } else if (result == 'cancel') {
              Navigator.of(context).pop();
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transactionToEdit != null;
    final state = ref.watch(transactionControllerProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateFormatter = DateFormat('MMM dd, yyyy');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.borderDefault,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Transaction' : 'Add Transaction',
                    style: const TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (state.errorMessage != null && !state.errorMessage!.contains("INSUFFICIENT_BALANCE")) ...[
                _buildErrorBanner(state.errorMessage!),
                const SizedBox(height: 16),
              ],

              // Type Segment Toggle (Expense / Income / Transfer)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTypeSegment('Expense', TransactionType.expense),
                    ),
                    Expanded(
                      child: _buildTypeSegment('Income', TransactionType.income),
                    ),
                    Expanded(
                      child: _buildTypeSegment('Transfer', TransactionType.transfer),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Large Numeric Amount Input
              Column(
                children: [
                  const Text(
                    'AMOUNT',
                    style: TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.only(bottom: 6),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.accentPrimary,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '₱',
                          style: TextStyle(
                            fontFamily: 'Quicksand',
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IntrinsicWidth(
                          stepWidth: 10,
                          child: TextFormField(
                            controller: _amountController,
                            focusNode: _amountFocusNode,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              DecimalTextInputFormatter(decimalRange: 2),
                            ],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Quicksand',
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                fontFamily: 'Quicksand',
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Enter amount';
                              }
                              if (double.tryParse(val.trim()) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category Selector (Hidden for Transfers)
              if (_selectedType != TransactionType.transfer) ...[
                const Text(
                  'Category',
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                categoriesAsync.when(
                  data: (categories) {
                    final filteredCats = categories.where((c) {
                      if (_selectedType == TransactionType.expense) {
                        return c.type == CategoryType.expense || c.type == CategoryType.both;
                      } else {
                        return c.type == CategoryType.income || c.type == CategoryType.both;
                      }
                    }).toList();

                    final rawUniqueFilteredCats = <CategoryModel>[];
                    final seenCatIds = <String>{};
                    for (final c in filteredCats) {
                      if (seenCatIds.add(c.id)) {
                        rawUniqueFilteredCats.add(c);
                      }
                    }
                    final uniqueFilteredCats = DefaultCategories.sortCategoriesWithOtherLast(rawUniqueFilteredCats);

                    if (_selectedCategory != null && !uniqueFilteredCats.contains(_selectedCategory)) {
                      _selectedCategory = null;
                    }

                    // Auto-select first category or match editing tx
                    if (_selectedCategory == null && uniqueFilteredCats.isNotEmpty) {
                      if (isEditing && widget.transactionToEdit!.type == _selectedType) {
                        _selectedCategory = uniqueFilteredCats.firstWhere(
                          (c) => c.id == widget.transactionToEdit!.categoryId,
                          orElse: () => uniqueFilteredCats.first,
                        );
                      } else {
                        _selectedCategory = uniqueFilteredCats.first;
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderDefault),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CategoryModel>(
                          value: _selectedCategory,
                          isExpanded: true,
                          icon: const Icon(Icons.expand_more, color: AppColors.textMuted),
                          items: uniqueFilteredCats.map((cat) {
                            final color = DefaultCategories.getCategoryColorByName(cat.name, cat.colorHex);
                            return DropdownMenuItem<CategoryModel>(
                              value: cat,
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                       child: CategoryIcon(
                                         categoryName: cat.name,
                                         iconName: cat.iconName,
                                         color: color,
                                         size: 18,
                                         containerSize: 32,
                                         borderRadius: BorderRadius.circular(8),
                                       ),
                                     ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    cat.name,
                                    style: const TextStyle(
                                      fontFamily: 'Quicksand',
                                      fontSize: 15,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (cat) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                        ),
                      ),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (err, _) => Text('Error loading categories: $err'),
                ),
                const SizedBox(height: 16),
              ],

              // Account Pickers
              accountsAsync.when(
                data: (accounts) {
                  final uniqueAccounts = <AccountModel>[];
                  final seenAccIds = <String>{};
                  for (final a in accounts) {
                    if (seenAccIds.add(a.id)) {
                      uniqueAccounts.add(a);
                    }
                  }

                  if (_selectedAccount != null && !uniqueAccounts.contains(_selectedAccount)) {
                    _selectedAccount = null;
                  }
                  if (_selectedToAccount != null && !uniqueAccounts.contains(_selectedToAccount)) {
                    _selectedToAccount = null;
                  }

                  if (_selectedAccount == null && uniqueAccounts.isNotEmpty) {
                    if (isEditing) {
                      _selectedAccount = uniqueAccounts.firstWhere(
                        (a) => a.id == widget.transactionToEdit!.accountId,
                        orElse: () => uniqueAccounts.first,
                      );
                    } else {
                      _selectedAccount = uniqueAccounts.first;
                    }
                  }

                  if (_selectedType == TransactionType.transfer) {
                    if (_selectedToAccount == null && uniqueAccounts.length > 1) {
                      if (isEditing && widget.transactionToEdit!.toAccountId != null) {
                        _selectedToAccount = uniqueAccounts.firstWhere(
                          (a) => a.id == widget.transactionToEdit!.toAccountId,
                          orElse: () => uniqueAccounts.last,
                        );
                      } else {
                        _selectedToAccount = uniqueAccounts.firstWhere(
                          (a) => a.id != _selectedAccount?.id,
                          orElse: () => uniqueAccounts.last,
                        );
                      }
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedType == TransactionType.transfer
                                      ? 'From Account'
                                      : 'Account',
                                  style: const TextStyle(
                                    fontFamily: 'Quicksand',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _buildAccountDropdown(
                                  accounts: uniqueAccounts,
                                  selected: _selectedAccount,
                                  onChanged: (acc) => setState(() => _selectedAccount = acc),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedType == TransactionType.transfer) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'To Account',
                                    style: TextStyle(
                                      fontFamily: 'Quicksand',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildAccountDropdown(
                                    accounts: uniqueAccounts,
                                    selected: _selectedToAccount,
                                    onChanged: (acc) => setState(() => _selectedToAccount = acc),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text('Error loading accounts: $err'),
              ),
              const SizedBox(height: 16),

              // Date Picker
              const Text(
                'Date',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderDefault),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textMuted),
                          const SizedBox(width: 12),
                          Text(
                            dateFormatter.format(_selectedDate),
                            style: const TextStyle(
                              fontFamily: 'Quicksand',
                              fontSize: 15,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Note Textarea
              const Text(
                'Note (Optional)',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                style: const TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 15,
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'What was this for?',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.borderDefault),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Action Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          isEditing ? 'Save Transaction' : 'Record Transaction',
                          style: const TextStyle(
                            fontFamily: 'Quicksand',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildAccountDropdown({
    required List<AccountModel> accounts,
    required AccountModel? selected,
    required ValueChanged<AccountModel?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AccountModel>(
          value: selected,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: AppColors.textMuted),
          items: accounts.map((acc) {
            return DropdownMenuItem<AccountModel>(
              value: acc,
              child: Text(
                acc.name,
                style: const TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTypeSegment(String label, TransactionType type) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        if (_selectedType != type) {
          setState(() {
            _selectedType = type;
            _selectedCategory = null;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String rawError) {
    String headline = 'Transaction Error';
    String explanation = rawError;

    // Handle structured INSUFFICIENT_BALANCE error string: INSUFFICIENT_BALANCE|AccountName|Available|Attempted|Action
    if (rawError.contains("INSUFFICIENT_BALANCE") || rawError.toLowerCase().contains("insufficient balance")) {
      final parts = rawError.split('|');
      if (parts.length >= 5 && parts[0] == "INSUFFICIENT_BALANCE") {
        final accName = parts[1];
        final availableStr = parts[2];
        final attemptedStr = parts[3];
        final actionStr = parts[4]; // 'spend' or 'transfer'

        headline = "Not enough in $accName";
        explanation = "You're trying to $actionStr $attemptedStr, but this account only has $availableStr available.";
      } else {
        // Fallback for unstructured string like "Insufficient balance in Ae_Bank. Available: ₱0.00."
        final regex = RegExp(r'Insufficient balance in ([^.]+)\. Available: ([^.]+)\.', caseSensitive: false);
        final match = regex.firstMatch(rawError);
        if (match != null) {
          final accName = match.group(1) ?? 'this account';
          final availableStr = match.group(2) ?? '₱0.00';
          final amtVal = double.tryParse(_amountController.text) ?? 0.0;
          final attemptedStr = NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(amtVal);
          final actionStr = _selectedType == TransactionType.transfer ? 'transfer' : 'spend';

          headline = "Not enough in $accName";
          explanation = "You're trying to $actionStr $attemptedStr, but this account only has $availableStr available.";
        } else {
          headline = "Insufficient Balance";
          explanation = rawError;
        }
      }
    } else {
      // General error cleaning (strip out exception dumps if any remain)
      explanation = rawError
          .replaceAll(RegExp(r'^(Exception|TransactionException|Failed to add transaction|Failed to update transaction):\s*'), '')
          .replaceAll(RegExp(r'Error: Dart exception thrown.*'), '')
          .trim();
      if (explanation.isEmpty) {
        explanation = "An unexpected error occurred. Please try again.";
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stateError.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.stateError.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.stateError,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headline,
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  explanation,
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onErrorContainer.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAccountIconData(String? type) {
    switch (type?.toLowerCase()) {
      case 'gcash':
      case 'e-wallet':
        return Icons.phone_iphone_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'credit':
        return Icons.credit_card_rounded;
      case 'cash':
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  IconData _getCategoryIconData(String? iconName) {
    switch (iconName) {
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'directions_bus':
        return Icons.directions_bus_rounded;
      case 'movie':
        return Icons.movie_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'receipt':
        return Icons.receipt_long_rounded;
      default:
        return Icons.shopping_cart_rounded;
    }
  }
}

/// Custom TextInputFormatter allowing only numeric digits and at most 1 decimal point with up to decimalRange digits.
class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;
  DecimalTextInputFormatter({this.decimalRange = 2});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;
    if (newText.isEmpty) {
      return newValue;
    }
    final regex = RegExp('^\\d*\\.?\\d{0,$decimalRange}\$');
    if (regex.hasMatch(newText)) {
      return newValue;
    }
    return oldValue;
  }
}
