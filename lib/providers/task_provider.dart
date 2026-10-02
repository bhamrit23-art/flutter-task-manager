import 'dart:async';

import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../services/task_service.dart';
import 'auth_provider.dart';

enum TaskFilter {
  all('All'),
  active('Active'),
  completed('Done');

  const TaskFilter(this.label);

  final String label;
}

enum TaskSort {
  newest('Newest first'),
  dueDate('Due date'),
  priority('Priority');

  const TaskSort(this.label);

  final String label;
}

class TaskProvider extends ChangeNotifier {
  /// Follows [AuthProvider] so the task list always belongs to the signed-in
  /// user, and is cleared the moment they sign out.
  TaskProvider(this._taskService, this._auth) {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final TaskService _taskService;
  final AuthProvider _auth;

  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadError;
  String? _actionError;
  String? _userId;
  StreamSubscription<List<TaskModel>>? _tasksSubscription;

  TaskFilter _filter = TaskFilter.all;
  TaskSort _sort = TaskSort.newest;
  String _searchQuery = '';

  /// Every task of the current user, newest first.
  List<TaskModel> get tasks => _tasks;

  /// True while the first snapshot of the task list is on its way.
  bool get isLoading => _isLoading;

  /// True while a task is being created or updated.
  bool get isSaving => _isSaving;

  /// Set when the live task list could not be loaded.
  String? get loadError => _loadError;

  /// Message of the most recent failed add / update / delete, if any.
  String? get actionError => _actionError;

  TaskFilter get filter => _filter;
  TaskSort get sort => _sort;
  String get searchQuery => _searchQuery;

  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((task) => task.isCompleted).length;
  int get activeCount => totalCount - completedCount;

  /// Share of tasks completed, from 0 to 1.
  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;

  int countFor(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return totalCount;
      case TaskFilter.active:
        return activeCount;
      case TaskFilter.completed:
        return completedCount;
    }
  }

  /// The tasks to show: filtered, searched and sorted.
  List<TaskModel> get visibleTasks {
    final query = _searchQuery.trim().toLowerCase();

    final visible = _tasks.where((task) {
      final matchesFilter = switch (_filter) {
        TaskFilter.all => true,
        TaskFilter.active => !task.isCompleted,
        TaskFilter.completed => task.isCompleted,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query);
    }).toList();

    // List.sort is not stable, so ties fall back to the original
    // (newest first) position to keep the order steady between rebuilds.
    final position = {
      for (var i = 0; i < _tasks.length; i++) _tasks[i].id: i,
    };
    int byPosition(TaskModel a, TaskModel b) =>
        position[a.id]!.compareTo(position[b.id]!);

    // Open tasks come before finished ones when sorting by urgency.
    int byCompletion(TaskModel a, TaskModel b) =>
        (a.isCompleted ? 1 : 0).compareTo(b.isCompleted ? 1 : 0);

    switch (_sort) {
      case TaskSort.newest:
        break;
      case TaskSort.dueDate:
        visible.sort((a, b) {
          final completion = byCompletion(a, b);
          if (completion != 0) return completion;
          final aDue = a.dueDate, bDue = b.dueDate;
          if (aDue != null && bDue != null) {
            final due = aDue.compareTo(bDue);
            if (due != 0) return due;
          } else if (aDue != null || bDue != null) {
            // Tasks without a due date go last.
            return aDue != null ? -1 : 1;
          }
          return byPosition(a, b);
        });
      case TaskSort.priority:
        visible.sort((a, b) {
          final completion = byCompletion(a, b);
          if (completion != 0) return completion;
          final priority = b.priority.index.compareTo(a.priority.index);
          return priority != 0 ? priority : byPosition(a, b);
        });
    }
    return visible;
  }

  void setFilter(TaskFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  void setSort(TaskSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void _onAuthChanged() {
    final userId = _auth.user?.uid;
    if (userId == _userId) return;
    _userId = userId;
    _filter = TaskFilter.all;
    _sort = TaskSort.newest;
    _searchQuery = '';
    _actionError = null;
    _subscribe();
  }

  /// Re-attaches the live listener, e.g. after a loading error.
  void retry() => _subscribe();

  /// Starts the real-time listener for the current user's tasks.
  void _subscribe() {
    _tasksSubscription?.cancel();
    _tasksSubscription = null;
    _tasks = [];
    _loadError = null;

    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _tasksSubscription = _taskService.watchTasks(userId).listen(
      (taskList) {
        _tasks = taskList;
        _isLoading = false;
        _loadError = null;
        notifyListeners();
      },
      onError: (Object error) {
        _loadError = _messageFor(error);
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Adds a new task
  Future<bool> addTask({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  }) {
    final userId = _userId;
    if (userId == null) return Future.value(false);

    final now = DateTime.now();
    return _save(
      () => _taskService.createTask(
        TaskModel(
          id: '',
          userId: userId,
          title: title.trim(),
          description: description.trim(),
          priority: priority,
          dueDate: dueDate,
          createdAt: now,
          updatedAt: now,
        ),
      ),
    );
  }

  /// Updates an existing task
  Future<bool> updateTask(TaskModel task) {
    return _save(
      () => _taskService.updateTask(
        task.copyWith(
          title: task.title.trim(),
          description: task.description.trim(),
        ),
      ),
    );
  }

  /// Toggles task completion state
  Future<bool> toggleTaskCompletion(TaskModel task, bool isCompleted) {
    return _run(
      () => _taskService.setCompleted(
        userId: task.userId,
        taskId: task.id,
        isCompleted: isCompleted,
      ),
    );
  }

  /// Deletes a task
  Future<bool> deleteTask(TaskModel task) {
    return _run(
      () => _taskService.deleteTasks(userId: task.userId, taskIds: [task.id]),
    );
  }

  /// Puts a just-deleted task back exactly as it was (the "Undo" action).
  Future<bool> restoreTask(TaskModel task) {
    return _run(() => _taskService.createTask(task));
  }

  /// Deletes every completed task. Returns how many were removed, or -1 if
  /// the delete failed.
  Future<int> clearCompleted() async {
    final userId = _userId;
    final completedIds = [
      for (final task in _tasks)
        if (task.isCompleted) task.id,
    ];
    if (userId == null || completedIds.isEmpty) return 0;

    final deleted = await _run(
      () => _taskService.deleteTasks(userId: userId, taskIds: completedIds),
    );
    return deleted ? completedIds.length : -1;
  }

  Future<bool> _save(Future<void> Function() action) async {
    _isSaving = true;
    notifyListeners();
    try {
      return await _run(action);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Runs a write and records its error message instead of throwing.
  Future<bool> _run(Future<void> Function() action) async {
    _actionError = null;
    try {
      await action();
      return true;
    } catch (error) {
      _actionError = _messageFor(error);
      return false;
    }
  }

  String _messageFor(Object error) {
    return error is TaskFailure
        ? error.message
        : 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
