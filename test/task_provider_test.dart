import 'package:firebase_task_manager/models/task_model.dart';
import 'package:firebase_task_manager/providers/auth_provider.dart';
import 'package:firebase_task_manager/providers/task_provider.dart';
import 'package:firebase_task_manager/services/local_auth_service.dart';
import 'package:firebase_task_manager/services/local_task_service.dart';
import 'package:firebase_task_manager/utils/formatters.dart';
import 'package:firebase_task_manager/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lets queued stream events reach their listeners.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late AuthProvider auth;
  late TaskProvider tasks;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    auth = AuthProvider(LocalAuthService(preferences));
    tasks = TaskProvider(LocalTaskService(preferences), auth);
    await auth.signUp(
      email: 'amrit@example.com',
      password: 'secret123',
      displayName: 'Amrit',
    );
    await settle();
  });

  tearDown(() {
    tasks.dispose();
    auth.dispose();
  });

  Future<void> add(
    String title, {
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  }) async {
    expect(
        await tasks.addTask(title: title, priority: priority, dueDate: dueDate),
        isTrue);
    await settle();
    // Distinct creation times keep "newest first" unambiguous.
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }

  List<String> visibleTitles() => [for (final t in tasks.visibleTasks) t.title];

  group('TaskProvider', () {
    test('starts empty for a new user', () {
      expect(tasks.tasks, isEmpty);
      expect(tasks.isLoading, isFalse);
      expect(tasks.progress, 0);
    });

    test('adds tasks newest first and trims the title', () async {
      await add('  First  ');
      await add('Second');

      expect(visibleTitles(), ['Second', 'First']);
      expect(tasks.totalCount, 2);
      expect(tasks.activeCount, 2);
    });

    test('tracks completion counts and progress', () async {
      await add('A');
      await add('B');
      await tasks.toggleTaskCompletion(tasks.tasks.first, true);
      await settle();

      expect(tasks.completedCount, 1);
      expect(tasks.activeCount, 1);
      expect(tasks.progress, 0.5);
    });

    test('filters by status', () async {
      await add('Open');
      await add('Finished');
      await tasks.toggleTaskCompletion(tasks.tasks.first, true);
      await settle();

      tasks.setFilter(TaskFilter.active);
      expect(visibleTitles(), ['Open']);
      tasks.setFilter(TaskFilter.completed);
      expect(visibleTitles(), ['Finished']);
      tasks.setFilter(TaskFilter.all);
      expect(visibleTitles(), ['Finished', 'Open']);
    });

    test('searches title and description, ignoring case', () async {
      await add('Buy MILK');
      await add('Call the bank');
      final bank = tasks.tasks.first;
      await tasks.updateTask(bank.copyWith(description: 'about the Mortgage'));
      await settle();

      tasks.setSearchQuery('milk');
      expect(visibleTitles(), ['Buy MILK']);
      tasks.setSearchQuery('mortgage');
      expect(visibleTitles(), ['Call the bank']);
      tasks.setSearchQuery('nothing matches');
      expect(visibleTitles(), isEmpty);
    });

    test('sorts by priority with completed tasks last', () async {
      await add('Low', priority: TaskPriority.low);
      await add('High', priority: TaskPriority.high);
      await add('Medium', priority: TaskPriority.medium);
      await add('Done high', priority: TaskPriority.high);
      await tasks.toggleTaskCompletion(tasks.tasks.first, true);
      await settle();

      tasks.setSort(TaskSort.priority);
      expect(visibleTitles(), ['High', 'Medium', 'Low', 'Done high']);
    });

    test('sorts by due date with undated tasks last', () async {
      await add('No date');
      await add('Later', dueDate: DateTime(2030, 6, 1));
      await add('Sooner', dueDate: DateTime(2030, 1, 1));

      tasks.setSort(TaskSort.dueDate);
      expect(visibleTitles(), ['Sooner', 'Later', 'No date']);
    });

    test('updates a task and can clear its due date', () async {
      await add('Draft', dueDate: DateTime(2030, 1, 1));
      final original = tasks.tasks.single;

      await tasks.updateTask(
        original.copyWith(
          title: 'Final',
          priority: TaskPriority.high,
          clearDueDate: true,
        ),
      );
      await settle();

      final updated = tasks.tasks.single;
      expect(updated.id, original.id);
      expect(updated.title, 'Final');
      expect(updated.priority, TaskPriority.high);
      expect(updated.dueDate, isNull);
    });

    test('deletes a task and restores it unchanged', () async {
      await add('Keep me', priority: TaskPriority.high);
      final task = tasks.tasks.single;

      expect(await tasks.deleteTask(task), isTrue);
      await settle();
      expect(tasks.tasks, isEmpty);

      expect(await tasks.restoreTask(task), isTrue);
      await settle();
      expect(tasks.tasks.single.id, task.id);
      expect(tasks.tasks.single.priority, TaskPriority.high);
    });

    test('clears only completed tasks', () async {
      await add('Stay');
      await add('Go 1');
      await add('Go 2');
      for (final task in tasks.tasks.where((t) => t.title.startsWith('Go'))) {
        await tasks.toggleTaskCompletion(task, true);
      }
      await settle();

      expect(await tasks.clearCompleted(), 2);
      await settle();
      expect(visibleTitles(), ['Stay']);
      expect(await tasks.clearCompleted(), 0);
    });

    test('empties the list and resets filters on sign-out', () async {
      await add('Mine');
      tasks.setFilter(TaskFilter.completed);
      tasks.setSearchQuery('x');

      await auth.signOut();
      await settle();

      expect(tasks.tasks, isEmpty);
      expect(tasks.filter, TaskFilter.all);
      expect(tasks.searchQuery, isEmpty);
      expect(await tasks.addTask(title: 'Nobody is signed in'), isFalse);
    });
  });

  group('TaskModel', () {
    test('survives a JSON round trip', () {
      final task = TaskModel(
        id: 'abc',
        userId: 'user-1',
        title: 'Title',
        description: 'Details',
        isCompleted: true,
        priority: TaskPriority.high,
        dueDate: DateTime(2030, 5, 20),
        createdAt: DateTime(2026, 10, 2, 9, 30),
        updatedAt: DateTime(2026, 10, 2, 10),
      );

      final copy = TaskModel.fromMap(task.id, task.toJson());

      expect(copy.id, task.id);
      expect(copy.userId, task.userId);
      expect(copy.title, task.title);
      expect(copy.description, task.description);
      expect(copy.isCompleted, isTrue);
      expect(copy.priority, TaskPriority.high);
      expect(copy.dueDate, task.dueDate);
      expect(copy.createdAt, task.createdAt);
      expect(copy.updatedAt, task.updatedAt);
    });

    test('reads documents written before priority and due date existed', () {
      final task = TaskModel.fromMap('old', {'title': 'Legacy', 'userId': 'u'});

      expect(task.priority, TaskPriority.medium);
      expect(task.dueDate, isNull);
      expect(task.description, isEmpty);
      expect(task.isCompleted, isFalse);
    });

    test('is overdue only when open and due before today', () {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final today = DateTime(now.year, now.month, now.day);
      TaskModel due(DateTime? date, {bool done = false}) => TaskModel(
            id: '1',
            userId: 'u',
            title: 't',
            dueDate: date,
            isCompleted: done,
          );

      expect(due(yesterday).isOverdue, isTrue);
      expect(due(yesterday, done: true).isOverdue, isFalse);
      expect(due(today).isOverdue, isFalse);
      expect(due(null).isOverdue, isFalse);
    });
  });

  group('formatters', () {
    final now = DateTime(2026, 10, 2, 15);

    test('describes due dates relative to today', () {
      expect(formatDueDate(DateTime(2026, 10, 2), now: now), 'Today');
      expect(formatDueDate(DateTime(2026, 10, 3), now: now), 'Tomorrow');
      expect(formatDueDate(DateTime(2026, 10, 1), now: now), 'Yesterday');
      expect(formatDueDate(DateTime(2026, 10, 12), now: now), '12 Oct');
      expect(formatDueDate(DateTime(2027, 1, 5), now: now), '5 Jan 2027');
    });

    test('greets by time of day', () {
      expect(greetingFor(DateTime(2026, 1, 1, 8)), 'Good morning');
      expect(greetingFor(DateTime(2026, 1, 1, 13)), 'Good afternoon');
      expect(greetingFor(DateTime(2026, 1, 1, 20)), 'Good evening');
    });
  });

  group('Validators.email', () {
    test('accepts real-world addresses', () {
      for (final email in [
        'amrit@example.com',
        'first.last@college.edu.np',
        'name+tag@gmail.com',
        'someone@company.technology',
      ]) {
        expect(Validators.email(email), isNull, reason: email);
      }
    });

    test('rejects malformed addresses', () {
      for (final email in ['', '   ', 'plain', 'a@b', 'a b@c.com', '@c.com']) {
        expect(Validators.email(email), isNotNull, reason: '"$email"');
      }
    });
  });
}
