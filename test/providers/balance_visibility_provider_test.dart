import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Weasly/providers/balance_visibility_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BalanceVisibilityNotifier Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('balance visibility defaults to false (not hidden)', () {
      final notifier = BalanceVisibilityNotifier(prefs);
      expect(notifier.state, isFalse);
    });

    test('toggle flips the state and persists value to SharedPreferences', () async {
      final notifier = BalanceVisibilityNotifier(prefs);

      await notifier.toggle();
      expect(notifier.state, isTrue);
      expect(prefs.getBool(kHideAccountBalanceKey), isTrue);

      await notifier.toggle();
      expect(notifier.state, isFalse);
      expect(prefs.getBool(kHideAccountBalanceKey), isFalse);
    });

    test('setHideBalance sets and persists the hidden flag', () async {
      final notifier = BalanceVisibilityNotifier(prefs);

      await notifier.setHideBalance(true);
      expect(notifier.state, isTrue);
      expect(prefs.getBool(kHideAccountBalanceKey), isTrue);

      await notifier.setHideBalance(false);
      expect(notifier.state, isFalse);
      expect(prefs.getBool(kHideAccountBalanceKey), isFalse);
    });

    test('reads stored hide_account_balance setting on initialization', () async {
      await prefs.setBool(kHideAccountBalanceKey, true);
      final notifier = BalanceVisibilityNotifier(prefs);
      expect(notifier.state, isTrue);
    });
  });
}
