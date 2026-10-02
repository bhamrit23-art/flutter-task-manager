import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task_model.dart';
import 'task_service.dart';

/// Tasks stored in Cloud Firestore under `users/{uid}/tasks/{taskId}`.
class FirestoreTaskService implements TaskService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Helper reference to user's tasks collection: users/{uid}/tasks
  CollectionReference<Map<String, dynamic>> _userTasksCollection(
      String userId) {
    if (userId.isEmpty) {
      throw const TaskFailure('You need to be signed in to manage tasks.');
    }
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  /// READ: Real-time stream of user tasks ordered by creation date
  @override
  Stream<List<TaskModel>> watchTasks(String userId) {
    return _userTasksCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(TaskModel.fromFirestore).toList())
        .handleError((Object error) => throw _failureFor(error));
  }

  /// CREATE: Add a new task for the authenticated user
  @override
  Future<void> createTask(TaskModel task) {
    return _write(() {
      final collection = _userTasksCollection(task.userId);
      final docRef =
          task.id.isEmpty ? collection.doc() : collection.doc(task.id);
      return docRef.set(task.copyWith(id: docRef.id).toFirestore());
    });
  }

  /// UPDATE: Modify the editable fields of a task
  @override
  Future<void> updateTask(TaskModel task) {
    return _write(() {
      return _userTasksCollection(task.userId).doc(task.id).update({
        'title': task.title,
        'description': task.description,
        'isCompleted': task.isCompleted,
        'priority': task.priority.name,
        'dueDate':
            task.dueDate != null ? Timestamp.fromDate(task.dueDate!) : null,
        'updatedAt': Timestamp.now(),
      });
    });
  }

  /// UPDATE: Toggle task completion status
  @override
  Future<void> setCompleted({
    required String userId,
    required String taskId,
    required bool isCompleted,
  }) {
    return _write(() {
      return _userTasksCollection(userId).doc(taskId).update({
        'isCompleted': isCompleted,
        'updatedAt': Timestamp.now(),
      });
    });
  }

  /// DELETE: Delete one or more task documents in a single batch
  @override
  Future<void> deleteTasks({
    required String userId,
    required List<String> taskIds,
  }) {
    return _write(() {
      final collection = _userTasksCollection(userId);
      final batch = _firestore.batch();
      for (final taskId in taskIds) {
        batch.delete(collection.doc(taskId));
      }
      return batch.commit();
    });
  }

  /// Runs a write and converts Firebase errors into [TaskFailure]s.
  ///
  /// Firestore applies writes to its local cache straight away but only
  /// completes the future once the server confirms. While offline that never
  /// happens, so after a short wait the write is treated as queued.
  Future<void> _write(Future<void> Function() action) async {
    try {
      await action().timeout(const Duration(seconds: 8), onTimeout: () {});
    } on FirebaseException catch (e) {
      throw _failureFor(e);
    }
  }

  TaskFailure _failureFor(Object error) {
    if (error is TaskFailure) return error;
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return const TaskFailure(
            'Permission denied. Check the Firestore security rules for this project.',
          );
        case 'unavailable':
          return const TaskFailure(
            'Cannot reach the server. Please check your internet connection.',
          );
        default:
          return TaskFailure(
            error.message ?? 'Something went wrong (${error.code}).',
          );
      }
    }
    return const TaskFailure('Something went wrong. Please try again.');
  }
}
