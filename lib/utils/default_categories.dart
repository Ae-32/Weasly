import 'package:flutter/material.dart';
import '../models/category_model.dart';

/// Pre-seeded default financial categories for all new users.
class DefaultCategories {
  DefaultCategories._();

  static const List<CategoryModel> defaultList = [
    CategoryModel(
      id: 'food_dining',
      name: 'Foods & Drinks',
      iconName: 'restaurant',
      colorHex: '#FB7140',
      type: CategoryType.expense,
      isDefault: true,
    ),
    CategoryModel(
      id: 'shopping',
      name: 'Shopping',
      iconName: 'shopping_bag',
      colorHex: '#05A789',
      type: CategoryType.expense,
      isDefault: true,
    ),
    CategoryModel(
      id: 'bills_utilities',
      name: 'Bills & Utilities',
      iconName: 'receipt_long',
      colorHex: '#F7C500',
      type: CategoryType.expense,
      isDefault: true,
    ),
    CategoryModel(
      id: 'transportation',
      name: 'Transportation',
      iconName: 'directions_bus',
      colorHex: '#009AC6',
      type: CategoryType.expense,
      isDefault: true,
    ),
    CategoryModel(
      id: 'entertainment',
      name: 'Entertainment',
      iconName: 'movie',
      colorHex: '#623A97',
      type: CategoryType.expense,
      isDefault: true,
    ),
    CategoryModel(
      id: 'health',
      name: 'Health',
      iconName: 'medical_services',
      colorHex: '#C20429',
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
      id: 'business_freelance',
      name: 'Business/Freelance',
      iconName: 'work',
      colorHex: '#00838F',
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
    CategoryModel(
      id: 'allowance_gifts',
      name: 'Allowance/Gifts',
      iconName: 'card_giftcard',
      colorHex: '#26A69A',
      type: CategoryType.income,
      isDefault: true,
    ),
    CategoryModel(
      id: 'other_income',
      name: 'Other Income',
      iconName: 'savings',
      colorHex: '#6FAE8C',
      type: CategoryType.income,
      isDefault: true,
    ),
  ];

  /// Category colors table matched directly to dominant custom icon colors.
  static const Map<String, String> categoryColorsTable = {
    'Foods & Drinks': '#FB7140',
    'Food & Dining': '#FB7140',
    'Bills & Utilities': '#F7C500',
    'Transportation': '#009AC6',
    'Shopping': '#05A789',
    'Entertainment': '#623A97',
    'Health': '#C20429',
    'Other': '#808080',
    'Housing': '#2B506E',
    'Education': '#7C4DFF',
    'Salary': '#4E8C6E',
    'Business/Freelance': '#00838F',
    'Investment': '#4AD98F',
    'Allowance/Gifts': '#26A69A',
    'Other Income': '#6FAE8C',
  };

  /// Curated color choices matching brand tokens for category chips.
  static const List<String> categoryColorChoices = [
    '#FB7140', // Foods & Drinks
    '#F7C500', // Bills & Utilities
    '#009AC6', // Transportation
    '#05A789', // Shopping
    '#623A97', // Entertainment
    '#C20429', // Health
    '#808080', // Other
    '#2B506E', // Housing
    '#7C4DFF', // Education
    '#4E8C6E', // Salary
    '#00838F', // Business/Freelance
    '#4AD98F', // Investment
    '#26A69A', // Allowance/Gifts
    '#6FAE8C', // Other Income
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

  /// Maps custom category icon PNGs in assets/Weasly_Icons/ based on category name or iconName.
  /// Returns null for categories without custom icons (Housing, Education, Salary, Investment, etc.).
  static String? getCustomIconAsset(String categoryName, [String? iconName]) {
    final nameClean = categoryName.trim().toLowerCase();
    final iconClean = (iconName ?? '').trim().toLowerCase();

    if (nameClean.contains('bill') ||
        nameClean.contains('utility') ||
        iconClean == 'receipt_long') {
      return 'assets/Weasly_Icons/Icon_Bills_Utilities.png';
    }
    if (nameClean.contains('entertainment') ||
        nameClean.contains('movie') ||
        iconClean == 'movie') {
      return 'assets/Weasly_Icons/Icon_Entertainment.png';
    }
    if (nameClean.contains('food') ||
        nameClean.contains('drink') ||
        nameClean.contains('dining') ||
        iconClean == 'restaurant') {
      return 'assets/Weasly_Icons/Icon_Foods_Drinks.png';
    }
    if (nameClean.contains('health') ||
        nameClean.contains('medical') ||
        iconClean == 'medical_services') {
      return 'assets/Weasly_Icons/Icon_Health.png';
    }
    if (nameClean.contains('shop') || iconClean == 'shopping_bag') {
      return 'assets/Weasly_Icons/Icon_Shopping.png';
    }
    if (nameClean.contains('transport') ||
        RegExp(r'\bbus\b').hasMatch(nameClean) ||
        iconClean == 'directions_bus') {
      return 'assets/Weasly_Icons/Icon_Transportation.png';
    }
    if (nameClean == 'other' || iconClean == 'category') {
      return 'assets/Weasly_Icons/Icon_Other.png';
    }

    return null;
  }


  /// Sanitizes legacy category names (e.g., 'Food & Dining' -> 'Foods & Drinks').
  static String sanitizeCategoryName(String name) {
    if (name.trim().toLowerCase() == 'food & dining') {
      return 'Foods & Drinks';
    }
    return name;
  }

  /// Resolves category color by category name matching ui-context.md table, or falls back to hex string.
  static Color getCategoryColorByName(String categoryName, [String? fallbackHex]) {
    final sanitized = sanitizeCategoryName(categoryName);
    final tableHex = categoryColorsTable[sanitized];
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

  /// Sorts a list of CategoryModel by name while guaranteeing 'Other' and 'Other Income' are ALWAYS placed at the very end.
  static List<CategoryModel> sortCategoriesWithOtherLast(List<CategoryModel> categories) {
    final list = List<CategoryModel>.from(categories);
    list.sort((a, b) {
      final aIsOther = _isOtherCategory(a.name);
      final bIsOther = _isOtherCategory(b.name);

      if (aIsOther && !bIsOther) return 1;  // a goes after b (towards end)
      if (!aIsOther && bIsOther) return -1; // a goes before b
      return a.name.compareTo(b.name);
    });
    return list;
  }

  static bool _isOtherCategory(String name) {
    final lower = name.trim().toLowerCase();
    return lower == 'other' || lower == 'other income' || lower == 'other expense' || lower.startsWith('other');
  }
}
