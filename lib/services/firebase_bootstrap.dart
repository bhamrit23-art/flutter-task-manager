import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Connects the app to Firebase when a real project has been configured.
///
/// `firebase_options.dart` ships with placeholder keys. Until they are replaced
/// (run `flutterfire configure`), the app falls back to on-device storage so it
/// can still be run and demonstrated.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  /// Returns true when Firebase was initialised and can be used.
  static Future<bool> init() async {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      if (_isPlaceholder(options)) return false;
      await Firebase.initializeApp(options: options);
      return true;
    } catch (error) {
      debugPrint('Firebase unavailable, using on-device storage: $error');
      return false;
    }
  }

  static bool _isPlaceholder(FirebaseOptions options) {
    return options.apiKey.isEmpty || options.apiKey.contains('DemoApiKey');
  }
}
