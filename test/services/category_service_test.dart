import 'package:flutter_test/flutter_test.dart';
import 'package:Weasly/models/category_model.dart';
import 'package:Weasly/utils/default_categories.dart';

void main() {
  group('DefaultCategories Income Expansion Tests', () {
    test('defaultList contains exactly 5 income categories', () {
      final incomeCategories = DefaultCategories.defaultList
          .where((c) => c.type == CategoryType.income)
          .toList();

      expect(incomeCategories.length, equals(5));

      final names = incomeCategories.map((c) => c.name).toList();
      expect(names, containsAll([
        'Salary',
        'Business/Freelance',
        'Investment',
        'Allowance/Gifts',
        'Other Income',
      ]));
    });

    test('All income categories have defined colors and icons', () {
      final incomeCategories = DefaultCategories.defaultList
          .where((c) => c.type == CategoryType.income);

      for (final cat in incomeCategories) {
        expect(cat.iconName.isNotEmpty, isTrue);
        expect(cat.colorHex.startsWith('#'), isTrue);
        expect(DefaultCategories.categoryColorsTable[cat.name], equals(cat.colorHex));
      }
    });

    test('sortCategoriesWithOtherLast places Other and Other Income at the very last position', () {
      final input = [
        const CategoryModel(id: '1', name: 'Bills & Utilities', iconName: 'receipt', colorHex: '#000', type: CategoryType.expense),
        const CategoryModel(id: '2', name: 'Entertainment', iconName: 'movie', colorHex: '#000', type: CategoryType.expense),
        const CategoryModel(id: '3', name: 'Other', iconName: 'category', colorHex: '#000', type: CategoryType.expense),
        const CategoryModel(id: '4', name: 'Shopping', iconName: 'bag', colorHex: '#000', type: CategoryType.expense),
        const CategoryModel(id: '5', name: 'Foods & Drinks', iconName: 'food', colorHex: '#000', type: CategoryType.expense),
        const CategoryModel(id: '6', name: 'Transportation', iconName: 'bus', colorHex: '#000', type: CategoryType.expense),
      ];

      final sorted = DefaultCategories.sortCategoriesWithOtherLast(input);
      final sortedNames = sorted.map((c) => c.name).toList();

      expect(sortedNames.last, equals('Other'));
      expect(sortedNames, equals([
        'Bills & Utilities',
        'Entertainment',
        'Foods & Drinks',
        'Shopping',
        'Transportation',
        'Other',
      ]));
    });

    test('getCustomIconAsset does not match bus in Business/Freelance', () {
      expect(
        DefaultCategories.getCustomIconAsset('Business/Freelance', 'work'),
        isNull,
      );
      expect(
        DefaultCategories.getCustomIconAsset('Transportation', 'directions_bus'),
        equals('assets/Weasly_Icons/Icon_Transportation.png'),
      );
      expect(
        DefaultCategories.getCustomIconAsset('Bus', 'directions_bus'),
        equals('assets/Weasly_Icons/Icon_Transportation.png'),
      );
      expect(
        DefaultCategories.getCustomIconAsset('Starting Balance', 'account_balance_wallet'),
        equals('assets/Weasly_Icons/Icon_StartingBalance.png'),
      );
      expect(
        DefaultCategories.getCustomIconAsset('Transfer', 'swap_horiz'),
        equals('assets/Weasly_Icons/Icon_Transfer.png'),
      );
    });
  });
}
