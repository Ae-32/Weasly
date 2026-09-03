import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../utils/default_categories.dart';
import 'auth_provider.dart';

/// Provider exposing the CategoryService instance.
final categoryServiceProvider = Provider<CategoryService>((ref) {
  return CategoryService();
});

/// Real-time stream of categories for the current logged-in user.
/// Automatically triggers default category seeding if the user has no categories yet.
final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.uid ?? '';

  if (userId.isEmpty) {
    return Stream.value([]);
  }

  final service = ref.watch(categoryServiceProvider);
  // Auto-seed default categories if empty
  service.seedDefaultCategoriesIfEmpty(userId);

  return service.getCategoriesStream(userId).map((list) {
    return DefaultCategories.sortCategoriesWithOtherLast(list);
  });
});

/// Filtered provider containing categories available for Expense transactions.
final expenseCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final categoriesAsync = ref.watch(categoriesStreamProvider);
  return categoriesAsync.when(
    data: (categories) => DefaultCategories.sortCategoriesWithOtherLast(
      categories
          .where((c) => c.type == CategoryType.expense || c.type == CategoryType.both)
          .toList(),
    ),
    loading: () => [],
    error: (err, stack) => [],
  );
});

/// Filtered provider containing categories available for Income transactions.
final incomeCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final categoriesAsync = ref.watch(categoriesStreamProvider);
  return categoriesAsync.when(
    data: (categories) => DefaultCategories.sortCategoriesWithOtherLast(
      categories
          .where((c) => c.type == CategoryType.income || c.type == CategoryType.both)
          .toList(),
    ),
    loading: () => [],
    error: (err, stack) => [],
  );
});

/// Controller state class for Category mutations.
class CategoryControllerState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const CategoryControllerState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  CategoryControllerState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return CategoryControllerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

/// Controller provider managing Add, Update, and Delete actions on categories.
class CategoryController extends StateNotifier<CategoryControllerState> {
  final CategoryService _service;
  final Ref _ref;

  CategoryController(this._service, this._ref)
      : super(const CategoryControllerState());

  String _getUserId() {
    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      throw const CategoryException("User is not authenticated.");
    }
    return user.uid;
  }

  /// Adds a new custom category.
  Future<bool> addCategory({
    required String name,
    required String iconName,
    required String colorHex,
    required CategoryType type,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final userId = _getUserId();
      await _service.addCategory(
        userId: userId,
        name: name,
        iconName: iconName,
        colorHex: colorHex,
        type: type,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: "Category added successfully!",
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Updates an existing category.
  Future<bool> updateCategory(CategoryModel category) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final userId = _getUserId();
      await _service.updateCategory(
        userId: userId,
        category: category,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: "Category updated successfully!",
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Deletes a custom category. Default categories will be blocked with an error.
  Future<bool> deleteCategory(CategoryModel category) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final userId = _getUserId();
      await _service.deleteCategory(
        userId: userId,
        category: category,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: "Category deleted successfully!",
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final categoryControllerProvider =
    StateNotifierProvider<CategoryController, CategoryControllerState>((ref) {
  final service = ref.watch(categoryServiceProvider);
  return CategoryController(service, ref);
});
