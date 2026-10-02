import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';
import 'local_auth_service.dart';
import 'local_task_service.dart';
import 'task_service.dart';

/// The set of services the app runs on, chosen once at start-up.
class AppServices {
  const AppServices({
    required this.auth,
    required this.tasks,
    required this.preferences,
    required this.usesFirebase,
  });

  /// Firebase Authentication + Cloud Firestore.
  factory AppServices.firebase(SharedPreferences preferences) {
    return AppServices(
      auth: FirebaseAuthService(),
      tasks: FirestoreTaskService(),
      preferences: preferences,
      usesFirebase: true,
    );
  }

  /// Accounts and tasks stored on this device only.
  factory AppServices.local(SharedPreferences preferences) {
    return AppServices(
      auth: LocalAuthService(preferences),
      tasks: LocalTaskService(preferences),
      preferences: preferences,
      usesFirebase: false,
    );
  }

  final AuthService auth;
  final TaskService tasks;
  final SharedPreferences preferences;
  final bool usesFirebase;
}
