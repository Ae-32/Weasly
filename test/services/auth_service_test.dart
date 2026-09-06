import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Weasly/services/auth_service.dart';

class MockUser extends Fake implements User {
  @override
  final bool emailVerified;

  @override
  final List<UserInfo> providerData;

  MockUser({
    required this.emailVerified,
    required this.providerData,
  });
}

class MockUserInfo extends Fake implements UserInfo {
  @override
  final String providerId;

  MockUserInfo({required this.providerId});
}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {}
class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {}

void main() {
  group('AuthService isEmailVerified Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService(
        auth: FakeFirebaseAuth(),
        firestore: FakeFirebaseFirestore(),
      );
    });

    test('isEmailVerified returns false when user is null', () {
      expect(authService.isEmailVerified(null), isFalse);
    });

    test('isEmailVerified returns false when email is not verified and user is not Google user', () {
      final user = MockUser(
        emailVerified: false,
        providerData: [MockUserInfo(providerId: 'password')],
      );
      expect(authService.isEmailVerified(user), isFalse);
    });

    test('isEmailVerified returns true when emailVerified is true', () {
      final user = MockUser(
        emailVerified: true,
        providerData: [MockUserInfo(providerId: 'password')],
      );
      expect(authService.isEmailVerified(user), isTrue);
    });

    test('isEmailVerified returns true when user signed in with Google even if emailVerified flag is false', () {
      final user = MockUser(
        emailVerified: false,
        providerData: [MockUserInfo(providerId: 'google.com')],
      );
      expect(authService.isEmailVerified(user), isTrue);
    });
  });
}
