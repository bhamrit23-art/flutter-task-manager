import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  bool get isAvailable {
    if (Firebase.apps.isEmpty) return false;
    final apiKey = Firebase.app().options.apiKey;
    return apiKey.isNotEmpty && !apiKey.contains('DemoApiKey');
  }

  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges =>
      isAvailable ? _auth.authStateChanges() : const Stream.empty();

  /// Gets the currently authenticated user
  User? get currentUser => isAvailable ? _auth.currentUser : null;

  /// Sign up a new user with Email, Password, and Full Name
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (!isAvailable) {
      throw Exception(
        'Firebase is not configured for this app yet. Add your Firebase project setup to enable authentication.',
      );
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Store user's display name using Firebase Auth updateDisplayName
      if (credential.user != null && displayName.isNotEmpty) {
        await credential.user!.updateDisplayName(displayName.trim());
        await credential.user!.reload();
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception("Authentication failed: ${e.toString()}");
    }
  }

  /// Sign in an existing user with Email and Password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!isAvailable) {
      throw Exception(
        'Firebase is not configured for this app yet. Add your Firebase project setup to enable authentication.',
      );
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception("Authentication failed: ${e.toString()}");
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    if (!isAvailable) return;

    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception(
          "Failed to sign out. Please check your network connection.");
    }
  }

  /// Maps Firebase Auth Exception codes to user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email address is already in use by another account.';
      case 'invalid-email':
        return 'The email address provided is invalid.';
      case 'weak-password':
        return 'The password provided is too weak. Please use at least 6 characters.';
      case 'user-not-found':
        return 'No user account found with this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'invalid-api-key':
      case 'app-not-authorized':
      case 'configuration-not-found':
        return 'Firebase is not connected correctly. Replace the demo values in firebase_options.dart with your real Firebase app configuration.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Authentication.';
      default:
        return e.message ?? 'An authentication error occurred (${e.code}).';
    }
  }
}
