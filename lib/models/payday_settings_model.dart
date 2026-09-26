import 'package:cloud_firestore/cloud_firestore.dart';

/// Recurrence options for manual Payday Setup.
enum PaydayFrequency {
  weekly,
  biWeekly,
  semiMonthly,
  monthly,
  custom;

  String toMap() => name;

  static PaydayFrequency fromString(String value) {
    switch (value) {
      case 'weekly':
        return PaydayFrequency.weekly;
      case 'biWeekly':
        return PaydayFrequency.biWeekly;
      case 'semiMonthly':
        return PaydayFrequency.semiMonthly;
      case 'monthly':
        return PaydayFrequency.monthly;
      case 'custom':
      default:
        return PaydayFrequency.custom;
    }
  }

  String get displayName {
    switch (this) {
      case PaydayFrequency.weekly:
        return 'Weekly';
      case PaydayFrequency.biWeekly:
        return 'Bi-weekly (Every 2 weeks)';
      case PaydayFrequency.semiMonthly:
        return 'Semi-monthly (Twice a month)';
      case PaydayFrequency.monthly:
        return 'Monthly (Once a month)';
      case PaydayFrequency.custom:
        return 'Custom (Manual date each time)';
    }
  }
}

/// Data model representing user-configured payday preferences.
class PaydaySettingsModel {
  final PaydayFrequency frequency;
  final DateTime nextPaydayDate;
  final double expectedAmount;
  final String? linkedAccountId;
  final String? linkedAccountName;
  final int? semiMonthlyDay1; // e.g. 15
  final int? semiMonthlyDay2; // e.g. 30
  final int? monthlyDay; // e.g. 15 or 30
  final DateTime? lastConfirmedPaydayDate;
  final DateTime? lastDismissedPaydayDate;
  final DateTime? updatedAt;

