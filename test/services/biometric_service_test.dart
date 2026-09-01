import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';

import 'package:Weasly/services/biometric_service.dart';

class MockLocalAuthentication implements LocalAuthentication {
  bool canCheck = true;
  bool isSupported = true;
  bool authResult = true;

  @override
  Future<bool> get canCheckBiometrics async => canCheck;

  @override
  Future<bool> isDeviceSupported() async => isSupported;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #authenticate) {
      return Future.value(authResult);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('BiometricService Tests', () {
    late MockLocalAuthentication mockAuth;
    late BiometricService biometricService;

    setUp(() {
      mockAuth = MockLocalAuthentication();
      biometricService = BiometricService(auth: mockAuth);
    });

    test('canCheckBiometrics returns true when device supports biometrics', () async {
      mockAuth.canCheck = true;
      mockAuth.isSupported = true;

      final result = await biometricService.canCheckBiometrics();
      expect(result, isTrue);
    });

    test('canCheckBiometrics returns false when device does not support biometrics', () async {
      mockAuth.canCheck = false;
      mockAuth.isSupported = false;

      final result = await biometricService.canCheckBiometrics();
      expect(result, isFalse);
    });

    test('authenticate returns true on successful biometric prompt', () async {
      mockAuth.canCheck = true;
      mockAuth.isSupported = true;
      mockAuth.authResult = true;

      final result = await biometricService.authenticate();
      expect(result, isTrue);
    });

    test('authenticate returns false when user cancels or fails biometrics', () async {
      mockAuth.canCheck = true;
      mockAuth.isSupported = true;
      mockAuth.authResult = false;

      final result = await biometricService.authenticate();
      expect(result, isFalse);
    });
  });
}
