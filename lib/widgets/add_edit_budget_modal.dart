import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';
import '../utils/app_colors.dart';
import '../utils/default_categories.dart';
import 'category_icon.dart';
import 'success_banner.dart';
import 'app_toast.dart';

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
      AppToast.showWarning(context, 'Please select a category for the budget.');
      return;
    }

    final amountVal = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amountVal <= 0) {
      AppToast.showWarning(context, 'Please enter a budget amount greater than zero.');
      return;
    }

    if (_selectedPeriod == BudgetPeriodType.custom && _endDate == null) {
      AppToast.showWarning(context, 'Please select an end date for the custom period.');
      return;
    }

    final isEditing = widget.budgetToEdit != null;
    final existingBudgets = ref.read(budgetsStreamProvider).value ?? [];
    if (BudgetModel.isDuplicateCategory(
      _selectedCategory!.id,
      _selectedCategory!.name,
      existingBudgets,
      excludeBudgetId: isEditing ? widget.budgetToEdit!.id : null,
    )) {
      AppToast.showError(
        context,
        'A budget for "${_selectedCategory!.name}" already exists. Please edit the existing budget instead.',
      );
      return;
    }

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
      SuccessBanner.show(
        context,
        isEditing ? 'Budget updated!' : 'Budget set!',
      );
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

                  final rawUniqueExpenseCategories = <CategoryModel>[];
                  final seenCatIds = <String>{};
                  for (final c in expenseCategories) {
                    if (seenCatIds.add(c.id)) {
                      rawUniqueExpenseCategories.add(c);
                    }
                  }
                  final uniqueExpenseCategories = DefaultCategories.sortCategoriesWithOtherLast(rawUniqueExpenseCategories);

                  if (_selectedCategory != null && !uniqueExpenseCategories.contains(_selectedCategory)) {
                    _selectedCategory = null;
                  }

                  if (_selectedCategory == null && uniqueExpenseCategories.isNotEmpty) {
                    if (isEditing) {
                      _selectedCategory = uniqueExpenseCategories.firstWhere(
                        (c) => c.id == widget.budgetToEdit!.categoryId,
                        orElse: () => uniqueExpenseCategories.first,
                      );
                    } else {
                      _selectedCategory = uniqueExpenseCategories.first;
                    }
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return PopupMenuButton<CategoryModel>(
                        position: PopupMenuPosition.under,
                        color: AppColors.bgSurface,
                        elevation: 4,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.borderDefault),
                        ),
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                          maxWidth: constraints.maxWidth,
                          maxHeight: 280,
                        ),
                        itemBuilder: (context) {
                          return uniqueExpenseCategories.map((cat) {
                            final color = DefaultCategories.getColor(cat.colorHex);
                            final isSelected = cat.id == _selectedCategory?.id;
                            return PopupMenuItem<CategoryModel>(
                              value: cat,
                              height: 48,
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
                                  Expanded(
                                    child: Text(
                                      cat.name,
                                      style: TextStyle(
                                        fontFamily: 'Quicksand',
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? AppColors.primary : AppColors.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
                                ],
                              ),
                            );
                          }).toList();
                        },
                        onSelected: (cat) {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderDefault),
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.bgSurface,
                          ),
                          child: Row(
                            children: [
                              if (_selectedCategory != null) ...[
                                Builder(
                                  builder: (context) {
                                    final color = DefaultCategories.getColor(_selectedCategory!.colorHex);
                                    return Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: CategoryIcon(
                                          categoryName: _selectedCategory!.name,
                                          iconName: _selectedCategory!.iconName,
                                          color: color,
                                          size: 18,
                                          containerSize: 32,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedCategory!.name,
                                    style: const TextStyle(
                                      fontFamily: 'Quicksand',
                                      fontSize: 15,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const Expanded(
                                  child: Text(
                                    'Select category',
                                    style: TextStyle(
                                      fontFamily: 'Quicksand',
                                      fontSize: 15,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                              const Icon(Icons.expand_more, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      );
                    },
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
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                style: const TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 16, right: 6),
                    child: Text(
                      '₱',
                      style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
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
