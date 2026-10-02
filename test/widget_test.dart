// End-to-end widget tests for the main user journeys, run against the
// on-device services so no Firebase project is needed.

import 'package:firebase_task_manager/main.dart';
import 'package:firebase_task_manager/services/app_services.dart';
import 'package:firebase_task_manager/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester) async {
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    FirebaseTaskManagerApp(services: AppServices.local(preferences)),
  );
  await tester.pumpAndSettle();
}

Finder fieldWithLabel(String label) =>
    find.widgetWithText(TextFormField, label);

Future<void> signUp(
  WidgetTester tester, {
  String name = 'Amrit Bhandari',
  String email = 'amrit@example.com',
  String password = 'secret123',
}) async {
  await tester.tap(find.text('Create one'));
  await tester.pumpAndSettle();

  await tester.enterText(fieldWithLabel('Full name'), name);
  await tester.enterText(fieldWithLabel('Email'), email);
  await tester.enterText(fieldWithLabel('Password'), password);
  await tester.enterText(fieldWithLabel('Confirm password'), password);
  await tester.ensureVisible(find.text('Create account'));
  await tester.tap(find.text('Create account'));
  await tester.pumpAndSettle();
}

Future<void> addTask(WidgetTester tester, String title) async {
  await tester.tap(find.text('New task').first);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextFormField, 'What needs to be done?'),
    title,
  );
  await tester.ensureVisible(find.text('Add task'));
  await tester.tap(find.text('Add task'));
  await tester.pumpAndSettle();
}

