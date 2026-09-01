import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Weasly/providers/biometric_provider.dart';
import 'package:Weasly/services/biometric_service.dart';
import '../services/biometric_service_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BiometricSettingNotifier Tests', () {
    late MockLocalAuthentication mockAuth;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockAuth = MockLocalAuthentication();
    });

    test('biometricEnabled defaults to false', () {
      final biometricService = BiometricService(auth: mockAuth);
      final notifier = BiometricSettingNotifier(prefs, biometricService);
      expect(notifier.state, isFalse);
    });

    test('setBiometricEnabled updates preference when hardware is supported', () async {
      mockAuth.canCheck = true;
      mockAuth.isSupported = true;

      final biometricService = BiometricService(auth: mockAuth);
      final notifier = BiometricSettingNotifier(prefs, biometricService);

      final (success, error) = await notifier.setBiometricEnabled(true);
      expect(success, isTrue);
      expect(error, isNull);
      expect(notifier.state, isTrue);
      expect(prefs.getBool('biometric_enabled'), isTrue);
    });

    test('setBiometricEnabled fails and returns error when biometrics unavailable', () async {
      mockAuth.canCheck = false;
      mockAuth.isSupported = false;

      final biometricService = BiometricService(auth: mockAuth);
      final notifier = BiometricSettingNotifier(prefs, biometricService);

      final (success, error) = await notifier.setBiometricEnabled(true);
      expect(success, isFalse);
      expect(error, isNotNull);
      expect(notifier.state, isFalse);
    });

    test('reads stored biometric_enabled setting from SharedPreferences on init', () async {
      await prefs.setBool('biometric_enabled', true);
      final biometricService = BiometricService(auth: mockAuth);
      final notifier = BiometricSettingNotifier(prefs, biometricService);
      expect(notifier.state, isTrue);
    });
  });

  group('BiometricLockStateNotifier Tests', () {
    test('starts locked and handles unlock/lock calls', () {
      final notifier = BiometricLockStateNotifier();
      expect(notifier.state, isFalse);

      notifier.unlock();
      expect(notifier.state, isTrue);

      notifier.lock();
      expect(notifier.state, isFalse);
    });
  });
}
