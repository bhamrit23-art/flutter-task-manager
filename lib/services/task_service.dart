import '../models/task_model.dart';

/// Thrown by a [TaskService] with a message that is safe to show to the user.
class TaskFailure implements Exception {
  const TaskFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Task storage. Implemented by Cloud Firestore and by on-device storage.
abstract class TaskService {
  /// Live list of the user's tasks, newest first.
  Stream<List<TaskModel>> watchTasks(String userId);

  /// Saves a new task. An empty [TaskModel.id] gets a generated id; a filled
  /// one is kept, which lets a deleted task be restored unchanged.
  Future<void> createTask(TaskModel task);

  Future<void> updateTask(TaskModel task);

  Future<void> setCompleted({
    required String userId,
    required String taskId,
    required bool isCompleted,
  });

  Future<void> deleteTasks({
    required String userId,
    required List<String> taskIds,
  });
}
