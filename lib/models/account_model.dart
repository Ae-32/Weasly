import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a financial account (Cash, GCash, Bank, etc.) in Weasly.
class AccountModel {
  final String id;
  final String name;
  final String type; // 'cash', 'digital', 'bank', 'other'
  final double balance;
  final String? note;
  final String? colorHex;
  final DateTime createdAt;

  const AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.note,
    this.colorHex,
    required this.createdAt,
  });

  /// Factory constructor to create an AccountModel from a Firestore document.
  factory AccountModel.fromMap(Map<String, dynamic> map, String docId) {
    return AccountModel(
      id: docId,
      name: map['name'] ?? 'Unnamed Account',
      type: map['type'] ?? 'cash',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      note: map['note'],
      colorHex: map['colorHex'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts AccountModel to a Map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'balance': balance,
      'note': note,
      'colorHex': colorHex,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Copy method for creating updated instances.
  AccountModel copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    String? note,
    String? colorHex,
    DateTime? createdAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      note: note ?? this.note,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Fixed account type constants for new stashes.
  static const String typeCash = 'cash';
  static const String typeDigital = 'digital';
  static const String typeBank = 'bank';
  static const String typeOther = 'other';

  /// Standard display names for fixed account types.
  static const String nameCash = 'Cash Stash';
  static const String nameDigital = 'Digital Stash';
  static const String nameBank = 'Bank Stash';

  /// Returns custom PNG icon asset path for a stash based on type or name.
  static String getStashIconAsset(String type, [String? name]) {
    final cleanType = type.trim().toLowerCase();
    final cleanName = (name ?? '').trim().toLowerCase();

    if (cleanType == typeDigital ||
        cleanType == 'digital_stash' ||
        cleanType == 'ewallet' ||
        cleanType == 'e-wallet' ||
        cleanType == 'gcash' ||
        cleanName.contains('digital') ||
        cleanName.contains('gcash') ||
        cleanName.contains('e-wallet')) {
      return 'assets/Weasly_Icons/Digital_Stash.png';
    }

    if (cleanType == typeBank ||
        cleanType == 'bank_wallet' ||
        cleanType == 'bank_stash' ||
        cleanName.contains('bank')) {
      return 'assets/Weasly_Icons/Bank_Stash.png';
    }

    if (cleanType == typeCash ||
        cleanType == 'cash_wallet' ||
        cleanType == 'cash_stash' ||
        cleanName.contains('cash')) {
      return 'assets/Weasly_Icons/Cash_Stash.png';
    }

    return 'assets/Weasly_Icons/Other_Stash.png';
  }

  /// Checks if an existing account list already contains an account of the given fixed type.
  /// Fixed types ('cash', 'digital', 'bank') only allow 1 instance per user.
  /// 'other' allows multiple instances and always returns false.
  static bool isDuplicateType(String targetType, List<AccountModel> existingAccounts, {String? excludeAccountId}) {
    if (targetType == typeOther) return false;

    for (final acc in existingAccounts) {
      if (excludeAccountId != null && acc.id.isNotEmpty && acc.id == excludeAccountId) continue;

      final accType = acc.type.toLowerCase();
      final accName = acc.name.trim().toLowerCase();

      switch (targetType) {
        case typeCash:
          if (accType == 'cash' ||
              accType == 'cash_wallet' ||
              accType == 'cash_stash' ||
              accName == 'cash stash' ||
              accName == 'cash wallet') {
            return true;
          }
          break;
        case typeDigital:
        case 'ewallet':
          if (accType == 'digital' ||
              accType == 'digital_stash' ||
              accType == 'ewallet' ||
              accType == 'e-wallet' ||
              accType == 'gcash' ||
              accName == 'digital stash' ||
              accName == 'e-wallet' ||
              accName == 'ewallet' ||
              accName == 'gcash' ||
              accName == 'e-cash') {
            return true;
          }
          break;
        case typeBank:
          if (accType == 'bank' ||
              accType == 'bank_wallet' ||
              accType == 'bank_stash' ||
              accName == 'bank stash' ||
              accName == 'bank wallet' ||
              accName == 'main bank' ||
              accName == 'ae_bank') {
            return true;
          }
          break;
      }
    }
    return false;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

