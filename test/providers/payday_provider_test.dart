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
      expect(paydayInfo.isCustomExpired, isFalse);
    });

    test('paydayCountdownProvider flags custom expired date when passed', () async {
      final pastDate = DateTime(2026, 1, 1);

      final settings = PaydaySettingsModel(
        frequency: PaydayFrequency.custom,
        nextPaydayDate: pastDate,
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

    test('shouldShowPaydayPromptProvider returns settings on payday when unconfirmed and undismissed', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final settings = PaydaySettingsModel(
        frequency: PaydayFrequency.custom,
        nextPaydayDate: today,
      );

      final container = ProviderContainer(
        overrides: [
          paydaySettingsStreamProvider.overrideWith((ref) => Stream.value(settings)),
        ],
      );

      await container.read(paydaySettingsStreamProvider.future);
      final promptSettings = container.read(shouldShowPaydayPromptProvider);
      expect(promptSettings, isNotNull);

      final reminderBanner = container.read(shouldShowPaydayReminderBannerProvider);
      expect(reminderBanner, isFalse);
    });

    test('shouldShowPaydayReminderBannerProvider returns true when dismissed today without confirmation', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final settings = PaydaySettingsModel(
        frequency: PaydayFrequency.weekly,
        nextPaydayDate: today.add(const Duration(days: 7)),
        lastDismissedPaydayDate: today,
      );

      final container = ProviderContainer(
        overrides: [
          paydaySettingsStreamProvider.overrideWith((ref) => Stream.value(settings)),
        ],
      );

      await container.read(paydaySettingsStreamProvider.future);
      final promptSettings = container.read(shouldShowPaydayPromptProvider);
      expect(promptSettings, isNull);

      final reminderBanner = container.read(shouldShowPaydayReminderBannerProvider);
      expect(reminderBanner, isTrue);
    });
  });
}


