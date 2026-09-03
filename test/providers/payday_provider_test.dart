import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Weasly/models/payday_settings_model.dart';
import 'package:Weasly/providers/payday_provider.dart';

void main() {
  group('PaydayProvider Tests', () {
    test('paydayCountdownProvider returns null when unconfigured', () async {
      final container = ProviderContainer(
        overrides: [
          paydaySettingsStreamProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );

      await container.read(paydaySettingsStreamProvider.future);
      final paydayInfo = container.read(paydayCountdownProvider);
      expect(paydayInfo, isNull);
    });

    test('paydayCountdownProvider calculates live info when configured', () async {
      final now = DateTime.now();
      final futureDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 5));

      final settings = PaydaySettingsModel(
        frequency: PaydayFrequency.custom,
        nextPaydayDate: futureDate,
        expectedAmount: 12000.0,
      );

      final container = ProviderContainer(
        overrides: [
          paydaySettingsStreamProvider.overrideWith((ref) => Stream.value(settings)),
        ],
      );

      await container.read(paydaySettingsStreamProvider.future);
      final paydayInfo = container.read(paydayCountdownProvider);
      expect(paydayInfo, isNotNull);
      expect(paydayInfo!.daysRemaining, 5);
      expect(paydayInfo.expectedAmount, 12000.0);
      expect(paydayInfo.isCustomExpired, isFalse);
    });

    test('paydayCountdownProvider flags custom expired date when passed', () async {
      final pastDate = DateTime(2026, 1, 1);

      final settings = PaydaySettingsModel(
        frequency: PaydayFrequency.custom,
        nextPaydayDate: pastDate,
        expectedAmount: 12000.0,
      );

      final container = ProviderContainer(
        overrides: [
          paydaySettingsStreamProvider.overrideWith((ref) => Stream.value(settings)),
        ],
      );

      await container.read(paydaySettingsStreamProvider.future);
      final paydayInfo = container.read(paydayCountdownProvider);
      expect(paydayInfo, isNotNull);
      expect(paydayInfo!.isCustomExpired, isTrue);
    });
  });
}

