import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
  });
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _user;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _user = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
      );
    }

    if (_authService.isAvailable) {
      _authSubscription = _authService.authStateChanges.listen((User? newUser) {
        _user = newUser == null
            ? null
            : AppUser(
                uid: newUser.uid,
                email: newUser.email ?? '',
                displayName: newUser.displayName ?? '',
              );
        notifyListeners();
      });
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Registration logic
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    _setError(null);

    if (!_authService.isAvailable) {
      _user = AppUser(
        uid: 'local-demo-user',
        email: email.trim(),
        displayName: displayName.trim(),
      );
      _setLoading(false);
      return true;
    }

    try {
      final credential = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      final firebaseUser = credential.user;
      _user = firebaseUser == null
          ? null
          : AppUser(
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              displayName: firebaseUser.displayName ?? '',
            );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll("Exception: ", ""));
      _setLoading(false);
      return false;
    }
  }

  /// Sign In logic
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    if (!_authService.isAvailable) {
      _user = AppUser(
        uid: 'local-demo-user',
        email: email.trim(),
        displayName: 'Task Manager User',
      );
      _setLoading(false);
      return true;
    }

    try {
      final credential = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      _user = firebaseUser == null
          ? null
          : AppUser(
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              displayName: firebaseUser.displayName ?? '',
            );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll("Exception: ", ""));
      _setLoading(false);
      return false;
    }
  }

  /// Sign Out logic
  Future<void> signOut() async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.signOut();
      _user = null;
    } catch (e) {
      _setError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
