# Task Manager (`firebase_task_manager`)

A minimal, responsive task manager built with Flutter for a university assignment. It uses **Firebase Authentication**, **Cloud Firestore**, **Provider** state management, and a light / dark theme.

Based on [Flutter-TODO_app](https://github.com/Bibek-Bhandari999/Flutter-TODO_app) by Bibek Bhandari. See [What changed](#what-changed-from-the-original) for what this version adds.

---

## Features

1. **Accounts (email & password)**
   - Sign up with full name, email, password and confirmation, all validated.
   - Sign in with clear error messages (wrong password, unknown account, email already in use).
   - The session is restored when the app restarts.
2. **Tasks (CRUD)**
   - **Create** a task with a title, optional description, priority and optional due date.
   - **Read** a live list that updates in real time.
   - **Update** any field from the edit screen.
   - **Delete** with a confirmation dialog, by menu or by swiping the card left, then **Undo** from the message that appears.
   - **Complete** a task with one tap.
3. **Staying organised**
   - Priorities (low / medium / high) and due dates, with overdue tasks highlighted.
   - Filter by All / Active / Done, with a count on each.
   - Search titles and descriptions.
   - Sort by newest, due date or priority.
   - A progress bar showing how much is done.
   - Clear all completed tasks from Settings.
4. **Appearance**
   - Light, dark, or follow-the-system theme. The choice is remembered.
   - Responsive: a single column on phones, a centred column with the main action in the header on tablets and desktops.
5. **Two storage modes behind one interface**
   - **Cloud**: Firebase Authentication + Cloud Firestore, used when a Firebase project is configured.
   - **Local**: accounts and tasks saved on the device, used automatically until then, so the app always runs.

---

## Running the app

Prerequisite: the [Flutter SDK](https://docs.flutter.dev/get-started/install). Developed and tested on Flutter 3.47 (stable).

```bash
flutter pub get
```

```bash
flutter run -d chrome
```

Use `flutter run` on its own to pick an Android emulator or connected phone instead.

Out of the box the app runs in **local mode** (a small note on the sign-in screen says so). To store data in Firebase, follow the next section.

---

## Connecting Firebase

`lib/firebase_options.dart` contains placeholder keys. Replace them with your own project's:

1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. **Authentication** → Sign-in method → enable **Email/Password**.
3. **Firestore Database** → Create database, then set these rules so each user can only reach their own tasks:

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

4. Generate the configuration file:

   ```bash
   dart pub global activate flutterfire_cli
   ```

   ```bash
   flutterfire configure
   ```

Run the app again. The local-mode note disappears, Settings shows **Cloud sync**, and tasks are stored at `users/{uid}/tasks/{taskId}`.

---

## Project structure

```
lib/
├── main.dart                        # Entry point, providers, auth gate
├── firebase_options.dart            # Firebase configuration (placeholders until configured)
├── models/
│   └── task_model.dart              # Task + priority; Firestore and JSON conversion
├── services/
│   ├── auth_service.dart            # AuthService interface, AppUser, AuthFailure
│   ├── firebase_auth_service.dart   # Firebase Authentication implementation
│   ├── local_auth_service.dart      # On-device implementation
│   ├── task_service.dart            # TaskService interface, TaskFailure
│   ├── firestore_service.dart       # Cloud Firestore implementation
│   ├── local_task_service.dart      # On-device implementation
│   ├── firebase_bootstrap.dart      # Initialises Firebase when it is configured
│   └── app_services.dart            # Picks cloud or local services at start-up
├── providers/
│   ├── auth_provider.dart           # Signed-in user, sign in / up / out
│   ├── task_provider.dart           # Task list, filter, search, sort, CRUD
│   └── theme_provider.dart          # Theme mode, saved between runs
├── theme/
│   └── app_theme.dart               # Light and dark themes
├── screens/
│   ├── auth/                        # login_screen.dart, signup_screen.dart
│   ├── home/home_screen.dart        # Task list with progress, search, filter, sort
│   ├── task/                        # task_form_screen.dart (add + edit), task_actions.dart
│   └── settings/settings_screen.dart
├── widgets/                         # task_card, auth_layout, empty_state, dialogs, ...
└── utils/                           # formatters.dart, validators.dart
test/
├── task_provider_test.dart          # Logic: filtering, sorting, CRUD, model, validators
└── widget_test.dart                 # Full user journeys through the UI
```

---

## Architecture

```
Screen (UI)
   ↓
AuthProvider / TaskProvider / ThemeProvider   (state, Provider)
   ↓
AuthService / TaskService                      (interfaces)
   ↓                         ↓
Firebase Auth + Firestore    On-device storage
```

- Screens never talk to Firebase directly; they only use providers.
- Providers hold state and turn failures into messages for the UI.
- Services hide where data lives. Each has a Firebase and a local implementation, and `AppServices` chooses one set at start-up.
- `TaskProvider` follows `AuthProvider`, so the task list always belongs to the signed-in user and is cleared on sign-out.

---

## Tests

```bash
flutter test
```

30 tests cover the task logic (filter, search, sort, add / edit / delete / undo, clear completed), the data model, form validation, and complete journeys through the UI: sign up, sign in, wrong password, duplicate email, separate data per account, persistence across restarts, theme switching, swipe to delete, and layout at five screen sizes from a small phone to a desktop.

---

## What changed from the original

- **Firebase is actually initialised** when configured. The original never called `Firebase.initializeApp`, so it always ran from memory and lost everything on restart.
- **Data persists in local mode**, with real account checks (the original accepted any email and password).
- **New features**: priority, due dates, search, filter, sort, progress, swipe to delete, undo, clear completed, system theme, remembered theme.
- **Redesigned UI**: a quieter monochrome look, and layouts that adapt to phone, tablet and desktop.
- **Fixes**: email validation that rejected valid addresses (such as `name+tag@gmail.com`), a sign-out that used a disposed screen, and a display name that could be empty right after sign-up.
- **Cleaner repository**: build caches, IDE folders and an unrelated native Android template were removed.
- **Automated tests** added.
