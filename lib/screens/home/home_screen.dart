import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/task_model.dart';
import '../../widgets/task_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_message.dart';
import '../task/add_task_screen.dart';
import '../task/edit_task_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        context.read<TaskProvider>().initTasks(authProvider.user!.uid);
      }
    });
  }

  /// Displays alert dialog confirmation before deleting a task
  void _confirmDeleteTask(BuildContext context, TaskModel task) {
    final authUser = context.read<AuthProvider>().user;
    if (authUser == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete Task?"),
          content: Text("Are you sure you want to delete '${task.title}'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final taskProvider = context.read<TaskProvider>();
                final success = await taskProvider.deleteTask(
                  userId: authUser.uid,
                  taskId: task.id,
                );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Task deleted successfully"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final authUser = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tasks"),
        actions: [
          // Dynamic Theme Toggle Button
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
            onPressed: () {
              themeProvider.toggleThemeMode();
            },
          ),
          // Settings Navigation Button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Error Message Banner if any
            if (taskProvider.errorMessage != null)
              ErrorMessage(
                message: taskProvider.errorMessage!,
                onRetry: () {
                  if (authUser != null) {
                    taskProvider.initTasks(authUser.uid);
                  }
                },
              ),

            // Real-Time Task List Body
            Expanded(
              child: taskProvider.isLoading && taskProvider.tasks.isEmpty
                  ? const LoadingWidget(message: "Loading your tasks...")
                  : taskProvider.tasks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 90,
                                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "No tasks yet. Create your first task!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyLarge?.color
                                        ?.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Tap the '+' button below to get started.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: taskProvider.tasks.length,
                          itemBuilder: (context, index) {
                            final task = taskProvider.tasks[index];
                            return TaskCard(
                              task: task,
                              onToggleCompleted: (bool? isCompleted) {
                                if (authUser != null && isCompleted != null) {
                                  taskProvider.toggleTaskCompletion(
                                    userId: authUser.uid,
                                    taskId: task.id,
                                    isCompleted: isCompleted,
                                  );
                                }
                              },
                              onEdit: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EditTaskScreen(task: task),
                                  ),
                                );
                              },
                              onDelete: () => _confirmDeleteTask(context, task),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddTaskScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Task"),
      ),
    );
  }
}
