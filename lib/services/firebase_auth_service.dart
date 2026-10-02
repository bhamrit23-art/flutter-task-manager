import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';

/// Email & password accounts backed by Firebase Authentication.
class FirebaseAuthService implements AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
    );
  }

  // userChanges (rather than authStateChanges) also fires when the profile is
  // edited, so the display name set during sign-up reaches the UI.
  @override
  Stream<AppUser?> get userChanges => _auth.userChanges().map(_toAppUser);

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final name = displayName.trim();
      if (name.isNotEmpty) {
        await credential.user?.updateDisplayName(name);
        await credential.user?.reload();
      }

      // Read the user again: the credential's copy predates the name update.
      final user = _toAppUser(_auth.currentUser ?? credential.user);
      if (user == null) {
        throw const AuthFailure(
            'Could not create your account. Please try again.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = _toAppUser(credential.user);
      if (user == null) {
        throw const AuthFailure('Could not sign you in. Please try again.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  /// Maps Firebase Auth Exception codes to user-friendly messages
  String _messageFor(FirebaseAuthException e) {
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
        return 'Firebase is not connected correctly. Check the values in firebase_options.dart.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Authentication.';
      default:
        return e.message ?? 'An authentication error occurred (${e.code}).';
    }
  }
}
