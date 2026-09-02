import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class TransactionException implements Exception {
  final String message;
  const TransactionException(this.message);

  @override
  String toString() => message;
}

/// Service class managing Firestore CRUD operations for transactions with atomic balance updates.
/// Collection path: users/{userId}/transactions/
class TransactionService {
  final FirebaseFirestore _firestore;

  TransactionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _transactionsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('transactions');
  }

  CollectionReference<Map<String, dynamic>> _accountsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('accounts');
  }

  /// Real-time stream of all transactions for a user, ordered by date descending.
  Stream<List<TransactionModel>> getTransactionsStream(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _transactionsRef(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Adds a new transaction and atomically updates the relevant account balance(s).
  Future<TransactionModel> addTransaction({
    required String userId,
    required TransactionType type,
    required double amount,
    required String categoryId,
    required String categoryName,
    required String categoryIcon,
    required String categoryColorHex,
    required String accountId,
    required String accountName,
    String? toAccountId,
    String? toAccountName,
    required DateTime date,
    String? note,
  }) async {
    if (userId.isEmpty) {
      throw const TransactionException("User is not signed in.");
    }
    if (amount <= 0) {
      throw const TransactionException("Amount must be greater than zero.");
    }
    if (accountId.isEmpty) {
      throw const TransactionException("Please select an account.");
    }
    if (type == TransactionType.transfer) {
      if (toAccountId == null || toAccountId.isEmpty) {
        throw const TransactionException("Please select a destination account for the transfer.");
      }
      if (accountId == toAccountId) {
        throw const TransactionException("Source and destination accounts cannot be the same.");
      }
    }

    final txDocRef = _transactionsRef(userId).doc();
    final transactionModel = TransactionModel(
      id: txDocRef.id,
      type: type,
      amount: amount,
      categoryId: categoryId,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      categoryColorHex: categoryColorHex,
      accountId: accountId,
      accountName: accountName,
      toAccountId: toAccountId,
      toAccountName: toAccountName,
      date: date,
      note: note,
      createdAt: DateTime.now(),
    );

    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    // Pre-check balance before runTransaction to ensure clean Dart exception throwing (especially on Flutter Web)
    if (type == TransactionType.expense || type == TransactionType.transfer) {
      final sourceAccountRef = _accountsRef(userId).doc(accountId);
      final sourceSnap = await sourceAccountRef.get();
      if (!sourceSnap.exists) {
        throw const TransactionException("Selected account does not exist.");
      }
      final sourceData = sourceSnap.data() ?? {};
      final double currentSourceBal = (sourceData['balance'] as num?)?.toDouble() ?? 0.0;
      final String sourceAccountName = (sourceData['name'] as String?) ?? accountName;

      if (currentSourceBal < amount) {
        final formattedBal = currencyFormatter.format(currentSourceBal);
        final formattedAmount = currencyFormatter.format(amount);
        final action = type == TransactionType.transfer ? 'transfer' : 'spend';
        throw TransactionException(
          "INSUFFICIENT_BALANCE|$sourceAccountName|$formattedBal|$formattedAmount|$action",
        );
      }
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final sourceAccountRef = _accountsRef(userId).doc(accountId);
        final sourceSnap = await transaction.get(sourceAccountRef);
        if (!sourceSnap.exists) {
          throw const TransactionException("Selected account does not exist.");
        }
        final sourceData = sourceSnap.data() ?? {};
        final double currentSourceBal =
            (sourceData['balance'] as num?)?.toDouble() ?? 0.0;
        final String sourceAccountName =
            (sourceData['name'] as String?) ?? accountName;

        // Validation 1 & 2: Expense / Transfer source account must have sufficient balance
        if (type == TransactionType.expense || type == TransactionType.transfer) {
          if (currentSourceBal < amount) {
            final formattedBal = currencyFormatter.format(currentSourceBal);
            final formattedAmount = currencyFormatter.format(amount);
            final action = type == TransactionType.transfer ? 'transfer' : 'spend';
            throw TransactionException(
              "INSUFFICIENT_BALANCE|$sourceAccountName|$formattedBal|$formattedAmount|$action",
            );
          }
        }

        if (type == TransactionType.expense) {
          transaction.update(sourceAccountRef, {
            'balance': currentSourceBal - amount,
          });
        } else if (type == TransactionType.income) {
          transaction.update(sourceAccountRef, {
            'balance': currentSourceBal + amount,
          });
        } else if (type == TransactionType.transfer) {
          final destAccountRef = _accountsRef(userId).doc(toAccountId!);
          final destSnap = await transaction.get(destAccountRef);
          if (!destSnap.exists) {
            throw const TransactionException("Destination account does not exist.");
          }
          final double currentDestBal =
              (destSnap.data()?['balance'] as num?)?.toDouble() ?? 0.0;

          transaction.update(sourceAccountRef, {
            'balance': currentSourceBal - amount,
          });
          transaction.update(destAccountRef, {
            'balance': currentDestBal + amount,
          });
        }

        transaction.set(txDocRef, transactionModel.toMap());
      });

      return transactionModel;
    } catch (e) {
      final unboxed = _unwrapException(e);
      if (unboxed is TransactionException) rethrow;
      final errStr = unboxed.toString();
      if (errStr.contains("INSUFFICIENT_BALANCE") || errStr.contains("Insufficient balance")) {
        throw TransactionException(errStr);
      }
      throw TransactionException(_cleanErrorMessage(errStr));
    }
  }

  /// Updates an existing transaction and atomically adjusts account balances.
  Future<void> updateTransaction({
    required String userId,
    required TransactionModel oldTx,
    required TransactionModel newTx,
  }) async {
    if (userId.isEmpty) {
      throw const TransactionException("User is not signed in.");
    }
    if (newTx.amount <= 0) {
      throw const TransactionException("Amount must be greater than zero.");
    }
    if (newTx.accountId.isEmpty) {
      throw const TransactionException("Please select an account.");
    }
    if (newTx.type == TransactionType.transfer) {
      if (newTx.toAccountId == null || newTx.toAccountId!.isEmpty) {
        throw const TransactionException("Please select a destination account for the transfer.");
      }
      if (newTx.accountId == newTx.toAccountId) {
        throw const TransactionException("Source and destination accounts cannot be the same.");
      }
    }

    final txDocRef = _transactionsRef(userId).doc(oldTx.id);
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    // Pre-check balance before runTransaction
    final newSourceRef = _accountsRef(userId).doc(newTx.accountId);
    final newSourceSnap = await newSourceRef.get();
    if (!newSourceSnap.exists) {
      throw const TransactionException("Selected account does not exist.");
    }
    final newSourceData = newSourceSnap.data() ?? {};
    final double currentNewSourceBal = (newSourceData['balance'] as num?)?.toDouble() ?? 0.0;
    final String newSourceAccountName = (newSourceData['name'] as String?) ?? newTx.accountName;

    double effectiveAvailableBal = currentNewSourceBal;
    if (oldTx.accountId == newTx.accountId) {
      if (oldTx.type == TransactionType.expense || oldTx.type == TransactionType.transfer) {
        effectiveAvailableBal += oldTx.amount;
      } else if (oldTx.type == TransactionType.income) {
        effectiveAvailableBal -= oldTx.amount;
      }
    }
    if (oldTx.toAccountId == newTx.accountId && oldTx.type == TransactionType.transfer) {
      effectiveAvailableBal -= oldTx.amount;
    }

    if (newTx.type == TransactionType.expense || newTx.type == TransactionType.transfer) {
      if (effectiveAvailableBal < newTx.amount) {
        final formattedBal = currencyFormatter.format(effectiveAvailableBal);
        final formattedAmount = currencyFormatter.format(newTx.amount);
        final action = newTx.type == TransactionType.transfer ? 'transfer' : 'spend';
        throw TransactionException(
          "INSUFFICIENT_BALANCE|$newSourceAccountName|$formattedBal|$formattedAmount|$action",
        );
      }
    }

    try {
      await _firestore.runTransaction((transaction) async {
        // Fetch source account for new transaction
        final newSourceRef = _accountsRef(userId).doc(newTx.accountId);
        final newSourceSnap = await transaction.get(newSourceRef);
        if (!newSourceSnap.exists) {
          throw const TransactionException("Selected account does not exist.");
        }
        final newSourceData = newSourceSnap.data() ?? {};
        final double currentNewSourceBal =
            (newSourceData['balance'] as num?)?.toDouble() ?? 0.0;
        final String newSourceAccountName =
            (newSourceData['name'] as String?) ?? newTx.accountName;

        // Validation 4: Calculate effective available balance for newTx source account (reverting oldTx impact first)
        double effectiveAvailableBal = currentNewSourceBal;
        if (oldTx.accountId == newTx.accountId) {
          if (oldTx.type == TransactionType.expense || oldTx.type == TransactionType.transfer) {
            effectiveAvailableBal += oldTx.amount;
          } else if (oldTx.type == TransactionType.income) {
            effectiveAvailableBal -= oldTx.amount;
          }
        }
        if (oldTx.toAccountId == newTx.accountId && oldTx.type == TransactionType.transfer) {
          effectiveAvailableBal -= oldTx.amount;
        }

        // Check if new transaction is expense or transfer and exceeds effective available balance
        if (newTx.type == TransactionType.expense || newTx.type == TransactionType.transfer) {
          if (effectiveAvailableBal < newTx.amount) {
            final formattedBal = currencyFormatter.format(effectiveAvailableBal);
            final formattedAmount = currencyFormatter.format(newTx.amount);
            final action = newTx.type == TransactionType.transfer ? 'transfer' : 'spend';
            throw TransactionException(
              "INSUFFICIENT_BALANCE|$newSourceAccountName|$formattedBal|$formattedAmount|$action",
            );
          }
        }

        // 1. Revert old transaction balance impact
        await _applyBalanceDelta(
          transaction: transaction,
          userId: userId,
          type: oldTx.type,
          amount: -oldTx.amount, // Inverse amount to revert
          accountId: oldTx.accountId,
          toAccountId: oldTx.toAccountId,
        );

        // 2. Apply new transaction balance impact
        await _applyBalanceDelta(
          transaction: transaction,
          userId: userId,
          type: newTx.type,
          amount: newTx.amount,
          accountId: newTx.accountId,
          toAccountId: newTx.toAccountId,
        );

        // 3. Save updated transaction doc
        transaction.set(txDocRef, newTx.toMap(), SetOptions(merge: true));
      });
    } catch (e) {
      final unboxed = _unwrapException(e);
      if (unboxed is TransactionException) rethrow;
      final errStr = unboxed.toString();
      if (errStr.contains("INSUFFICIENT_BALANCE") || errStr.contains("Insufficient balance")) {
        throw TransactionException(errStr);
      }
      throw TransactionException(_cleanErrorMessage(errStr));
    }
  }

  /// Deletes a transaction and atomically restores affected account balance(s).
  Future<void> deleteTransaction({
    required String userId,
    required TransactionModel tx,
  }) async {
    if (userId.isEmpty) {
      throw const TransactionException("User is not signed in.");
    }

    final txDocRef = _transactionsRef(userId).doc(tx.id);

    try {
      await _firestore.runTransaction((transaction) async {
        // Revert transaction balance impact (invert amount)
        await _applyBalanceDelta(
          transaction: transaction,
          userId: userId,
          type: tx.type,
          amount: -tx.amount,
          accountId: tx.accountId,
          toAccountId: tx.toAccountId,
        );

        transaction.delete(txDocRef);
      });
    } catch (e) {
      if (e is TransactionException) rethrow;
      throw TransactionException("Failed to delete transaction: ${e.toString()}");
    }
  }

  /// Internal helper to modify account balances within a transaction context.
  Future<void> _applyBalanceDelta({
    required Transaction transaction,
    required String userId,
    required TransactionType type,
    required double amount,
    required String accountId,
    String? toAccountId,
  }) async {
    final sourceRef = _accountsRef(userId).doc(accountId);
    final sourceSnap = await transaction.get(sourceRef);
    if (sourceSnap.exists) {
      final double currentSourceBal =
          (sourceSnap.data()?['balance'] as num?)?.toDouble() ?? 0.0;

      if (type == TransactionType.expense) {
        transaction.update(sourceRef, {'balance': currentSourceBal - amount});
      } else if (type == TransactionType.income) {
        transaction.update(sourceRef, {'balance': currentSourceBal + amount});
      } else if (type == TransactionType.transfer && toAccountId != null) {
        final destRef = _accountsRef(userId).doc(toAccountId);
        final destSnap = await transaction.get(destRef);
        if (destSnap.exists) {
          final double currentDestBal =
              (destSnap.data()?['balance'] as num?)?.toDouble() ?? 0.0;
          transaction.update(sourceRef, {'balance': currentSourceBal - amount});
          transaction.update(destRef, {'balance': currentDestBal + amount});
        }
      }
    }
  }

  /// Helper to unwrap Web JS exception wrappers around boxed Dart exceptions.
  dynamic _unwrapException(dynamic e) {
    if (e is TransactionException) return e;
    final str = e.toString();
    if (str.contains("INSUFFICIENT_BALANCE")) {
      final idx = str.indexOf("INSUFFICIENT_BALANCE");
      return TransactionException(str.substring(idx));
    }
    try {
      final boxed = (e as dynamic).error;
      if (boxed != null) {
        if (boxed is TransactionException) return boxed;
        final boxedStr = boxed.toString();
        if (boxedStr.contains("INSUFFICIENT_BALANCE")) {
          final idx = boxedStr.indexOf("INSUFFICIENT_BALANCE");
          return TransactionException(boxedStr.substring(idx));
        }
        return boxed;
      }
    } catch (_) {}
    return e;
  }

  /// Strips technical stack trace prefixes and raw Dart exception wrapper boilerplate.
  String _cleanErrorMessage(String rawStr) {
    String cleaned = rawStr
        .replaceAll(RegExp(r'^(Exception|TransactionException|Failed to add transaction|Failed to update transaction):\s*'), '')
        .replaceAll(RegExp(r'Error: Dart exception thrown from converted Future.*'), '')
        .trim();
    if (cleaned.isEmpty) {
      cleaned = "An error occurred while processing the transaction. Please try again.";
    }
    return cleaned;
  }
}
