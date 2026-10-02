/// The signed-in user, independent of where accounts are stored.
class AppUser {
  final String uid;
  final String email;
  final String displayName;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  @override
  bool operator ==(Object other) {
    return other is AppUser &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName;
  }

  @override
  int get hashCode => Object.hash(uid, email, displayName);
}

/// Thrown by an [AuthService] with a message that is safe to show to the user.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Account operations. Implemented by Firebase Auth and by on-device storage.
abstract class AuthService {
  /// Emits the current user as soon as it is listened to, then every change.
  Stream<AppUser?> get userChanges;

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
