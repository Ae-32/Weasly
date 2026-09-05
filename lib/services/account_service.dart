import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/account_model.dart';

/// Firestore Service layer for managing financial accounts.
/// Data is scoped strictly under users/{userId}/accounts/{accountId} per architecture.md invariants.
class AccountService {
  final FirebaseFirestore _firestore;

  AccountService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference helper for a given user.
  CollectionReference<Map<String, dynamic>> _userAccountsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('accounts');
  }

  /// Returns a real-time stream of accounts for a specific user.
  Stream<List<AccountModel>> getAccountsStream(String userId) {
    return _userAccountsRef(userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AccountModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Adds a new account document to Firestore under users/{userId}/accounts.
  /// Enforces duplicate prevention for fixed account types (Cash Stash, Digital Stash, Bank Stash).
  /// If the new account has a non-zero starting balance, automatically logs a "Starting Balance" transaction.
  Future<void> addAccount(String userId, AccountModel account) async {
    // Validate duplicate fixed account type before creating
    if (account.type != AccountModel.typeOther) {
      final snapshot = await _userAccountsRef(userId).get();
      final existingAccounts = snapshot.docs
          .map((doc) => AccountModel.fromMap(doc.data(), doc.id))
          .toList();

      if (AccountModel.isDuplicateType(account.type, existingAccounts)) {
        throw Exception('An account of type "${account.name}" already exists.');
      }
    }

    final batch = _firestore.batch();
    final accountDocRef = _userAccountsRef(userId).doc();
    final accountId = accountDocRef.id;

    final accountWithId = account.copyWith(id: accountId);
    batch.set(accountDocRef, accountWithId.toMap());

    // Automatically create a "Starting Balance" transaction log if balance > 0
    if (account.balance > 0) {
      final txDocRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc();

      final startingTxData = {
        'id': txDocRef.id,
        'type': 'income',
        'amount': account.balance,
        'categoryId': 'starting_balance',
        'categoryName': 'Starting Balance',
        'categoryIcon': 'account_balance_wallet',
        'categoryColorHex': '#4E8C6E',
        'accountId': accountId,
        'accountName': account.name,
        'toAccountId': null,
        'toAccountName': null,
        'date': Timestamp.fromDate(DateTime.now()),
        'note': 'Starting balance for ${account.name}',
        'createdAt': FieldValue.serverTimestamp(),
      };

      batch.set(txDocRef, startingTxData);
    }

    await batch.commit();
  }

  /// Updates an existing account document in Firestore.
  /// Note: Balance is deliberately omitted here; balance adjustments must happen via transactions.
  Future<void> updateAccount(String userId, AccountModel account) async {
    final updateData = <String, dynamic>{
      'name': account.name,
      'type': account.type,
      'note': account.note,
    };
    if (account.colorHex != null) {
      updateData['colorHex'] = account.colorHex;
    }
    await _userAccountsRef(userId).doc(account.id).update(updateData);
  }

  /// Deletes an account document from Firestore.
  Future<void> deleteAccount(String userId, String accountId) async {
    await _userAccountsRef(userId).doc(accountId).delete();
  }

  /// Clears 0-balance default stashes from Firestore for the user.
  Future<void> clearZeroBalanceDefaultAccounts(String userId) async {
    final snapshot = await _userAccountsRef(userId).get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    int deleteCount = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
      if (balance == 0.0) {
        batch.delete(doc.reference);
        deleteCount++;
      }
    }
    if (deleteCount > 0) {
      await batch.commit();
    }
  }

  /// Seeds default accounts (Cash Stash, Digital Stash, Bank Stash) if a user has no accounts yet.
  Future<void> seedDefaultAccountsIfEmpty(String userId) async {
    final snapshot = await _userAccountsRef(userId).limit(1).get();
    if (snapshot.docs.isEmpty) {
      final now = DateTime.now();
      final defaultAccounts = [
        AccountModel(
          id: '',
          name: AccountModel.nameCash,
          type: AccountModel.typeCash,
          balance: 0.0,
          note: 'Everyday spending',
          colorHex: 'c5942c', // Tertiary amber
          createdAt: now,
        ),
        AccountModel(
          id: '',
          name: AccountModel.nameDigital,
          type: AccountModel.typeDigital,
          balance: 0.0,
          note: 'Digital transactions',
          colorHex: 'd98a3d', // Primary amber
          createdAt: now.add(const Duration(milliseconds: 1)),
        ),
        AccountModel(
          id: '',
          name: AccountModel.nameBank,
          type: AccountModel.typeBank,
          balance: 0.0,
          note: 'Savings & salary',
          colorHex: '2b694e', // Secondary green
          createdAt: now.add(const Duration(milliseconds: 2)),
        ),
      ];

      final batch = _firestore.batch();
      for (final acc in defaultAccounts) {
        final docRef = _userAccountsRef(userId).doc();
        batch.set(docRef, acc.toMap());
      }
      await batch.commit();
    }
  }
}
