import 'package:flutter_test/flutter_test.dart';
import 'package:Weasly/models/payday_settings_model.dart';


void main() {
  group('PaydayFrequency Enum Tests', () {
    test('fromString parses correctly for all frequencies', () {
      expect(PaydayFrequency.fromString('weekly'), PaydayFrequency.weekly);
      expect(PaydayFrequency.fromString('biWeekly'), PaydayFrequency.biWeekly);
      expect(PaydayFrequency.fromString('semiMonthly'), PaydayFrequency.semiMonthly);
      expect(PaydayFrequency.fromString('monthly'), PaydayFrequency.monthly);
      expect(PaydayFrequency.fromString('custom'), PaydayFrequency.custom);
      expect(PaydayFrequency.fromString('unknown'), PaydayFrequency.custom);
    });

    test('displayName returns clear labels', () {
      expect(PaydayFrequency.weekly.displayName, contains('Weekly'));
      expect(PaydayFrequency.biWeekly.displayName, contains('Bi-weekly'));
      expect(PaydayFrequency.semiMonthly.displayName, contains('Semi-monthly'));
      expect(PaydayFrequency.monthly.displayName, contains('Monthly'));
      expect(PaydayFrequency.custom.displayName, contains('Custom'));
    });
  });

  group('PaydaySettingsModel Serialization Tests', () {
    test('fromMap and toMap correctly serialize and deserialize', () {
      final now = DateTime(2026, 9, 3);
      final model = PaydaySettingsModel(
        frequency: PaydayFrequency.semiMonthly,
        nextPaydayDate: DateTime(2026, 9, 15),
        expectedAmount: 15000.0,
        linkedAccountId: 'acc_123',
        linkedAccountName: 'Bank Stash',
        semiMonthlyDay1: 15,
        semiMonthlyDay2: 30,
        updatedAt: now,
      );

      final map = model.toMap();
      expect(map['frequency'], 'semiMonthly');
      expect(map['expectedAmount'], 15000.0);
      expect(map['linkedAccountId'], 'acc_123');
      expect(map['linkedAccountName'], 'Bank Stash');
      expect(map['semiMonthlyDay1'], 15);
      expect(map['semiMonthlyDay2'], 30);

      final deserialized = PaydaySettingsModel.fromMap(map);
      expect(deserialized.frequency, PaydayFrequency.semiMonthly);
      expect(deserialized.expectedAmount, 15000.0);
      expect(deserialized.linkedAccountId, 'acc_123');
      expect(deserialized.linkedAccountName, 'Bank Stash');
      expect(deserialized.semiMonthlyDay1, 15);
      expect(deserialized.semiMonthlyDay2, 30);
    });
  });

  group('PaydaySettingsModel Date Calculations', () {
    test('Weekly frequency calculates 7-day increments', () {
      final anchor = DateTime(2026, 8, 1);
      final model = PaydaySettingsModel(
        frequency: PaydayFrequency.weekly,
        nextPaydayDate: anchor,
        expectedAmount: 5000.0,
      );

      final refDate = DateTime(2026, 9, 3); // Thursday
      final nextPayday = model.calculateNextUpcomingPayday(refDate);

      // Aug 1 -> 8 -> 15 -> 22 -> 29 -> Sep 5
      expect(nextPayday, DateTime(2026, 9, 5));
    });

    test('Bi-weekly frequency calculates 14-day increments', () {
      final anchor = DateTime(2026, 8, 1);
      final model = PaydaySettingsModel(
        frequency: PaydayFrequency.biWeekly,
        nextPaydayDate: anchor,
        expectedAmount: 10000.0,
      );

      final refDate = DateTime(2026, 9, 3);
      final nextPayday = model.calculateNextUpcomingPayday(refDate);

      // Aug 1 -> Aug 15 -> Aug 29 -> Sep 12
      expect(nextPayday, DateTime(2026, 9, 12));
    });

    test('Semi-monthly frequency calculates 15th and 30th candidates', () {
      final model = PaydaySettingsModel(
        frequency: PaydayFrequency.semiMonthly,
        nextPaydayDate: DateTime(2026, 8, 15),
        expectedAmount: 20000.0,
        semiMonthlyDay1: 15,
        semiMonthlyDay2: 30,
      );

      // On Sep 3, next semi-monthly payday should be Sep 15
      final refDate1 = DateTime(2026, 9, 3);
      expect(model.calculateNextUpcomingPayday(refDate1), DateTime(2026, 9, 15));

      // On Sep 16, next semi-monthly payday should be Sep 30
      final refDate2 = DateTime(2026, 9, 16);
      expect(model.calculateNextUpcomingPayday(refDate2), DateTime(2026, 9, 30));

      // On Sep 30, next semi-monthly payday should be Sep 30 (today)
      final refDate3 = DateTime(2026, 9, 30);
      expect(model.calculateNextUpcomingPayday(refDate3), DateTime(2026, 9, 30));

      // On Oct 1, next semi-monthly payday should be Oct 15
      final refDate4 = DateTime(2026, 10, 1);
      expect(model.calculateNextUpcomingPayday(refDate4), DateTime(2026, 10, 15));
    });

    test('Semi-monthly handles shorter months (February 28/29)', () {
      final model = PaydaySettingsModel(
        frequency: PaydayFrequency.semiMonthly,
        nextPaydayDate: DateTime(2026, 1, 15),
        expectedAmount: 20000.0,
        semiMonthlyDay1: 15,
        semiMonthlyDay2: 30,
      );

      // On Feb 16 in non-leap year (2027), 30th becomes Feb 28
      final refDate = DateTime(2027, 2, 16);
      final nextPayday = model.calculateNextUpcomingPayday(refDate);
      expect(nextPayday, DateTime(2027, 2, 28));
    });

    test('Monthly frequency calculates target day of month', () {
      final model = PaydaySettingsModel(
        frequency: PaydayFrequency.monthly,
        nextPaydayDate: DateTime(2026, 8, 15),
        expectedAmount: 30000.0,
        monthlyDay: 15,
      );

      final refDate1 = DateTime(2026, 9, 3);
      expect(model.calculateNextUpcomingPayday(refDate1), DateTime(2026, 9, 15));

      final refDate2 = DateTime(2026, 9, 16);
      expect(model.calculateNextUpcomingPayday(refDate2), DateTime(2026, 10, 15));
    });

    test('Custom frequency retains manual target date', () {
      final customDate = DateTime(2026, 9, 10);
      final model = PaydaySettingsModel(
        frequency: PaydayFrequency.custom,
        nextPaydayDate: customDate,
        expectedAmount: 5000.0,
      );

      final refDate = DateTime(2026, 9, 3);
      expect(model.calculateNextUpcomingPayday(refDate), customDate);
    });
  });
}
