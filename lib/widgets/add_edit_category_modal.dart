import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../providers/category_provider.dart';
import '../utils/app_colors.dart';
import '../utils/default_categories.dart';

class AddEditCategoryModal extends ConsumerStatefulWidget {
  final CategoryModel? categoryToEdit;

  const AddEditCategoryModal({
    super.key,
    this.categoryToEdit,
  });

  static Future<void> show(BuildContext context, {CategoryModel? categoryToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditCategoryModal(categoryToEdit: categoryToEdit),
    );
  }

  @override
  ConsumerState<AddEditCategoryModal> createState() =>
      _AddEditCategoryModalState();
}

class _AddEditCategoryModalState extends ConsumerState<AddEditCategoryModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late CategoryType _selectedType;
  late String _selectedIconName;
  late String _selectedColorHex;

  @override
  void initState() {
    super.initState();
    final isEditing = widget.categoryToEdit != null;
    _nameController =
        TextEditingController(text: isEditing ? widget.categoryToEdit!.name : '');
    _selectedType = isEditing ? widget.categoryToEdit!.type : CategoryType.expense;
    _selectedIconName =
        isEditing ? widget.categoryToEdit!.iconName : 'restaurant';
    _selectedColorHex =
        isEditing ? widget.categoryToEdit!.colorHex : DefaultCategories.categoryColorChoices.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isEditing = widget.categoryToEdit != null;
    final controller = ref.read(categoryControllerProvider.notifier);

    bool success;
    if (isEditing) {
      final updated = widget.categoryToEdit!.copyWith(
        name: _nameController.text.trim(),
        iconName: _selectedIconName,
        colorHex: _selectedColorHex,
        type: _selectedType,
      );
      success = await controller.updateCategory(updated);
    } else {
      success = await controller.addCategory(
        name: _nameController.text.trim(),
        iconName: _selectedIconName,
        colorHex: _selectedColorHex,
        type: _selectedType,
      );
    }

    if (mounted && success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.categoryToEdit != null;
    final state = ref.watch(categoryControllerProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                    isEditing ? 'Edit Category' : 'Add Category',
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

              // Category Name Input
              TextFormField(
                controller: _nameController,
                style: const TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 16,
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. Groceries, Gym, Coffee',
                  prefixIcon: Icon(
                    DefaultCategories.getIcon(_selectedIconName),
                    color: DefaultCategories.getColor(_selectedColorHex),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.borderDefault),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category Type Selector (Expense vs Income)
              const Text(
                'Type',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTypeSegment(
                        label: 'Expense',
                        type: CategoryType.expense,
                      ),
                    ),
                    Expanded(
                      child: _buildTypeSegment(
                        label: 'Income',
                        type: CategoryType.income,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Color Chip Picker
              const Text(
                'Color Tag',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: DefaultCategories.categoryColorChoices.map((hex) {
                  final isSelected = _selectedColorHex.toUpperCase() == hex.toUpperCase();
                  final color = DefaultCategories.getColor(hex);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColorHex = hex;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: AppColors.onSurface, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Icon Grid Picker
              const Text(
                'Select Icon',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 130,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: DefaultCategories.availableIcons.length,
                  itemBuilder: (context, index) {
                    final key = DefaultCategories.availableIcons.keys.elementAt(index);
                    final iconData = DefaultCategories.availableIcons[key]!;
                    final isSelected = _selectedIconName == key;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIconName = key;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          iconData,
                          size: 22,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Submit Action Button
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
                    elevation: 2,
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isEditing ? 'Save Changes' : 'Create Category',
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

  Widget _buildTypeSegment({
    required String label,
    required CategoryType type,
  }) {
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
