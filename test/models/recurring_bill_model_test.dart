import 'package:flutter_test/flutter_test.dart';
import 'package:Weasly/models/recurring_bill_model.dart';

void main() {
  group('RecurringBillModel Tests', () {
    test('calculateNextDueDate advances weekly frequency by 7 days', () {
      final initialDate = DateTime(2026, 8, 1, 10, 0);
      final bill = RecurringBillModel(
        id: 'bill1',
        name: 'Weekly Pass',
        amount: 100.0,
        frequency: BillFrequency.weekly,
        nextDueDate: initialDate,
        categoryId: 'cat1',
        categoryName: 'Entertainment',
        categoryIcon: 'movie',
        categoryColorHex: '#8E4E00',
        accountId: 'acc1',
        accountName: 'Cash Stash',
      );

      final nextDate = bill.calculateNextDueDate();
      expect(nextDate, DateTime(2026, 8, 8, 10, 0));
    });

    test('calculateNextDueDate advances monthly frequency by 1 month', () {
      final initialDate = DateTime(2026, 8, 15, 12, 0);
      final bill = RecurringBillModel(
        id: 'bill2',
        name: 'Internet Bill',
        amount: 1500.0,
        frequency: BillFrequency.monthly,
        nextDueDate: initialDate,
        categoryId: 'cat2',
        categoryName: 'Bills & Utilities',
        categoryIcon: 'receipt_long',
        categoryColorHex: '#D64545',
        accountId: 'acc2',
        accountName: 'Digital Stash',
      );

      final nextDate = bill.calculateNextDueDate();
      expect(nextDate, DateTime(2026, 9, 15, 12, 0));
    });

    test('calculateNextDueDate advances yearly frequency by 1 year', () {
      final initialDate = DateTime(2026, 8, 26, 9, 0);
      final bill = RecurringBillModel(
        id: 'bill3',
        name: 'Domain Renewal',
        amount: 800.0,
        frequency: BillFrequency.yearly,
        nextDueDate: initialDate,
        categoryId: 'cat2',
        categoryName: 'Bills & Utilities',
        categoryIcon: 'receipt_long',
        categoryColorHex: '#D64545',
        accountId: 'acc3',
        accountName: 'Bank Stash',
      );

      final nextDate = bill.calculateNextDueDate();
      expect(nextDate, DateTime(2027, 8, 26, 9, 0));
    });

    test('fromMap and toMap serialize correctly', () {
      final bill = RecurringBillModel(
        id: 'bill_test',
        name: 'Netflix',
        amount: 549.0,
        frequency: BillFrequency.monthly,
        nextDueDate: DateTime(2026, 9, 1),
        categoryId: 'cat_ent',
        categoryName: 'Entertainment',
        categoryIcon: 'movie',
        categoryColorHex: '#7B5800',
        accountId: 'acc_digital',
        accountName: 'Digital Stash',
        reminderDaysBefore: 3,
        isReminderEnabled: true,
      );

      final map = bill.toMap();
      expect(map['id'], 'bill_test');
      expect(map['name'], 'Netflix');
      expect(map['amount'], 549.0);
      expect(map['frequency'], 'monthly');
      expect(map['reminderDaysBefore'], 3);
      expect(map['isReminderEnabled'], true);

      final restored = RecurringBillModel.fromMap(map, 'bill_test');
      expect(restored.name, 'Netflix');
      expect(restored.amount, 549.0);
      expect(restored.frequency, BillFrequency.monthly);
      expect(restored.reminderDaysBefore, 3);
      expect(restored.isReminderEnabled, true);
    });
  });
}
