import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/task_model.dart';

class FirestoreService {
  bool get isAvailable {
    if (Firebase.apps.isEmpty) return false;
    final apiKey = Firebase.app().options.apiKey;
    return apiKey.isNotEmpty && !apiKey.contains('DemoApiKey');
  }

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Helper reference to user's tasks collection: users/{uid}/tasks
  CollectionReference _userTasksCollection(String userId) {
    if (!isAvailable) {
      throw Exception(
        'Firebase Firestore is not configured for this app yet. Add your Firebase project setup to enable cloud tasks.',
      );
    }

    if (userId.isEmpty) {
      throw Exception("User ID cannot be empty.");
    }
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  /// CREATE: Add a new task for the authenticated user
  Future<void> addTask({
    required String userId,
    required String title,
    required String description,
  }) async {
    if (!isAvailable) {
      throw Exception(
        'Firebase Firestore is not configured for this app yet. Add your Firebase project setup to enable cloud tasks.',
      );
    }

    try {
      final docRef = _userTasksCollection(userId).doc();
      final newTask = TaskModel(
        id: docRef.id,
        userId: userId,
        title: title.trim(),
        description: description.trim(),
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(newTask.toFirestore());
    } on FirebaseException catch (e) {
      throw Exception("Firestore Error (${e.code}): ${e.message}");
    } catch (e) {
      throw Exception("Failed to create task: ${e.toString()}");
    }
  }

  /// READ: Real-time stream of user tasks ordered by creation date
  Stream<List<TaskModel>> getTasksStream(String userId) {
    if (!isAvailable) {
      return const Stream.empty();
    }

    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _userTasksCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
    });
  }

  /// UPDATE: Modify task title and description
  Future<void> updateTask(TaskModel task) async {
    if (!isAvailable) {
      throw Exception(
        'Firebase Firestore is not configured for this app yet. Add your Firebase project setup to enable cloud tasks.',
      );
    }

    try {
      final taskRef = _userTasksCollection(task.userId).doc(task.id);
      await taskRef.update({
        'title': task.title.trim(),
        'description': task.description.trim(),
        'isCompleted': task.isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception("Firestore Error (${e.code}): ${e.message}");
    } catch (e) {
      throw Exception("Failed to update task: ${e.toString()}");
    }
  }

  /// UPDATE: Toggle task completion status
  Future<void> toggleTaskStatus({
    required String userId,
    required String taskId,
    required bool isCompleted,
  }) async {
    if (!isAvailable) {
      throw Exception(
        'Firebase Firestore is not configured for this app yet. Add your Firebase project setup to enable cloud tasks.',
      );
    }

    try {
      final taskRef = _userTasksCollection(userId).doc(taskId);
      await taskRef.update({
        'isCompleted': isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception("Firestore Error (${e.code}): ${e.message}");
    } catch (e) {
      throw Exception("Failed to toggle task status: ${e.toString()}");
    }
  }

  /// DELETE: Delete a task document
  Future<void> deleteTask({
    required String userId,
    required String taskId,
  }) async {
    if (!isAvailable) {
      throw Exception(
        'Firebase Firestore is not configured for this app yet. Add your Firebase project setup to enable cloud tasks.',
      );
    }

    try {
      final taskRef = _userTasksCollection(userId).doc(taskId);
      await taskRef.delete();
    } on FirebaseException catch (e) {
      throw Exception("Firestore Error (${e.code}): ${e.message}");
    } catch (e) {
      throw Exception("Failed to delete task: ${e.toString()}");
    }
  }
}
