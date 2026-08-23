import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Data model representing a signed-in user profile in Weasly.
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  /// Factory constructor to convert a Firebase User object to UserModel.
  factory UserModel.fromFirebaseUser(fb.User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  /// Converts UserModel to a Map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }

  /// Factory constructor to create UserModel from Firestore document map.
  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
    );
  }
}