Future<void> signOut(WidgetTester tester) async {
  // Let any "Task added" message time out so it is not covering the screen.
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();

  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Sign out'));
  await tester.tap(find.text('Sign out'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the sign-in screen when signed out', (tester) async {
    await pumpApp(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('validates the sign-in form', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter your email address'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);

    await tester.enterText(fieldWithLabel('Email'), 'not-an-email');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a valid email address'), findsOneWidget);
  });

  testWidgets('rejects sign-in for an unknown account', (tester) async {
    await pumpApp(tester);

    await tester.enterText(fieldWithLabel('Email'), 'nobody@example.com');
    await tester.enterText(fieldWithLabel('Password'), 'whatever');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(
      find.text('Incorrect email or password. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('My Tasks'), findsNothing);
  });

  testWidgets('sign up, add, complete and delete a task', (tester) async {
    await pumpApp(tester);
    await signUp(tester);

    expect(find.text('My Tasks'), findsOneWidget);
    expect(find.textContaining('Amrit'), findsOneWidget);
    expect(find.text('No tasks yet'), findsOneWidget);

    await addTask(tester, 'Write the report');
    expect(find.text('Write the report'), findsOneWidget);
    expect(find.text('0 of 1 completed'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('All done. Nice work!'), findsOneWidget);

    await tester.tap(find.byTooltip('Task options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete task?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Write the report'), findsNothing);
    expect(find.text('No tasks yet'), findsOneWidget);

    // Undo brings the task back, still completed.
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Write the report'), findsOneWidget);
    expect(find.text('All done. Nice work!'), findsOneWidget);
  });

  testWidgets('swiping a task asks before deleting it', (tester) async {
    await pumpApp(tester);
    await signUp(tester);
    await addTask(tester, 'Swipe me');

    // Cancelling keeps the task.
    await tester.drag(find.text('Swipe me'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Delete task?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Swipe me'), findsOneWidget);

    // Confirming removes it.
    await tester.drag(find.text('Swipe me'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Swipe me'), findsNothing);
    expect(find.text('No tasks yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out without overflow from small phones to desktops',
      (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;

    Future<void> checkEachSize(String screen) async {
      for (final size in const [
        Size(320, 568), // small phone
        Size(412, 915), // large phone
        Size(700, 400), // phone in landscape
        Size(834, 1112), // tablet
        Size(1440, 900), // desktop
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$screen at $size');
      }
    }

    await pumpApp(tester);
    await checkEachSize('sign-in');

    tester.view.physicalSize = const Size(412, 915);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create one'));
    await tester.pumpAndSettle();
    await checkEachSize('sign-up');
    tester.view.physicalSize = const Size(412, 915);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await signUp(tester, name: 'Someone With A Really Long Display Name');
    await checkEachSize('empty home');

    tester.view.physicalSize = const Size(412, 915);
    await tester.pumpAndSettle();
    await addTask(
      tester,
      'A very long task title that should wrap or truncate instead of '
      'overflowing the card on a narrow screen',
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await checkEachSize('home with tasks');

    tester.view.physicalSize = const Size(412, 915);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Task options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await checkEachSize('task form');

    tester.view.physicalSize = const Size(412, 915);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await checkEachSize('settings');
  });

  testWidgets('filters and searches the task list', (tester) async {
    await pumpApp(tester);
    await signUp(tester);
    await addTask(tester, 'Buy milk');
    await addTask(tester, 'Call the bank');

    // Newest first: "Call the bank" is on top. Complete it.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.text('1 of 2 completed'), findsOneWidget);

    await tester.tap(find.text('Active  1'));
    await tester.pumpAndSettle();
    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('Call the bank'), findsNothing);

    await tester.tap(find.text('Done  1'));
    await tester.pumpAndSettle();
    expect(find.text('Buy milk'), findsNothing);
    expect(find.text('Call the bank'), findsOneWidget);

    await tester.tap(find.text('All  2'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Search tasks'), 'milk');
    await tester.pumpAndSettle();
    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('Call the bank'), findsNothing);

    await tester.enterText(
        find.widgetWithText(TextField, 'Search tasks'), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Nothing here'), findsOneWidget);

    await tester.tap(find.text('Show all tasks'));
    await tester.pumpAndSettle();
    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('Call the bank'), findsOneWidget);
  });

  testWidgets('edits an existing task', (tester) async {
    await pumpApp(tester);
    await signUp(tester);
    await addTask(tester, 'Draft');

    await tester.tap(find.text('Draft'));
    await tester.pumpAndSettle();
    expect(find.text('Edit task'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Draft'), 'Final');
    await tester.tap(find.text('High'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Final'), findsOneWidget);
    expect(find.text('Draft'), findsNothing);
    expect(find.text('High'), findsOneWidget);
  });

  testWidgets('tasks and session survive an app restart', (tester) async {
    await pumpApp(tester);
    await signUp(tester);
    await addTask(tester, 'Remember me');

    // A fresh widget tree over the same stored preferences is a restart.
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester);

    expect(find.text('My Tasks'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
  });

  testWidgets('signing out returns to sign-in and keeps accounts separate',
      (tester) async {
    await pumpApp(tester);
    await signUp(tester);
    await addTask(tester, 'Private task');
    await signOut(tester);

    expect(find.text('Welcome back'), findsOneWidget);

    // A second account must not see the first account's tasks.
    await signUp(tester, name: 'Second User', email: 'second@example.com');
    expect(find.text('No tasks yet'), findsOneWidget);
    expect(find.text('Private task'), findsNothing);
    await signOut(tester);

    // The wrong password is rejected, the right one restores the tasks.
    await tester.enterText(fieldWithLabel('Email'), 'amrit@example.com');
    await tester.enterText(fieldWithLabel('Password'), 'wrong-password');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(
      find.text('Incorrect email or password. Please try again.'),
      findsOneWidget,
    );

    await tester.enterText(fieldWithLabel('Password'), 'secret123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Private task'), findsOneWidget);
  });

  testWidgets('theme changed in Settings reaches the home screen underneath',
      (tester) async {
    await pumpApp(tester);
    await signUp(tester);
    await addTask(tester, 'Any task');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Dark mode'), findsOneWidget);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // The home header must have been rebuilt with the dark theme even though
    // it was covered by the Settings screen when the theme changed.
    expect(find.byTooltip('Light mode'), findsOneWidget);
    final title = tester.widget<Text>(find.text('My Tasks'));
    expect(title.style?.color, AppTheme.darkTheme.colorScheme.onSurface);

    // The choice is remembered across restarts.
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester);
    expect(find.byTooltip('Light mode'), findsOneWidget);
  });

  testWidgets('refuses to register the same email twice', (tester) async {
    await pumpApp(tester);
    await signUp(tester);
    await signOut(tester);

    await signUp(tester, name: 'Copycat', email: 'AMRIT@example.com');
    expect(
      find.text('This email address is already in use by another account.'),
      findsOneWidget,
    );
    expect(find.text('My Tasks'), findsNothing);
  });
}