  const PaydaySettingsModel({
    required this.frequency,
    required this.nextPaydayDate,
    this.expectedAmount = 0.0,
    this.linkedAccountId,
    this.linkedAccountName,
    this.semiMonthlyDay1,
    this.semiMonthlyDay2,
    this.monthlyDay,
    this.lastConfirmedPaydayDate,
    this.lastDismissedPaydayDate,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency.toMap(),
      'nextPaydayDate': Timestamp.fromDate(nextPaydayDate),
      'expectedAmount': expectedAmount,
      'linkedAccountId': linkedAccountId,
      'linkedAccountName': linkedAccountName,
      'semiMonthlyDay1': semiMonthlyDay1,
      'semiMonthlyDay2': semiMonthlyDay2,
      'monthlyDay': monthlyDay,
      'lastConfirmedPaydayDate': lastConfirmedPaydayDate != null
          ? Timestamp.fromDate(lastConfirmedPaydayDate!)
          : null,
      'lastDismissedPaydayDate': lastDismissedPaydayDate != null
          ? Timestamp.fromDate(lastDismissedPaydayDate!)
          : null,
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory PaydaySettingsModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate = DateTime.now();
    if (map['nextPaydayDate'] is Timestamp) {
      parsedDate = (map['nextPaydayDate'] as Timestamp).toDate();
    } else if (map['nextPaydayDate'] is String) {
      parsedDate = DateTime.tryParse(map['nextPaydayDate']) ?? DateTime.now();
    }

    DateTime? parsedLastConfirmed;
    if (map['lastConfirmedPaydayDate'] is Timestamp) {
      parsedLastConfirmed = (map['lastConfirmedPaydayDate'] as Timestamp).toDate();
    }

    DateTime? parsedLastDismissed;
    if (map['lastDismissedPaydayDate'] is Timestamp) {
      parsedLastDismissed = (map['lastDismissedPaydayDate'] as Timestamp).toDate();
    }

    DateTime? parsedUpdatedAt;
    if (map['updatedAt'] is Timestamp) {
      parsedUpdatedAt = (map['updatedAt'] as Timestamp).toDate();
    }

    return PaydaySettingsModel(
      frequency: PaydayFrequency.fromString(map['frequency'] ?? 'custom'),
      nextPaydayDate: parsedDate,
      expectedAmount: (map['expectedAmount'] as num?)?.toDouble() ?? 0.0,
      linkedAccountId: map['linkedAccountId'],
      linkedAccountName: map['linkedAccountName'],
      semiMonthlyDay1: (map['semiMonthlyDay1'] as num?)?.toInt(),
      semiMonthlyDay2: (map['semiMonthlyDay2'] as num?)?.toInt(),
      monthlyDay: (map['monthlyDay'] as num?)?.toInt(),
      lastConfirmedPaydayDate: parsedLastConfirmed,
      lastDismissedPaydayDate: parsedLastDismissed,
      updatedAt: parsedUpdatedAt,
    );
  }

  /// Calculates the next upcoming payday date on or after reference date.
  DateTime calculateNextUpcomingPayday([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var target = DateTime(nextPaydayDate.year, nextPaydayDate.month, nextPaydayDate.day);

    switch (frequency) {
      case PaydayFrequency.weekly:
        while (target.isBefore(today)) {
          target = target.add(const Duration(days: 7));
        }
        return target;

      case PaydayFrequency.biWeekly:
        while (target.isBefore(today)) {
          target = target.add(const Duration(days: 14));
        }
        return target;

      case PaydayFrequency.semiMonthly:
        int rawD1 = semiMonthlyDay1 ?? 15;
        int rawD2 = semiMonthlyDay2 ?? 30;
        final d1 = rawD1 < rawD2 ? rawD1 : rawD2;
        final d2 = rawD1 < rawD2 ? rawD2 : rawD1;

        int year = today.year;
        int month = today.month;

        for (int i = 0; i < 24; i++) {
          final lastDayOfM = DateTime(year, month + 1, 0).day;
          final targetDay1 = d1 > lastDayOfM ? lastDayOfM : d1;
          final targetDay2 = d2 > lastDayOfM ? lastDayOfM : d2;

          final candidate1 = DateTime(year, month, targetDay1);
          final candidate2 = DateTime(year, month, targetDay2);

          if (!candidate1.isBefore(today)) return candidate1;
          if (!candidate2.isBefore(today)) return candidate2;

          month++;
          if (month > 12) {
            month = 1;
            year++;
          }
        }
        return target;

      case PaydayFrequency.monthly:
        final d = monthlyDay ?? nextPaydayDate.day;
        int year = today.year;
        int month = today.month;

        for (int i = 0; i < 24; i++) {
          final lastDayOfM = DateTime(year, month + 1, 0).day;
          final targetDay = d > lastDayOfM ? lastDayOfM : d;
          final candidate = DateTime(year, month, targetDay);

          if (!candidate.isBefore(today)) return candidate;

          month++;
          if (month > 12) {
            month = 1;
            year++;
          }
        }
        return target;

      case PaydayFrequency.custom:
        return target;
    }
  }

  PaydaySettingsModel copyWith({
    PaydayFrequency? frequency,
    DateTime? nextPaydayDate,
    double? expectedAmount,
    String? linkedAccountId,
    String? linkedAccountName,
    int? semiMonthlyDay1,
    int? semiMonthlyDay2,
    int? monthlyDay,
    DateTime? lastConfirmedPaydayDate,
    DateTime? lastDismissedPaydayDate,
    DateTime? updatedAt,
  }) {
    return PaydaySettingsModel(
      frequency: frequency ?? this.frequency,
      nextPaydayDate: nextPaydayDate ?? this.nextPaydayDate,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      linkedAccountId: linkedAccountId ?? this.linkedAccountId,
      linkedAccountName: linkedAccountName ?? this.linkedAccountName,
      semiMonthlyDay1: semiMonthlyDay1 ?? this.semiMonthlyDay1,
      semiMonthlyDay2: semiMonthlyDay2 ?? this.semiMonthlyDay2,
      monthlyDay: monthlyDay ?? this.monthlyDay,
      lastConfirmedPaydayDate: lastConfirmedPaydayDate ?? this.lastConfirmedPaydayDate,
      lastDismissedPaydayDate: lastDismissedPaydayDate ?? this.lastDismissedPaydayDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

