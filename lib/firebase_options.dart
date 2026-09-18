// File configured for Firebase project: flutter-project-2d595
// To re-sync or update keys via FlutterFire CLI, run:
//   flutterfire configure --project=flutter-project-2d595

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDemoApiKeyForFlutterProject2d595',
    appId: '1:100000000000:web:abcdef1234567890',
    messagingSenderId: '100000000000',
    projectId: 'flutter-project-2d595',
    authDomain: 'flutter-project-2d595.firebaseapp.com',
    storageBucket: 'flutter-project-2d595.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDemoApiKeyForFlutterProject2d595',
    appId: '1:100000000000:android:abcdef1234567890',
    messagingSenderId: '100000000000',
    projectId: 'flutter-project-2d595',
    storageBucket: 'flutter-project-2d595.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemoApiKeyForFlutterProject2d595',
    appId: '1:100000000000:ios:abcdef1234567890',
    messagingSenderId: '100000000000',
    projectId: 'flutter-project-2d595',
    storageBucket: 'flutter-project-2d595.firebasestorage.app',
    iosBundleId: 'com.example.firebaseTaskManager',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDemoApiKeyForFlutterProject2d595',
    appId: '1:100000000000:ios:abcdef1234567890',
    messagingSenderId: '100000000000',
    projectId: 'flutter-project-2d595',
    storageBucket: 'flutter-project-2d595.firebasestorage.app',
    iosBundleId: 'com.example.firebaseTaskManager',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDemoApiKeyForFlutterProject2d595',
    appId: '1:100000000000:web:abcdef1234567890',
    messagingSenderId: '100000000000',
    projectId: 'flutter-project-2d595',
    authDomain: 'flutter-project-2d595.firebaseapp.com',
    storageBucket: 'flutter-project-2d595.firebasestorage.app',
  );
}
