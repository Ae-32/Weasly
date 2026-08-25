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
      colorHex: '#8E4E00',
      type: CategoryType.expense,
      isDefault: true,
    ),
    CategoryModel(
      id: 'shopping',
      name: 'Shopping',
      iconName: 'shopping_bag',
      colorHex: '#C5942C',
      type: CategoryType.expense,
      isDefault: true,
    ),
    CategoryModel(
      id: 'bills_utilities',
      name: 'Bills & Utilities',
      iconName: 'receipt_long',
      colorHex: '#D64545',
      type: CategoryType.expense,
      isDefault: true,
    ),
    CategoryModel(
      id: 'transportation',
      name: 'Transportation',
      iconName: 'directions_bus',
      colorHex: '#2B694E',
      type: CategoryType.expense,
      isDefault: true,
    ),
    CategoryModel(
      id: 'entertainment',
      name: 'Entertainment',
      iconName: 'movie',
      colorHex: '#7B5800',
      type: CategoryType.expense,
      isDefault: true,
    ),
    CategoryModel(
      id: 'health',
      name: 'Health',
      iconName: 'medical_services',
      colorHex: '#317054',
      type: CategoryType.expense,
      isDefault: true,
    ),
    CategoryModel(
      id: 'salary',
      name: 'Salary',
      iconName: 'payments',
      colorHex: '#2B694E',
      type: CategoryType.income,
      isDefault: true,
    ),
    CategoryModel(
      id: 'investment',
      name: 'Investment',
      iconName: 'trending_up',
      colorHex: '#8E4E00',
      type: CategoryType.income,
      isDefault: true,
    ),
  ];

  /// Curated color choices matching brand tokens for category chips.
  static const List<String> categoryColorChoices = [
    '#8E4E00', // Warm Amber (Primary)
    '#C5942C', // Gold / Tertiary
    '#D64545', // Error / Coral
    '#2B694E', // Forest Green / Secondary
    '#7B5800', // Deep Gold
    '#317054', // Sage Green
    '#D98A3D', // Bright Terracotta
    '#867466', // Muted Earth
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

  /// Converts hex color string (#RRGGBB) to Flutter Color instance.
  static Color getColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
