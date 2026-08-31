import 'package:flutter/material.dart';
import '../models/category_model.dart';

/// Pre-seeded default financial categories for all new users.
class DefaultCategories {
  DefaultCategories._();

  static const List<CategoryModel> defaultList = [
    CategoryModel(
      id: 'food_dining',
      name: 'Food & Dining',
      iconName: 'restaurant',
      colorHex: '#D9553A',
      type: CategoryType.expense,
      isDefault: true,
    ),
    CategoryModel(
      id: 'shopping',
      name: 'Shopping',
      iconName: 'shopping_bag',
      colorHex: '#D94A6E',
      type: CategoryType.expense,
      isDefault: true,
    ),
    CategoryModel(
      id: 'bills_utilities',
      name: 'Bills & Utilities',
      iconName: 'receipt_long',
      colorHex: '#D9884A',
      type: CategoryType.expense,
      isDefault: true,
    ),
    CategoryModel(
      id: 'transportation',
      name: 'Transportation',
      iconName: 'directions_bus',
      colorHex: '#4A8CD9',
      type: CategoryType.expense,
      isDefault: true,
    ),
    CategoryModel(
      id: 'entertainment',
      name: 'Entertainment',
      iconName: 'movie',
      colorHex: '#8B6BB8',
      type: CategoryType.expense,
      isDefault: true,
    ),
    CategoryModel(
      id: 'health',
      name: 'Health',
      iconName: 'medical_services',
      colorHex: '#D9A63D',
      type: CategoryType.expense,
      isDefault: true,
    ),
    CategoryModel(
      id: 'salary',
      name: 'Salary',
      iconName: 'payments',
      colorHex: '#4E8C6E',
      type: CategoryType.income,
      isDefault: true,
    ),
    CategoryModel(
      id: 'investment',
      name: 'Investment',
      iconName: 'trending_up',
      colorHex: '#4AD98F',
      type: CategoryType.income,
      isDefault: true,
    ),
  ];

  /// Category colors table from ui-context.md (Confirmed Figma Export).
  static const Map<String, String> categoryColorsTable = {
    'Food & Dining': '#EE4818',
    'Bills & Utilities': '#F48423',
    'Transportation': '#E08B03',
    'Shopping': '#D94A6E',
    'Entertainment': '#8B6BB8',
    'Health': '#D9A63D',
    'Housing': '#A8664A',
    'Education': '#6B8A9E',
    'Other': '#8A7F73',
    'Salary': '#4E8C6E',
    'Investment': '#4AD98F',
    'Other Income': '#6FAE8C',
  };

  /// Curated color choices matching brand tokens for category chips.
  static const List<String> categoryColorChoices = [
    '#D9553A', // Food & Dining
    '#D9884A', // Bills & Utilities
    '#4A8CD9', // Transportation
    '#D94A6E', // Shopping
    '#8B6BB8', // Entertainment
    '#D9A63D', // Health
    '#4E8C6E', // Salary
    '#4AD98F', // Investment
    '#A8664A', // Housing
    '#6B8A9E', // Education
    '#8A7F73', // Other
  ];

  /// Selectable icon choices for user-defined custom categories.
  static const Map<String, IconData> availableIcons = {
    'restaurant': Icons.restaurant_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'directions_bus': Icons.directions_bus_rounded,
    'movie': Icons.movie_rounded,
    'medical_services': Icons.medical_services_rounded,
    'payments': Icons.payments_rounded,
    'trending_up': Icons.trending_up_rounded,
    'home': Icons.home_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'pets': Icons.pets_rounded,
    'school': Icons.school_rounded,
    'flight': Icons.flight_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'work': Icons.work_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'savings': Icons.savings_rounded,
  };

  /// Safely resolves a category icon by name, falling back to a default folder icon.
  static IconData getIcon(String iconName) {
    return availableIcons[iconName] ?? Icons.category_rounded;
  }

  /// Resolves category color by category name matching ui-context.md table, or falls back to hex string.
  static Color getCategoryColorByName(String categoryName, [String? fallbackHex]) {
    final tableHex = categoryColorsTable[categoryName];
    if (tableHex != null) {
      return getColor(tableHex);
    }
    if (fallbackHex != null && fallbackHex.isNotEmpty) {
      return getColor(fallbackHex);
    }
    return getColor('#8A7F73');
  }

  /// Converts hex color string (#RRGGBB) to Flutter Color instance.
  static Color getColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
