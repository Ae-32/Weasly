import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

/// Custom Exception class for returning clean, human-readable auth error messages to the UI.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Service class handling all Firebase Authentication and User Profile operations.
/// Follows architecture.md invariant: UI components never call Firebase directly.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Returns the current signed-in Firebase user.
  User? get currentUser => _auth.currentUser;

  /// Signs in a user with email and password.
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException("Sign in failed. User profile unavailable.");
      }

      return UserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException("An unexpected error occurred during sign in: ${e.toString()}");
    }
  }

  /// Registers a new user with email, password, and optional full name.
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException("Registration failed. Unable to create user.");
      }

      if (fullName != null && fullName.trim().isNotEmpty) {
        await user.updateDisplayName(fullName.trim());
      }

      final userModel = UserModel(
        id: user.uid,
        email: user.email ?? normalizedEmail,
        displayName: fullName?.trim() ?? user.displayName,
        photoUrl: user.photoURL,
      );

      // Save user profile document in Firestore under users/{userId}
      await _firestore.collection('users').doc(user.uid).set(
        userModel.toMap(),
        SetOptions(merge: true),
      );

      // Automatically send Firebase email verification link
      try {
        await user.sendEmailVerification();
      } catch (_) {
        // Handled silently so account creation still succeeds
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException("An unexpected error occurred during registration: ${e.toString()}");
    }
  }

  /// Sends a Firebase email verification link to the currently signed-in user.
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw const AuthException("No active user session found.");
      }
      if (!isEmailVerified(user)) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException("Failed to send verification email: ${e.toString()}");
    }
  }

  /// Reloads the current user's profile from Firebase Auth and returns their email verification status.
  Future<bool> checkEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      await user.reload();
      return isEmailVerified(_auth.currentUser);
    } catch (_) {
      return isEmailVerified(_auth.currentUser);
    }
  }

  /// Helper method determining if the given user has a verified email or signed in with Google.
  bool isEmailVerified(User? user) {
    if (user == null) return false;
    if (user.emailVerified) return true;
    final isGoogle = user.providerData.any((provider) => provider.providerId == 'google.com');
    return isGoogle;
  }

  /// Authenticates a user using Google Sign-In and Firebase Authentication.
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in flow
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw const AuthException("Google Sign-In failed. User profile unavailable.");
      }

      final userModel = UserModel.fromFirebaseUser(user);

      // Store/sync user profile in Firestore
      await _firestore.collection('users').doc(user.uid).set(
        userModel.toMap(),
        SetOptions(merge: true),
      );

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException("Failed to sign in with Google: ${e.toString()}");
    }
  }

  /// Signs out the current user from Firebase and Google Sign-In.
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw AuthException("Failed to sign out: ${e.toString()}");
    }
  }

  /// Helper method converting technical Firebase Auth error codes to plain-language messages.
  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return "No account found with these credentials. Please check your email and password.";
      case 'wrong-password':
        return "Incorrect password. Please try again.";
      case 'email-already-in-use':
        return "An account with this email address already exists.";
      case 'weak-password':
        return "The password is too weak. Please use at least 6 characters.";
      case 'invalid-email':
        return "Please enter a valid email address.";
      case 'user-disabled':
        return "This account has been disabled. Please contact support.";
      case 'too-many-requests':
        return "Too many failed attempts. Please wait a moment and try again.";
      case 'operation-not-allowed':
        return "Email/Password sign-in is not enabled in Firebase.";
      default:
        return e.message ?? "Authentication failed. Please try again.";
    }
  }
}
