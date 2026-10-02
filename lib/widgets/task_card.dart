import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

enum _TaskAction { edit, delete }

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final ValueChanged<bool> onToggleCompleted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleCompleted,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = task.isCompleted;
    final dueDate = task.dueDate;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Completion Checkbox
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: done,
                  onChanged: (value) => onToggleCompleted(value ?? false),
                ),
              ),
              // Title, description and details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(2, 12, 0, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: theme.textTheme.titleMedium!.copyWith(
                          height: 1.5,
                          color:
                              done ? scheme.onSurfaceVariant : scheme.onSurface,
                          decoration: done
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: scheme.onSurfaceVariant,
                        ),
                        child: Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          _Detail(
                            label: task.priority.label,
                            leading: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.priorityColor(
                                  task.priority,
                                  theme.brightness,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          if (dueDate != null)
                            _Detail(
                              label: task.isOverdue
                                  ? 'Overdue · ${formatDueDate(dueDate)}'
                                  : 'Due ${formatDueDate(dueDate)}',
                              color: task.isOverdue ? scheme.error : null,
                              leading: Icon(
                                Icons.event_outlined,
                                size: 14,
                                color: task.isOverdue
                                    ? scheme.error
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Edit & Delete
              PopupMenuButton<_TaskAction>(
                tooltip: 'Task options',
                icon: Icon(Icons.more_horiz, color: scheme.onSurfaceVariant),
                onSelected: (action) {
                  switch (action) {
                    case _TaskAction.edit:
                      onEdit();
                    case _TaskAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _TaskAction.edit,
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: _TaskAction.delete,
                    child:
                        Text('Delete', style: TextStyle(color: scheme.error)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small icon-and-label pair in the footer of a task card.
class _Detail extends StatelessWidget {
  final Widget leading;
  final String label;
  final Color? color;

  const _Detail({required this.leading, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        leading,
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color ?? theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
