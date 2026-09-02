import 'package:flutter_test/flutter_test.dart';
import 'package:Weasly/models/account_model.dart';

void main() {
  group('AccountModel Tests', () {
    final now = DateTime.now();

    final existingAccounts = [
      AccountModel(
        id: 'acc_1',
        name: 'Cash Wallet',
        type: 'cash',
        balance: 1000.0,
        createdAt: now,
      ),
      AccountModel(
        id: 'acc_2',
        name: 'GCash',
        type: 'gcash',
        balance: 5000.0,
        createdAt: now,
      ),
      AccountModel(
        id: 'acc_3',
        name: 'Crypto Wallet',
        type: 'other',
        balance: 10000.0,
        createdAt: now,
      ),
    ];

    test('isDuplicateType correctly detects existing fixed account types', () {
      expect(
        AccountModel.isDuplicateType(AccountModel.typeCash, existingAccounts),
        isTrue,
      );
      expect(
        AccountModel.isDuplicateType(AccountModel.typeDigital, existingAccounts),
        isTrue, // GCash is a legacy digital stash equivalent
      );
      expect(
        AccountModel.isDuplicateType(AccountModel.typeBank, existingAccounts),
        isFalse, // No bank wallet in existing list
      );
      expect(
        AccountModel.isDuplicateType(AccountModel.typeOther, existingAccounts),
        isFalse, // 'other' type always allows duplicates
      );
    });

    test('isDuplicateType excludes specified account ID when editing', () {
      expect(
        AccountModel.isDuplicateType(
          AccountModel.typeCash,
          existingAccounts,
          excludeAccountId: 'acc_1',
        ),
        isFalse, // acc_1 is excluded during edit
      );
    });

    test('AccountModel copyWith and toMap/fromMap function correctly', () {
      final acc = AccountModel(
        id: 'acc_test',
        name: 'E-Wallet',
        type: 'ewallet',
        balance: 2500.0,
        note: 'Primary digital wallet',
        createdAt: now,
      );

      final map = acc.toMap();
      expect(map['name'], 'E-Wallet');
      expect(map['type'], 'ewallet');
      expect(map['balance'], 2500.0);

      final copy = acc.copyWith(balance: 3000.0);
      expect(copy.id, 'acc_test');
      expect(copy.balance, 3000.0);
    });
  });
}
