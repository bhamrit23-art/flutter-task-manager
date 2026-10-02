import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_message.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive.dart';
import '../../widgets/task_card.dart';
import '../settings/settings_screen.dart';
import '../task/task_actions.dart';
import '../task/task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<TaskProvider>().searchQuery,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openTaskForm([TaskModel? task]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TaskFormScreen(task: task)),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  Future<void> _toggleCompleted(TaskModel task, bool isCompleted) async {
    final taskProvider = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await taskProvider.toggleTaskCompletion(task, isCompleted);
    if (!success) {
      showAppSnackBar(
        messenger,
        taskProvider.actionError ?? 'Could not update the task.',
      );
    }
  }

  void _clearSearchAndFilter() {
    _searchController.clear();
    context.read<TaskProvider>()
      ..setSearchQuery('')
      ..setFilter(TaskFilter.all);
  }

  /// What to show instead of the list while loading or when there is nothing
  /// to list. Returns null when there are tasks to show.
  Widget? _buildPlaceholder(TaskProvider taskProvider, int visibleCount) {
    if (taskProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 72),
        child: LoadingWidget(message: 'Loading your tasks...'),
      );
    }
    if (taskProvider.totalCount == 0) {
      // A loading error already explains the empty list.
      if (taskProvider.loadError != null) return const SizedBox.shrink();
      return const EmptyState(
        icon: Icons.task_alt,
        title: 'No tasks yet',
        message: 'Tap "New task" to add your first one.',
      );
    }
    if (visibleCount == 0) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Nothing here',
        message: 'No tasks match your search or filter.',
        actionLabel: 'Show all tasks',
        onAction: _clearSearchAndFilter,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Read the theme here, at screen level, so the whole list is rebuilt when
    // it changes, even while this screen is covered by Settings.
    final theme = Theme.of(context);
    final taskProvider = context.watch<TaskProvider>();
    final displayName = context.watch<AuthProvider>().user?.displayName ?? '';
    final compact = isCompact(context);
    final visibleTasks = taskProvider.visibleTasks;
    final placeholder = _buildPlaceholder(taskProvider, visibleTasks.length);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView.builder(
          // Extra bottom space keeps the last card clear of the button.
          padding: pagePadding(context, top: 12, bottom: 104),
          itemCount: 1 + (placeholder != null ? 1 : visibleTasks.length),
          itemBuilder: (_, index) {
            if (index == 0) {
              return _buildHeader(theme, taskProvider, displayName, compact);
            }
            if (placeholder != null) return placeholder;

            final task = visibleTasks[index - 1];
            return Padding(
              key: ValueKey(task.id),
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildTask(theme.colorScheme, task),
            );
          },
        ),
      ),
      floatingActionButton: compact
          ? FloatingActionButton.extended(
              // No hero animation: while the button fades in or out (e.g. on
              // rotation) two copies exist briefly, and their tags would clash.
              heroTag: null,
              onPressed: _openTaskForm,
              icon: const Icon(Icons.add),
              label: const Text('New task'),
            )
          : null,
    );
  }

  Widget _buildTask(ColorScheme scheme, TaskModel task) {
    return Dismissible(
      key: ValueKey('dismiss-${task.id}'),
      direction: DismissDirection.endToStart,
      // The card is never dismissed by the swipe itself: the task is deleted
      // through the provider and disappears when the live list updates.
      confirmDismiss: (_) async {
        await confirmAndDeleteTask(context, task);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      child: TaskCard(
        task: task,
        onToggleCompleted: (isCompleted) => _toggleCompleted(task, isCompleted),
        onEdit: () => _openTaskForm(task),
        onDelete: () => confirmAndDeleteTask(context, task),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    TaskProvider taskProvider,
    String displayName,
    bool compact,
  ) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final firstName = displayName.trim().split(RegExp(r'\s+')).first;
    final greeting = greetingFor(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Greeting, title and actions
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    firstName.isEmpty ? greeting : '$greeting, $firstName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('My Tasks', style: theme.textTheme.headlineMedium),
                ],
              ),
            ),
            if (!compact) ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: _openTaskForm,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New task'),
              ),
              const SizedBox(width: 8),
            ],
            IconButton(
              tooltip: isDark ? 'Light mode' : 'Dark mode',
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
              onPressed: () {
                context.read<ThemeProvider>().toggleTheme(theme.brightness);
              },
            ),
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: _openSettings,
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (taskProvider.loadError != null) ...[
          ErrorMessage(
            message: taskProvider.loadError!,
            onRetry: taskProvider.retry,
          ),
          const SizedBox(height: 16),
        ],

        if (taskProvider.totalCount > 0) ...[
          _ProgressCard(
            completed: taskProvider.completedCount,
            total: taskProvider.totalCount,
            progress: taskProvider.progress,
          ),
          const SizedBox(height: 16),

          // Search and sort
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: taskProvider.setSearchQuery,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search tasks',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: taskProvider.searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              taskProvider.setSearchQuery('');
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SortButton(
                selected: taskProvider.sort,
                onSelected: taskProvider.setSort,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // All / Active / Done
          SegmentedButton<TaskFilter>(
            expandedInsets: EdgeInsets.zero,
            showSelectedIcon: false,
            segments: [
              for (final filter in TaskFilter.values)
                ButtonSegment(
                  value: filter,
                  label:
                      Text('${filter.label}  ${taskProvider.countFor(filter)}'),
                ),
            ],
            selected: {taskProvider.filter},
            onSelectionChanged: (selection) {
              taskProvider.setFilter(selection.first);
            },
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

/// "3 of 8 completed" with a thin progress bar.
class _ProgressCard extends StatelessWidget {
  final int completed;
  final int total;
  final double progress;

  const _ProgressCard({
    required this.completed,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final allDone = completed == total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    allDone
                        ? 'All done. Nice work!'
                        : '$completed of $total completed',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: progress),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(99),
                  color: allDone ? scheme.secondary : scheme.primary,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Square button, sized to sit next to the search field, that opens the sort menu.
class _SortButton extends StatelessWidget {
  final TaskSort selected;
  final ValueChanged<TaskSort> onSelected;

  const _SortButton({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(12);

    return PopupMenuButton<TaskSort>(
      tooltip: 'Sort tasks',
      onSelected: onSelected,
      borderRadius: borderRadius,
      itemBuilder: (context) => [
        for (final sort in TaskSort.values)
          PopupMenuItem(
            value: sort,
            child: Row(
              children: [
                Expanded(child: Text(sort.label)),
                const SizedBox(width: 16),
                Icon(
                  Icons.check,
                  size: 18,
                  color:
                      sort == selected ? scheme.onSurface : Colors.transparent,
                ),
              ],
            ),
          ),
      ],
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: borderRadius,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Icon(Icons.swap_vert, size: 20, color: scheme.onSurfaceVariant),
      ),
    );
  }
}
