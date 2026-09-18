import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Weasly/models/feedback_model.dart';

void main() {
  group('FeedbackModel Tests', () {
    final now = DateTime(2026, 9, 17, 12, 0, 0);

    test('FeedbackCategory fromString and displayName', () {
      expect(FeedbackCategory.fromString('general'), FeedbackCategory.general);
      expect(FeedbackCategory.fromString('featureRequest'), FeedbackCategory.featureRequest);
      expect(FeedbackCategory.fromString('bugReport'), FeedbackCategory.bugReport);
      expect(FeedbackCategory.fromString('other'), FeedbackCategory.other);
      expect(FeedbackCategory.fromString('unknown'), FeedbackCategory.general);

      expect(FeedbackCategory.general.displayName, 'General Feedback');
      expect(FeedbackCategory.featureRequest.displayName, 'Feature Request');
      expect(FeedbackCategory.bugReport.displayName, 'Bug Report');
      expect(FeedbackCategory.other.displayName, 'Other');
    });

    test('toMap converts FeedbackModel to Map correctly', () {
      final feedback = FeedbackModel(
        id: 'fb_123',
        userId: 'user_456',
        userEmail: 'test@example.com',
        category: FeedbackCategory.featureRequest,
        rating: 5,
        message: 'Great app! Please add dark mode.',
        appVersion: '1.0.0+1',
        createdAt: now,
      );

      final map = feedback.toMap();

      expect(map['id'], 'fb_123');
      expect(map['userId'], 'user_456');
      expect(map['userEmail'], 'test@example.com');
      expect(map['category'], 'featureRequest');
      expect(map['rating'], 5);
      expect(map['message'], 'Great app! Please add dark mode.');
      expect(map['appVersion'], '1.0.0+1');
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('fromMap creates FeedbackModel from Map correctly', () {
      final map = {
        'userId': 'user_789',
        'userEmail': 'dev@example.com',
        'category': 'bugReport',
        'rating': 4,
        'message': 'Minor chart display glitch.',
        'appVersion': '1.0.0+1',
        'createdAt': Timestamp.fromDate(now),
      };

      final feedback = FeedbackModel.fromMap(map, 'fb_999');

      expect(feedback.id, 'fb_999');
      expect(feedback.userId, 'user_789');
      expect(feedback.userEmail, 'dev@example.com');
      expect(feedback.category, FeedbackCategory.bugReport);
      expect(feedback.rating, 4);
      expect(feedback.message, 'Minor chart display glitch.');
      expect(feedback.appVersion, '1.0.0+1');
      expect(feedback.createdAt, now);
    });

    test('copyWith produces updated FeedbackModel', () {
      final initial = FeedbackModel(
        id: 'fb_1',
        userId: 'u_1',
        userEmail: 'a@b.com',
        category: FeedbackCategory.general,
        rating: 3,
        message: 'Hello',
        createdAt: now,
      );

      final updated = initial.copyWith(
        rating: 5,
        message: 'Hello updated',
      );

      expect(updated.id, 'fb_1');
      expect(updated.rating, 5);
      expect(updated.message, 'Hello updated');
      expect(updated.category, FeedbackCategory.general);
    });
  });
}
