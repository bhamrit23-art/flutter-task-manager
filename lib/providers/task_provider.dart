import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/firestore_service.dart';

class TaskProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  StreamSubscription<List<TaskModel>>? _tasksSubscription;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Initializes real-time listener for user tasks
  void initTasks(String userId) {
    if (!_firestoreService.isAvailable) {
      _tasks = [];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    if (_currentUserId == userId && _tasksSubscription != null) {
      return; // Already listening for this user
    }

    _currentUserId = userId;
    _tasksSubscription?.cancel();

    if (userId.isEmpty) {
      _tasks = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    _tasksSubscription = _firestoreService.getTasksStream(userId).listen(
      (taskList) {
        _tasks = taskList;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString().replaceAll("Exception: ", "");
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Adds a new task
  Future<bool> addTask({
    required String userId,
    required String title,
    required String description,
  }) async {
    _setLoading(true);
    _setError(null);

    if (!_firestoreService.isAvailable) {
      final now = DateTime.now();
      _tasks = [
        TaskModel(
          id: 'local-${now.microsecondsSinceEpoch}',
          userId: userId,
          title: title.trim(),
          description: description.trim(),
          createdAt: now,
          updatedAt: now,
        ),
        ..._tasks,
      ];
      _setLoading(false);
      notifyListeners();
      return true;
    }

    try {
      await _firestoreService.addTask(
        userId: userId,
        title: title,
        description: description,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll("Exception: ", ""));
      _setLoading(false);
      return false;
    }
  }

  /// Updates existing task title and description
  Future<bool> updateTask(TaskModel task) async {
    _setLoading(true);
    _setError(null);

    if (!_firestoreService.isAvailable) {
      _tasks = _tasks
          .map((currentTask) => currentTask.id == task.id ? task : currentTask)
          .toList();
      _setLoading(false);
      notifyListeners();
      return true;
    }

    try {
      await _firestoreService.updateTask(task);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll("Exception: ", ""));
      _setLoading(false);
      return false;
    }
  }

  /// Toggles task completion state
  Future<void> toggleTaskCompletion({
    required String userId,
    required String taskId,
    required bool isCompleted,
  }) async {
    if (!_firestoreService.isAvailable) {
      _tasks = _tasks.map((task) {
        if (task.id != taskId) return task;
        return task.copyWith(
            isCompleted: isCompleted, updatedAt: DateTime.now());
      }).toList();
      notifyListeners();
      return;
    }

    try {
      await _firestoreService.toggleTaskStatus(
        userId: userId,
        taskId: taskId,
        isCompleted: isCompleted,
      );
    } catch (e) {
      _setError(e.toString().replaceAll("Exception: ", ""));
    }
  }

  /// Deletes a task
  Future<bool> deleteTask({
    required String userId,
    required String taskId,
  }) async {
    _setLoading(true);
    _setError(null);

    if (!_firestoreService.isAvailable) {
      _tasks = _tasks.where((task) => task.id != taskId).toList();
      _setLoading(false);
      notifyListeners();
      return true;
    }

    try {
      await _firestoreService.deleteTask(userId: userId, taskId: taskId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll("Exception: ", ""));
      _setLoading(false);
      return false;
    }
  }

  /// Clears tasks on user logout
  void clearTasks() {
    _tasksSubscription?.cancel();
    _tasksSubscription = null;
    _tasks = [];
    _currentUserId = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
