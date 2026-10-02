import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_model.dart';
import 'task_service.dart';

/// Tasks kept on this device, used when Firebase has not been configured.
///
/// Each user's tasks are stored as one JSON list, so they survive restarts.
class LocalTaskService implements TaskService {
  LocalTaskService(this._prefs);

  final SharedPreferences _prefs;

  /// Emits the id of the user whose task list was just written.
  final _changes = StreamController<String>.broadcast();

  String _key(String userId) => 'local_tasks_$userId';

  @override
  Stream<List<TaskModel>> watchTasks(String userId) {
    late final StreamController<List<TaskModel>> controller;
    StreamSubscription<String>? subscription;
    controller = StreamController<List<TaskModel>>(
      onListen: () {
        controller.add(_read(userId));
        subscription = _changes.stream
            .where((changedUserId) => changedUserId == userId)
            .listen((_) => controller.add(_read(userId)));
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<void> createTask(TaskModel task) {
    final tasks = _read(task.userId);
    final id = task.id.isEmpty
        ? 'task-${DateTime.now().microsecondsSinceEpoch}'
        : task.id;
    tasks.add(task.copyWith(id: id));
    return _write(task.userId, tasks);
  }

  @override
  Future<void> updateTask(TaskModel task) {
    final tasks = _read(task.userId);
    final index = tasks.indexWhere((existing) => existing.id == task.id);
    if (index == -1) {
      throw const TaskFailure('This task no longer exists.');
    }
    tasks[index] = task.copyWith(updatedAt: DateTime.now());
    return _write(task.userId, tasks);
  }

  @override
  Future<void> setCompleted({
    required String userId,
    required String taskId,
    required bool isCompleted,
  }) {
    final tasks = _read(userId);
    final index = tasks.indexWhere((existing) => existing.id == taskId);
    if (index == -1) {
      throw const TaskFailure('This task no longer exists.');
    }
    tasks[index] = tasks[index].copyWith(
      isCompleted: isCompleted,
      updatedAt: DateTime.now(),
    );
    return _write(userId, tasks);
  }

  @override
  Future<void> deleteTasks({
    required String userId,
    required List<String> taskIds,
  }) {
    final tasks = _read(userId)
      ..removeWhere((existing) => taskIds.contains(existing.id));
    return _write(userId, tasks);
  }

  /// Reads the user's tasks, newest first to match the Firestore query.
  List<TaskModel> _read(String userId) {
    final raw = _prefs.getString(_key(userId));
    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final tasks = [
        for (final item in decoded)
          if (item is Map<String, dynamic>)
            TaskModel.fromMap(item['id'] as String? ?? '', item),
      ];
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      tasks.sort(
        (a, b) => (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch),
      );
      return tasks;
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<void> _write(String userId, List<TaskModel> tasks) async {
    final encoded = jsonEncode([for (final task in tasks) task.toJson()]);
    final saved = await _prefs.setString(_key(userId), encoded);
    if (!saved) {
      throw const TaskFailure('Could not save your tasks on this device.');
    }
    _changes.add(userId);
  }
}
