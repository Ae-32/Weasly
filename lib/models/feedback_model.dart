import 'package:cloud_firestore/cloud_firestore.dart';

/// Feedback category options.
enum FeedbackCategory {
  general,
  featureRequest,
  bugReport,
  other;

  String toMap() => name;

  static FeedbackCategory fromString(String value) {
    switch (value) {
      case 'featureRequest':
        return FeedbackCategory.featureRequest;
      case 'bugReport':
        return FeedbackCategory.bugReport;
      case 'other':
        return FeedbackCategory.other;
      case 'general':
      default:
        return FeedbackCategory.general;
    }
  }

  String get displayName {
    switch (this) {
      case FeedbackCategory.general:
        return 'General Feedback';
      case FeedbackCategory.featureRequest:
        return 'Feature Request';
      case FeedbackCategory.bugReport:
        return 'Bug Report';
      case FeedbackCategory.other:
        return 'Other';
    }
  }
}

/// Data model representing a user submitted feedback entry.
class FeedbackModel {
  final String id;
  final String userId;
  final String userEmail;
  final FeedbackCategory category;
  final int rating; // 1 to 5 stars
  final String message;
  final String appVersion;
  final DateTime createdAt;

  const FeedbackModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.category,
    required this.rating,
    required this.message,
    this.appVersion = '1.0.0+1',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'category': category.toMap(),
      'rating': rating,
      'message': message,
      'appVersion': appVersion,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return FeedbackModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      userEmail: map['userEmail'] as String? ?? '',
      category: FeedbackCategory.fromString(map['category'] as String? ?? 'general'),
      rating: (map['rating'] as num?)?.toInt() ?? 5,
      message: map['message'] as String? ?? '',
      appVersion: map['appVersion'] as String? ?? '1.0.0+1',
      createdAt: parseDate(map['createdAt']),
    );
  }

  FeedbackModel copyWith({
    String? id,
    String? userId,
    String? userEmail,
    FeedbackCategory? category,
    int? rating,
    String? message,
    String? appVersion,
    DateTime? createdAt,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      message: message ?? this.message,
      appVersion: appVersion ?? this.appVersion,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
