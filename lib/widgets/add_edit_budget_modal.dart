import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';
import '../utils/app_colors.dart';
import '../utils/default_categories.dart';

class AddEditBudgetModal extends ConsumerStatefulWidget {
  final BudgetModel? budgetToEdit;

  const AddEditBudgetModal({
    super.key,
    this.budgetToEdit,
  });

  static Future<void> show(BuildContext context, {BudgetModel? budgetToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditBudgetModal(budgetToEdit: budgetToEdit),
    );
  }

  @override
  ConsumerState<AddEditBudgetModal> createState() => _AddEditBudgetModalState();
}

class _AddEditBudgetModalState extends ConsumerState<AddEditBudgetModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late BudgetPeriodType _selectedPeriod;
  late DateTime _startDate;
  DateTime? _endDate;

  CategoryModel? _selectedCategory;
  bool _isAlertEnabled = true;

  @override
  void initState() {
    super.initState();
    final budget = widget.budgetToEdit;
    final isEditing = budget != null;

    _amountController = TextEditingController(
      text: isEditing ? budget.amount.toStringAsFixed(2) : '',
    );
    _selectedPeriod = isEditing ? budget.periodType : BudgetPeriodType.monthly;
    _startDate = isEditing ? budget.startDate : DateTime.now();
    _endDate = isEditing ? budget.endDate : DateTime.now().add(const Duration(days: 30));
    _isAlertEnabled = isEditing ? budget.isAlertEnabled : true;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate ?? _startDate.add(const Duration(days: 7)),
      ),
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

    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category for the budget.', style: TextStyle(fontFamily: 'Quicksand')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final amountVal = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amountVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a budget amount greater than zero.', style: TextStyle(fontFamily: 'Quicksand')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedPeriod == BudgetPeriodType.custom && _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an end date for the custom period.', style: TextStyle(fontFamily: 'Quicksand')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final isEditing = widget.budgetToEdit != null;
    final controller = ref.read(budgetControllerProvider.notifier);

    final model = BudgetModel(
      id: isEditing ? widget.budgetToEdit!.id : '',
      categoryId: _selectedCategory!.id,
      categoryName: _selectedCategory!.name,
      categoryIcon: _selectedCategory!.iconName,
      categoryColorHex: _selectedCategory!.colorHex,
      amount: amountVal,
      periodType: _selectedPeriod,
      startDate: _startDate,
      endDate: _selectedPeriod == BudgetPeriodType.custom ? _endDate : null,
      createdAt: widget.budgetToEdit?.createdAt ?? DateTime.now(),
      isAlertEnabled: _isAlertEnabled,
      alertThreshold: widget.budgetToEdit?.alertThreshold ?? 80.0,
    );

    final success = isEditing
        ? await controller.updateBudget(model)
        : await controller.addBudget(model);

    if (mounted && success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.budgetToEdit != null;
    final state = ref.watch(budgetControllerProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
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
                    isEditing ? 'Edit Budget' : 'Set Budget',
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

              // Category Selector
              const Text(
                'CATEGORY',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              categoriesAsync.when(
                data: (categories) {
                  final expenseCategories = categories
                      .where((c) => c.type == CategoryType.expense || c.type == CategoryType.both)
                      .toList();

                  if (_selectedCategory == null && expenseCategories.isNotEmpty) {
                    if (isEditing) {
                      _selectedCategory = expenseCategories.firstWhere(
                        (c) => c.id == widget.budgetToEdit!.categoryId,
                        orElse: () => expenseCategories.first,
                      );
                    } else {
                      _selectedCategory = expenseCategories.first;
                    }
                  }

                  return Column(
                    children: [
                      Container(
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
                            items: expenseCategories.map((cat) {
                              final color = DefaultCategories.getColor(cat.colorHex);
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
                      ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text('Error loading categories: $err'),
              ),
              const SizedBox(height: 20),

              // Budget Amount Input
              const Text(
                'AMOUNT TARGET',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  prefixText: '₱ ',
                  prefixStyle: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.borderDefault),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter budget amount';
                  if (double.tryParse(val.trim()) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Period Radio Selection Cards
              const Text(
                'PERIOD',
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
                children: [
                  Expanded(
                    child: _buildPeriodCard(
                      label: 'Weekly',
                      icon: Icons.calendar_view_week_rounded,
                      type: BudgetPeriodType.weekly,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPeriodCard(
                      label: 'Monthly',
                      icon: Icons.calendar_month_rounded,
                      type: BudgetPeriodType.monthly,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPeriodCard(
                      label: 'Custom',
                      icon: Icons.date_range_rounded,
                      type: BudgetPeriodType.custom,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Custom Date Range Picker Field
              if (_selectedPeriod == BudgetPeriodType.custom) ...[
                GestureDetector(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderDefault),
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.date_range_rounded, size: 20, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Text(
                              '${dateFormatter.format(_startDate)} - ${dateFormatter.format(_endDate ?? _startDate)}',
                              style: const TextStyle(
                                fontFamily: 'Quicksand',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
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
              ],

              // Alert me when 80% is reached toggle
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderDefault),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  value: _isAlertEnabled,
                  onChanged: (val) {
                    setState(() {
                      _isAlertEnabled = val;
                    });
                  },
                  activeThumbColor: AppColors.accentPrimary,
                  title: const Text(
                    'Alert me when 80% is reached',
                    style: TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  subtitle: const Text(
                    'Receive a notification when spending reaches 80%',
                    style: TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
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
                          isEditing ? 'Update Budget' : 'Set Budget',
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

  Widget _buildPeriodCard({
    required String label,
    required IconData icon,
    required BudgetPeriodType type,
  }) {
    final isSelected = _selectedPeriod == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderDefault,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
