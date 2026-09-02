import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/recurring_bill_model.dart';
import '../providers/account_provider.dart';
import '../providers/category_provider.dart';
import '../providers/recurring_bill_provider.dart';
import '../utils/app_colors.dart';
import '../utils/default_categories.dart';

/// Modal bottom sheet for adding or editing a recurring bill.
class AddEditRecurringBillModal extends ConsumerStatefulWidget {
  final RecurringBillModel? billToEdit;

  const AddEditRecurringBillModal({super.key, this.billToEdit});

  static Future<void> show(BuildContext context, {RecurringBillModel? billToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditRecurringBillModal(billToEdit: billToEdit),
    );
  }

  @override
  ConsumerState<AddEditRecurringBillModal> createState() => _AddEditRecurringBillModalState();
}

class _AddEditRecurringBillModalState extends ConsumerState<AddEditRecurringBillModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;

  late BillFrequency _selectedFrequency;
  late DateTime _selectedDueDate;
  late int _selectedReminderDays;

  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;

  final List<(int, String)> _reminderOptions = const [
    (0, 'On due date (9:00 AM)'),
    (1, '1 day before'),
    (3, '3 days before'),
    (7, '7 days before'),
    (-1, 'Disabled / No Reminder'),
  ];

  @override
  void initState() {
    super.initState();
    final bill = widget.billToEdit;
    final isEdit = bill != null;

    _nameController = TextEditingController(text: bill?.name ?? '');
    _amountController = TextEditingController(
      text: isEdit ? bill.amount.toStringAsFixed(2) : '',
    );

    _selectedFrequency = bill?.frequency ?? BillFrequency.monthly;
    _selectedDueDate = bill?.nextDueDate ?? DateTime.now().add(const Duration(days: 7));
    _selectedReminderDays = bill != null ? (bill.isReminderEnabled ? bill.reminderDaysBefore : -1) : 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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
        _selectedDueDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDueDate.hour,
          _selectedDueDate.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a stash account'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final isEdit = widget.billToEdit != null;
    final amountVal = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final reminderDays = _selectedReminderDays >= 0 ? _selectedReminderDays : 1;
    final reminderEnabled = _selectedReminderDays >= 0;

    final newBill = RecurringBillModel(
      id: isEdit ? widget.billToEdit!.id : '',
      name: _nameController.text.trim(),
      amount: amountVal,
      frequency: _selectedFrequency,
      nextDueDate: _selectedDueDate,
      categoryId: _selectedCategory!.id,
      categoryName: _selectedCategory!.name,
      categoryIcon: _selectedCategory!.iconName,
      categoryColorHex: _selectedCategory!.colorHex,
      accountId: _selectedAccount!.id,
      accountName: _selectedAccount!.name,
      reminderDaysBefore: reminderDays,
      isReminderEnabled: reminderEnabled,
      createdAt: widget.billToEdit?.createdAt ?? DateTime.now(),
    );

    final notifier = ref.read(recurringBillControllerProvider.notifier);
    final success = isEdit
        ? await notifier.updateBill(newBill)
        : await notifier.addBill(newBill);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Bill updated' : 'Recurring bill saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.billToEdit != null;
    final state = ref.watch(recurringBillControllerProvider);

    final categories = ref.watch(expenseCategoriesProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);

    final uniqueCategories = <CategoryModel>[];
    final seenCatIds = <String>{};
    for (final c in categories) {
      if (seenCatIds.add(c.id)) {
        uniqueCategories.add(c);
      }
    }

    if (_selectedCategory != null && !uniqueCategories.contains(_selectedCategory)) {
      _selectedCategory = null;
    }

    if (_selectedCategory == null && uniqueCategories.isNotEmpty) {
      if (isEdit) {
        _selectedCategory = uniqueCategories.firstWhere(
          (c) => c.id == widget.billToEdit!.categoryId,
          orElse: () => uniqueCategories.first,
        );
      } else {
        _selectedCategory = uniqueCategories.firstWhere(
          (c) => c.name.contains('Bills'),
          orElse: () => uniqueCategories.first,
        );
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Recurring Bill' : 'New Recurring Bill',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bill Name
              const Text('Bill Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'e.g. Netflix, Wifi Internet, Electricity'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a bill name' : null,
              ),
              const SizedBox(height: 16),

              // Amount
              const Text('Amount (₱)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(hintText: '0.00'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter an amount';
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) return 'Please enter a valid amount greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Selector
              const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<CategoryModel>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                items: uniqueCategories.map((cat) {
                  final icon = DefaultCategories.getIcon(cat.iconName);
                  final color = DefaultCategories.getColor(cat.colorHex);
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(icon, size: 18, color: color),
                        const SizedBox(width: 10),
                        Text(cat.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (val) => val == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),

              // Account Selector
              const Text('Linked Stash Account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
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

                  if (_selectedAccount == null && uniqueAccounts.isNotEmpty) {
                    if (isEdit) {
                      _selectedAccount = uniqueAccounts.firstWhere(
                        (a) => a.id == widget.billToEdit!.accountId,
                        orElse: () => uniqueAccounts.first,
                      );
                    } else {
                      _selectedAccount = uniqueAccounts.first;
                    }
                  }

                  return DropdownButtonFormField<AccountModel>(
                    initialValue: _selectedAccount,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                    items: uniqueAccounts.map((acc) {
                      return DropdownMenuItem(
                        value: acc,
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_rounded, size: 18, color: AppColors.accentPrimary),
                            const SizedBox(width: 10),
                            Text('${acc.name} (₱${acc.balance.toStringAsFixed(2)})'),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedAccount = val),
                    validator: (val) => val == null ? 'Please select an account' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text('Error loading accounts: $err', style: const TextStyle(color: AppColors.stateError)),
              ),
              const SizedBox(height: 16),

              // Frequency Chips
              const Text('Payment Frequency', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: BillFrequency.values.map((freq) {
                  final isSelected = _selectedFrequency == freq;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Center(
                          child: Text(
                            freq.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.accentPrimary,
                        backgroundColor: AppColors.bgBase,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedFrequency = freq);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Next Due Date Tile
              const Text('Next Due Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _selectDueDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.bgBase,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.accentPrimary),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(_selectedDueDate),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reminder Days Dropdown
              const Text('Reminder Alert', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                initialValue: _selectedReminderDays,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                items: _reminderOptions.map((opt) {
                  return DropdownMenuItem(
                    value: opt.$1,
                    child: Text(opt.$2),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedReminderDays = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _save,
                  child: state.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(isEdit ? 'Update Bill' : 'Save Recurring Bill'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
