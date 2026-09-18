# Firebase Task Manager (`firebase_task_manager`)

A complete, production-ready Flutter application built for a university assignment. The app provides a full task management solution powered by **Firebase Authentication**, **Cloud Firestore**, **Provider** state management, and custom **Light/Dark theme switching**.

---

## 📌 Features & Highlights

1. **Firebase Authentication (Email & Password)**:
   - User Sign-Up with Full Name, Email, Password validation & confirmation.
   - User Sign-In with validation & comprehensive Firebase error handling.
   - Display name persistence on Firebase user profile.
   - Secure Sign-Out functionality.
2. **Persistent Authentication State**:
   - Listens to `FirebaseAuth.instance.authStateChanges()`.
   - Automatically maintains logged-in state across app restarts.
   - Restricts unauthenticated access to home & task screens.
3. **Cloud Firestore Real-time Database**:
   - Structured per user UID: `users/{uid}/tasks/{taskId}`.
   - Isolated tasks: users only see their own tasks.
   - Real-time updates via Firestore snapshots (`Stream<List<TaskModel>>`).
4. **Task Operations (CRUD)**:
   - **Create**: Add new task with title and description.
   - **Read**: Live real-time stream of user tasks ordered by creation date.
   - **Update**: Edit title and description with pre-populated form.
   - **Delete**: Confirmation dialog (`AlertDialog`) before deletion.
   - **Toggle Completion**: Instant checkbox toggle with visual strikethrough & styling.
5. **Dynamic Light / Dark Theme Switching**:
   - Custom Indigo & Slate ThemeData defined in `AppTheme`.
   - Global reactive theme toggle accessible from AppBar and Settings screen.
6. **Clean Architecture**:
   - Clear separation into Models, Services, Providers, Screens, Widgets, and Theme.

---

## 📁 Project Structure

```
firebase_task_manager/
├── lib/
│   ├── models/
│   │   └── task_model.dart            # Data model with fromFirestore, toFirestore, copyWith
│   ├── services/
│   │   ├── auth_service.dart          # Firebase Auth operations & error mapping
│   │   └── firestore_service.dart     # Cloud Firestore database CRUD operations
│   ├── providers/
│   │   ├── auth_provider.dart         # Auth state management ChangeNotifier
│   │   ├── task_provider.dart         # Task stream & CRUD state management
│   │   └── theme_provider.dart        # Light/Dark theme switching ChangeNotifier
│   ├── theme/
│   │   ├── app_theme.dart             # Custom Light & Dark ThemeData configurations
│   │   └── theme_provider.dart        # Re-export of ThemeProvider for structural compatibility
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart      # Email/Password sign-in screen
│   │   │   └── signup_screen.dart     # Registration screen with validation
│   │   ├── home/
│   │   │   └── home_screen.dart       # Real-time task dashboard with FAB
│   │   ├── task/
│   │   │   ├── add_task_screen.dart   # Task creation screen
│   │   │   └── edit_task_screen.dart  # Task editing screen
│   │   └── settings/
│   │       └── settings_screen.dart   # Profile info, dark mode switch, sign out
│   ├── widgets/
│   │   ├── task_card.dart             # Reusable card widget for task items
│   │   ├── loading_widget.dart        # Reusable progress indicator widget
│   │   └── error_message.dart         # Reusable error banner widget
│   ├── firebase_options.dart          # Platform configuration options
│   └── main.dart                      # App entry point & MultiProvider initialization
├── pubspec.yaml                       # Dependencies configuration
└── README.md                          # Comprehensive documentation
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.5.0 or higher)
- [Dart SDK](https://dart.dev/get-dart)
- An active [Firebase Project](https://console.firebase.google.com/)

---

### 🛠 Setup & Firebase Configuration

1. **Clone or navigate to the project root**:
   ```bash
   cd firebase_task_manager
   ```

2. **Install Flutter packages**:
   ```bash
   flutter pub get
   ```

3. **Configure your Firebase Project**:
   - Install the FlutterFire CLI:
     ```bash
     dart pub global activate flutterfire_cli
     ```
   - Run the configuration command to generate your project's specific `firebase_options.dart`:
     ```bash
     flutterfire configure
     ```
   - In your [Firebase Console](https://console.firebase.google.com/):
     - **Authentication**: Enable **Email/Password** sign-in method under Auth -> Sign-in method.
     - **Cloud Firestore**: Create a Firestore database in test or production mode with rules allowing user-authenticated access under `users/{uid}/tasks`.

#### Example Firestore Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/tasks/{taskId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 🏃 Running the App

Run the application using:

```bash
flutter run
```

To run specifically on Web / Mobile / Desktop:
```bash
flutter run -d chrome
```

---

## 🔐 Architecture Overview

```
Screen (UI Layer)
   ↓
TaskProvider / AuthProvider (State Management - Provider)
   ↓
FirestoreService / AuthService (Data Layer)
   ↓
Cloud Firestore / Firebase Auth (Remote Backend)
```

- **UI Components** never interact directly with Firebase services.
- **Providers** manage loading states, error handling, and business logic.
- **Services** isolate external SDK dependencies.
