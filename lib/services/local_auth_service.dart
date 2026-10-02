import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

/// Accounts kept on this device, used when Firebase has not been configured.
///
/// It mirrors the Firebase behaviour (unique emails, password check, session
/// restored on restart) so the rest of the app does not need to know which
/// backend is active. Passwords are stored as salted SHA-256 hashes. This is a
/// stand-in for Firebase Auth, not a hardened credential store.
class LocalAuthService implements AuthService {
  LocalAuthService(this._prefs) {
    _current = _restoreSession();
  }

  static const _accountsKey = 'local_accounts';
  static const _sessionKey = 'local_session';

  final SharedPreferences _prefs;
  final _changes = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  @override
  Stream<AppUser?> get userChanges {
    late final StreamController<AppUser?> controller;
    StreamSubscription<AppUser?>? subscription;
    controller = StreamController<AppUser?>(
      onListen: () {
        controller.add(_current);
        subscription = _changes.stream.listen(controller.add);
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final key = _normalise(email);
    final accounts = _readAccounts();
    if (accounts.containsKey(key)) {
      throw const AuthFailure(
        'This email address is already in use by another account.',
      );
    }

    final salt = _newSalt();
    final uid = 'local-${DateTime.now().microsecondsSinceEpoch}';
    accounts[key] = {
      'uid': uid,
      'displayName': displayName.trim(),
      'salt': salt,
      'hash': _hash(password, salt),
    };
    await _prefs.setString(_accountsKey, jsonEncode(accounts));

    final user = AppUser(uid: uid, email: key, displayName: displayName.trim());
    await _setSession(user);
    return user;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final key = _normalise(email);
    final account = _readAccounts()[key];
    if (account is! Map<String, dynamic> ||
        account['hash'] != _hash(password, account['salt'] as String? ?? '')) {
      throw const AuthFailure('Incorrect email or password. Please try again.');
    }

    final user = _userFrom(key, account);
    await _setSession(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await _prefs.remove(_sessionKey);
    _current = null;
    _changes.add(null);
  }

  Future<void> _setSession(AppUser user) async {
    await _prefs.setString(_sessionKey, user.email);
    _current = user;
    _changes.add(user);
  }

  AppUser? _restoreSession() {
    final email = _prefs.getString(_sessionKey);
    if (email == null) return null;
    final account = _readAccounts()[email];
    return account is Map<String, dynamic> ? _userFrom(email, account) : null;
  }

  AppUser _userFrom(String email, Map<String, dynamic> account) {
    return AppUser(
      uid: account['uid'] as String? ?? '',
      email: email,
      displayName: account['displayName'] as String? ?? '',
    );
  }

  Map<String, dynamic> _readAccounts() {
    final raw = _prefs.getString(_accountsKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } on FormatException {
      return {};
    }
  }

  String _normalise(String email) => email.trim().toLowerCase();

  String _newSalt() {
    final random = Random.secure();
    return base64Url.encode(List.generate(16, (_) => random.nextInt(256)));
  }

  String _hash(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }
}
