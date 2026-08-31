import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/account_provider.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/app_colors.dart';
import '../utils/default_categories.dart';

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

    if (mounted && success) {
      Navigator.of(context).pop();
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

              if (state.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(
                      color: AppColors.onErrorContainer,
                      fontSize: 13,
                      fontFamily: 'Quicksand',
                    ),
                  ),
                ),
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '₱',
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IntrinsicWidth(
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Quicksand',
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0.00',
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

                    // Auto-select first category or match editing tx
                    if (_selectedCategory == null && filteredCats.isNotEmpty) {
                      if (isEditing) {
                        _selectedCategory = filteredCats.firstWhere(
                          (c) => c.id == widget.transactionToEdit!.categoryId,
                          orElse: () => filteredCats.first,
                        );
                      } else {
                        _selectedCategory = filteredCats.first;
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
                          items: filteredCats.map((cat) {
                            final color = DefaultCategories.getCategoryColorByName(cat.name, cat.colorHex);
                            final icon = DefaultCategories.getIcon(cat.iconName);
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
                                    child: Icon(icon, size: 18, color: color),
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
                  if (_selectedAccount == null && accounts.isNotEmpty) {
                    if (isEditing) {
                      _selectedAccount = accounts.firstWhere(
                        (a) => a.id == widget.transactionToEdit!.accountId,
                        orElse: () => accounts.first,
                      );
                    } else {
                      _selectedAccount = accounts.first;
                    }
                  }

                  if (_selectedType == TransactionType.transfer) {
                    if (_selectedToAccount == null && accounts.length > 1) {
                      if (isEditing && widget.transactionToEdit!.toAccountId != null) {
                        _selectedToAccount = accounts.firstWhere(
                          (a) => a.id == widget.transactionToEdit!.toAccountId,
                          orElse: () => accounts.last,
                        );
                      } else {
                        _selectedToAccount = accounts.firstWhere(
                          (a) => a.id != _selectedAccount?.id,
                          orElse: () => accounts.last,
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
                                  accounts: accounts,
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
                                    accounts: accounts,
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
        setState(() {
          _selectedType = type;
        });
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
}
