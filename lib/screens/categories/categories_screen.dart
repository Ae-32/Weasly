import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/default_categories.dart';
import '../../widgets/add_edit_category_modal.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/success_banner.dart';
import '../../widgets/app_toast.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext parentContext, CategoryModel category) {
    if (category.isDefault) {
      AppToast.showWarning(
        parentContext,
        'Default categories cannot be deleted to protect your transaction history.',
      );
      return;
    }

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Category',
          style: TextStyle(fontFamily: 'Quicksand', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"? This action cannot be undone.',
          style: const TextStyle(fontFamily: 'Quicksand'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await ref
                  .read(categoryControllerProvider.notifier)
                  .deleteCategory(category);
              if (parentContext.mounted) {
                if (success) {
                  SuccessBanner.show(parentContext, 'Category deleted!');
                } else {
                  final err = ref.read(categoryControllerProvider).errorMessage;
                  if (err != null) {
                    AppToast.showError(parentContext, err);
                  }
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Categories',
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentPrimary,
          labelColor: AppColors.accentPrimary,
          unselectedLabelColor: colors.textMuted,
          labelStyle: const TextStyle(
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddEditCategoryModal.show(context),
        backgroundColor: AppColors.accentPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Category',
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final expenseList = DefaultCategories.sortCategoriesWithOtherLast(
            categories
                .where((c) => c.type == CategoryType.expense || c.type == CategoryType.both)
                .toList(),
          );
          final incomeList = DefaultCategories.sortCategoriesWithOtherLast(
            categories
                .where((c) => c.type == CategoryType.income || c.type == CategoryType.both)
                .toList(),
          );

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(expenseList, 'No expense categories found.', colors),
              _buildCategoryList(incomeList, 'No income categories found.', colors),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentPrimary),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Failed to load categories: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Quicksand', color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(
    List<CategoryModel> categories,
    String emptyMessage,
    AppColorsExtension colors,
  ) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: colors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 16,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final color = DefaultCategories.getColor(category.colorHex);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: colors.bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.borderDefault),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Category Icon Badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: CategoryIcon(
                      categoryName: category.name,
                      iconName: category.iconName,
                      color: color,
                      size: 24,
                      containerSize: 48,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name and Badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              category.name,
                              style: TextStyle(
                                fontFamily: 'Quicksand',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          if (category.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.iconButtonBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Preset',
                                style: TextStyle(
                                  fontFamily: 'Quicksand',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Edit Action Button
                IconButton(
                  onPressed: () => AddEditCategoryModal.show(
                    context,
                    categoryToEdit: category,
                  ),
                  icon: Icon(Icons.edit_outlined, color: colors.textMuted, size: 20),
                  tooltip: 'Edit Category',
                ),

                // Delete Action Button (Disabled for default categories)
                IconButton(
                  onPressed: category.isDefault
                      ? null
                      : () => _confirmDelete(context, category),
                  icon: Icon(
                    Icons.delete_outline,
                    color: category.isDefault
                        ? colors.borderDefault
                        : AppColors.error,
                    size: 20,
                  ),
                  tooltip: category.isDefault
                      ? 'Default category (Protected)'
                      : 'Delete Category',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
