import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';

export '../services/auth_service.dart' show AppUser;

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService) {
    _authSubscription = _authService.userChanges.listen(
      _onUserChanged,
      onError: (Object _) => _onUserChanged(null),
    );
  }

  final AuthService _authService;

  AppUser? _user;
  bool _isReady = false;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<AppUser?>? _authSubscription;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;

  /// False until the saved session has been checked, so the app can show a
  /// splash instead of flashing the login screen at a signed-in user.
  bool get isReady => _isReady;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _onUserChanged(AppUser? user) {
    if (_isReady && user == _user) return;
    _user = user;
    _isReady = true;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Registration logic
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _authenticate(
      () => _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  /// Sign In logic
  Future<bool> signIn({
    required String email,
    required String password,
  }) {
    return _authenticate(
      () => _authService.signIn(email: email, password: password),
    );
  }

  Future<bool> _authenticate(Future<AppUser> Function() request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await request();
      _isReady = true;
      return true;
    } on AuthFailure catch (failure) {
      _errorMessage = failure.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign Out logic
  Future<void> signOut() async {
    // Clear the user first so listeners (the live task list) detach before the
    // backend session ends, instead of seeing a permission error from it.
    final previousUser = _user;
    _user = null;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signOut();
    } on AuthFailure catch (failure) {
      _user = previousUser;
      _errorMessage = failure.message;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
