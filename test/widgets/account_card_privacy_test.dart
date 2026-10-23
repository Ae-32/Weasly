import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Weasly/models/account_model.dart';
import 'package:Weasly/providers/balance_visibility_provider.dart';
import 'package:Weasly/providers/onboarding_provider.dart';
import 'package:Weasly/widgets/account_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccountCard Balance Privacy Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    final testAccount = AccountModel(
      id: 'acc-1',
      name: 'Ae Bank',
      balance: 5400.0,
      type: AccountModel.typeBank,
      createdAt: DateTime.now(),
    );

    final negativeAccount = AccountModel(
      id: 'acc-2',
      name: 'Credit Card',
      balance: -150.0,
      type: AccountModel.typeBank,
      createdAt: DateTime.now(),
    );

    testWidgets('displays actual formatted balance when visibility is enabled',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AccountCard(
                account: testAccount,
                totalBalance: 5400.0,
                isBalanceHidden: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ae Bank'), findsOneWidget);
      expect(find.text('₱5,400.00'), findsOneWidget);
      expect(find.text('₱ • • • • •'), findsNothing);
    });

    testWidgets('displays masked balance when isBalanceHidden is true',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AccountCard(
                account: testAccount,
                totalBalance: 5400.0,
                isBalanceHidden: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ae Bank'), findsOneWidget);
      expect(find.text('₱5,400.00'), findsNothing);
      expect(find.text('₱ • • • • •'), findsOneWidget);
    });

    testWidgets('hides Needs Adjustment label when balance is hidden on negative balance account',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AccountCard(
                account: negativeAccount,
                totalBalance: 5400.0,
                isBalanceHidden: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('₱ • • • • •'), findsOneWidget);
      expect(find.text('Needs Adjustment'), findsNothing);
    });

    testWidgets('shows Needs Adjustment label when balance is visible on negative balance account',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AccountCard(
                account: negativeAccount,
                totalBalance: 5400.0,
                isBalanceHidden: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('-₱150.00'), findsOneWidget);
      expect(find.text('Needs Adjustment'), findsOneWidget);
    });

    testWidgets('inherits balance visibility from balanceVisibilityProvider when parameter omitted',
        (tester) async {
      await prefs.setBool(kHideAccountBalanceKey, true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AccountCard(
                account: testAccount,
                totalBalance: 5400.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('₱ • • • • •'), findsOneWidget);
      expect(find.text('₱5,400.00'), findsNothing);
    });
  });
}
