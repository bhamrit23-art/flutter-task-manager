import 'package:cloud_firestore/cloud_firestore.dart';

/// How urgent a task is. Stored by [name] ('low', 'medium', 'high').
enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High');

  const TaskPriority(this.label);

  final String label;

  /// Falls back to [medium] for tasks saved before priorities existed.
  static TaskPriority fromName(Object? name) {
    for (final priority in values) {
      if (priority.name == name) return priority;
    }
    return medium;
  }
}

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final bool isCompleted;
  final TaskPriority priority;

  /// Day the task is due. Only the date part is meaningful.
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
  });

  /// True when the due day has passed and the task is still open.
  bool get isOverdue {
    final due = dueDate;
    if (due == null || isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(due.year, due.month, due.day).isBefore(today);
  }

  /// Factory method to construct a TaskModel from a Cloud Firestore DocumentSnapshot
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    return TaskModel.fromMap(doc.id, data);
  }

  /// Builds a task from either a Firestore document or locally stored JSON.
  factory TaskModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value);
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return null;
    }

    return TaskModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      isCompleted: data['isCompleted'] as bool? ?? false,
      priority: TaskPriority.fromName(data['priority']),
      dueDate: parseDateTime(data['dueDate']),
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }

  /// Converts the TaskModel instance to a Map for Firestore insertion/updating
  Map<String, dynamic> toFirestore() {
    final now = DateTime.now();
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'priority': priority.name,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt ?? now),
      'updatedAt': Timestamp.fromDate(updatedAt ?? now),
    };
  }

  /// Converts the TaskModel instance to plain JSON for on-device storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'priority': priority.name,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Creates a copy of the TaskModel with updated fields.
  /// Pass [clearDueDate] to remove the due date, since null means "unchanged".
  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    bool? isCompleted,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
