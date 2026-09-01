import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Weasly/models/user_model.dart';
import 'package:Weasly/providers/auth_provider.dart';
import 'package:Weasly/screens/auth/login_screen.dart';
import 'package:Weasly/services/auth_service.dart';

class FakeAuthService implements AuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  User? get currentUser => null;

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return const UserModel(id: 'test-id', email: 'test@example.com');
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return const UserModel(id: 'test-id', email: 'test@example.com');
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    return const UserModel(id: 'test-id', email: 'test@example.com');
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('Renders LoginScreen UI elements', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(FakeAuthService()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Weasly'), findsOneWidget);
    expect(find.text('Stash your cash, gently.'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
  });
}
