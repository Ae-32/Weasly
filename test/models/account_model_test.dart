import 'package:flutter_test/flutter_test.dart';
import 'package:Weasly/models/account_model.dart';

void main() {
  group('AccountModel Tests', () {
    final now = DateTime.now();

    final existingAccounts = [
      AccountModel(
        id: 'acc_1',
        name: AccountModel.nameCash,
        type: AccountModel.typeCash,
        balance: 1000.0,
        createdAt: now,
      ),
      AccountModel(
        id: 'acc_2',
        name: AccountModel.nameDigital,
        type: AccountModel.typeDigital,
        balance: 5000.0,
        createdAt: now,
      ),
      AccountModel(
        id: 'acc_3',
        name: 'Crypto Wallet',
        type: AccountModel.typeOther,
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
        isTrue,
      );
      expect(
        AccountModel.isDuplicateType(AccountModel.typeBank, existingAccounts),
        isFalse, // No bank stash in existing list
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
        name: AccountModel.nameDigital,
        type: AccountModel.typeDigital,
        balance: 2500.0,
        note: 'Primary digital stash',
        createdAt: now,
      );

      final map = acc.toMap();
      expect(map['name'], AccountModel.nameDigital);
      expect(map['type'], AccountModel.typeDigital);
      expect(map['balance'], 2500.0);

      final copy = acc.copyWith(balance: 3000.0);
      expect(copy.id, 'acc_test');
      expect(copy.balance, 3000.0);
    });

    test('getStashIconAsset returns correct PNG asset paths for stash types', () {
      expect(
        AccountModel.getStashIconAsset(AccountModel.typeCash),
        'assets/Weasly_Icons/Cash_Stash.png',
      );
      expect(
        AccountModel.getStashIconAsset(AccountModel.typeDigital),
        'assets/Weasly_Icons/Digital_Stash.png',
      );
      expect(
        AccountModel.getStashIconAsset(AccountModel.typeBank),
        'assets/Weasly_Icons/Bank_Stash.png',
      );
      expect(
        AccountModel.getStashIconAsset(AccountModel.typeOther),
        'assets/Weasly_Icons/Other_Stash.png',
      );
      expect(
        AccountModel.getStashIconAsset('custom_crypto', 'My Crypto Stash'),
        'assets/Weasly_Icons/Other_Stash.png',
      );
    });
  });
}
