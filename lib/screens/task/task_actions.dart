import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../widgets/confirm_dialog.dart';

/// Shows a short message at the bottom of the screen, replacing any message
/// that is already visible.
void showAppSnackBar(
  ScaffoldMessengerState messenger,
  String message, {
  SnackBarAction? action,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        // Messages offering an action get longer, so there is time to tap it.
        duration: Duration(seconds: action == null ? 3 : 6),
        // Snack bars with an action stay up until dismissed unless told
        // otherwise; "Undo" should fade away like any other message.
        persist: false,
      ),
    );
}

/// Asks for confirmation, deletes [task], and offers an "Undo".
/// Returns true when the task was deleted.
Future<bool> confirmAndDeleteTask(BuildContext context, TaskModel task) async {
  final taskProvider = context.read<TaskProvider>();
  final messenger = ScaffoldMessenger.of(context);

  final confirmed = await showConfirmDialog(
    context,
    title: 'Delete task?',
    message: '"${task.title}" will be removed from your list.',
    confirmLabel: 'Delete',
    isDestructive: true,
  );
  if (!confirmed) return false;

  final deleted = await taskProvider.deleteTask(task);
  if (deleted) {
    showAppSnackBar(
      messenger,
      'Task deleted',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => taskProvider.restoreTask(task),
      ),
    );
  } else {
    showAppSnackBar(
      messenger,
      taskProvider.actionError ?? 'Could not delete the task.',
    );
  }
  return deleted;
}
