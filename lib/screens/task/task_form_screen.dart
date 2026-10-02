import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/responsive.dart';
import 'task_actions.dart';

/// Creates a new task, or edits [task] when one is given.
class TaskFormScreen extends StatefulWidget {
  final TaskModel? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskPriority _priority;
  DateTime? _dueDate;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    _priority = task?.priority ?? TaskPriority.medium;
    _dueDate = task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final initial = _dueDate ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      // Past dates are only offered when the task is already due in the past.
      firstDate: initial.isBefore(today) ? initial : today,
      lastDate: DateTime(today.year + 10, 12, 31),
      helpText: 'Due date',
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final taskProvider = context.read<TaskProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final existing = widget.task;

    final bool success;
    if (existing == null) {
      success = await taskProvider.addTask(
        title: _titleController.text,
        description: _descriptionController.text,
        priority: _priority,
        dueDate: _dueDate,
      );
    } else {
      success = await taskProvider.updateTask(
        existing.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          priority: _priority,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
        ),
      );
    }

    if (success) {
      navigator.pop();
      showAppSnackBar(
          messenger, existing == null ? 'Task added' : 'Task updated');
    } else {
      showAppSnackBar(
        messenger,
        taskProvider.actionError ?? 'Could not save the task.',
      );
    }
  }

  Future<void> _deleteTask() async {
    final navigator = Navigator.of(context);
    if (await confirmAndDeleteTask(context, widget.task!)) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isSaving = context.watch<TaskProvider>().isSaving;
    final createdAt = widget.task?.createdAt;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit task' : 'New task'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete task',
              icon: const Icon(Icons.delete_outline),
              onPressed: isSaving ? null : _deleteTask,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: pagePadding(context, maxContentWidth: 560, top: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title Field
                const _FieldLabel('Title'),
                TextFormField(
                  controller: _titleController,
                  autofocus: !_isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    hintText: 'What needs to be done?',
                    counterText: '',
                  ),
                  validator:
                      Validators.required('Please give the task a title'),
                ),
                const SizedBox(height: 20),

                // Description Field
                const _FieldLabel('Description', optional: true),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Add details or notes',
                  ),
                ),
                const SizedBox(height: 20),

                // Priority
                const _FieldLabel('Priority'),
                SegmentedButton<TaskPriority>(
                  expandedInsets: EdgeInsets.zero,
                  showSelectedIcon: false,
                  segments: [
                    for (final priority in TaskPriority.values)
                      ButtonSegment(
                        value: priority,
                        label: Text(priority.label),
                        icon: Icon(
                          Icons.circle,
                          size: 8,
                          color: AppTheme.priorityColor(
                            priority,
                            theme.brightness,
                          ),
                        ),
                      ),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (selection) {
                    setState(() => _priority = selection.first);
                  },
                ),
                const SizedBox(height: 20),

                // Due date
                const _FieldLabel('Due date', optional: true),
                _DueDateField(
                  dueDate: _dueDate,
                  onTap: _pickDueDate,
                  onClear: () => setState(() => _dueDate = null),
                ),
                const SizedBox(height: 32),

                PrimaryButton(
                  label: _isEditing ? 'Save changes' : 'Add task',
                  isLoading: isSaving,
                  onPressed: _saveTask,
                ),
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    foregroundColor: scheme.onSurfaceVariant,
                  ),
                  onPressed:
                      isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),

                if (createdAt != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Created ${formatTimestamp(createdAt)}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small caption placed above a form field.
class _FieldLabel extends StatelessWidget {
  final String text;
  final bool optional;

  const _FieldLabel(this.text, {this.optional = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text,
          children: [
            if (optional)
              TextSpan(
                text: '  optional',
                style: TextStyle(color: muted, fontWeight: FontWeight.w400),
              ),
          ],
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Tappable row that shows the chosen due date, styled to match text fields.
class _DueDateField extends StatelessWidget {
  final DateTime? dueDate;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DueDateField({
    required this.dueDate,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(12);

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.event_outlined,
                  size: 20, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dueDate == null ? 'No due date' : formatLongDate(dueDate!),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: dueDate == null ? scheme.onSurfaceVariant : null,
                  ),
                ),
              ),
              if (dueDate != null)
                IconButton(
                  tooltip: 'Remove due date',
                  icon: const Icon(Icons.close, size: 20),
                  color: scheme.onSurfaceVariant,
                  onPressed: onClear,
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
