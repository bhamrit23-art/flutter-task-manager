import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/app_services.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/responsive.dart';
import '../task/task_actions.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final navigator = Navigator.of(context);
    final authProvider = context.read<AuthProvider>();

    final confirmed = await showConfirmDialog(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in again to see your tasks.',
      confirmLabel: 'Sign out',
      isDestructive: true,
    );
    if (!confirmed) return;

    // Leave this screen first; the auth gate then swaps in the login screen.
    navigator.popUntil((route) => route.isFirst);
    await authProvider.signOut();
  }

  Future<void> _confirmClearCompleted(BuildContext context) async {
    final taskProvider = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final count = taskProvider.completedCount;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Clear completed tasks?',
      message: count == 1
          ? 'Your completed task will be deleted. This cannot be undone.'
          : 'Your $count completed tasks will be deleted. This cannot be undone.',
      confirmLabel: 'Clear',
      isDestructive: true,
    );
    if (!confirmed) return;

    final removed = await taskProvider.clearCompleted();
    if (removed < 0) {
      showAppSnackBar(
        messenger,
        taskProvider.actionError ?? 'Could not clear completed tasks.',
      );
    } else {
      showAppSnackBar(
        messenger,
        removed == 1 ? '1 task cleared' : '$removed tasks cleared',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final authUser = context.watch<AuthProvider>().user;
    final usesFirebase = context.watch<AppServices>().usesFirebase;

    final displayName = (authUser?.displayName ?? '').trim();
    final name = displayName.isNotEmpty ? displayName : 'Task Manager User';
    final email = authUser?.email ?? '';
    final completedCount = taskProvider.completedCount;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: pagePadding(context, maxContentWidth: 560, top: 8),
          children: [
            // Account Information Section
            const _SectionHeader('Account'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      child: Text(
                        name.characters.first.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Appearance / Theme Section
            const _SectionHeader('Appearance'),
            SegmentedButton<ThemeMode>(
              expandedInsets: EdgeInsets.zero,
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined, size: 18),
                ),
              ],
              selected: {themeProvider.themeMode},
              onSelectionChanged: (selection) {
                themeProvider.setThemeMode(selection.first);
              },
            ),
            const SizedBox(height: 24),

            // Tasks & storage Section
            const _SectionHeader('Tasks'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      usesFirebase
                          ? Icons.cloud_done_outlined
                          : Icons.smartphone_outlined,
                    ),
                    title: Text(usesFirebase ? 'Cloud sync' : 'Local mode'),
                    subtitle: Text(
                      usesFirebase
                          ? 'Tasks are stored in Cloud Firestore'
                          : 'Tasks are saved on this device',
                    ),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    enabled: completedCount > 0,
                    leading: const Icon(Icons.done_all),
                    title: const Text('Clear completed tasks'),
                    subtitle: Text(
                      completedCount == 0
                          ? 'Nothing to clear'
                          : completedCount == 1
                              ? '1 completed task'
                              : '$completedCount completed tasks',
                    ),
                    onTap: () => _confirmClearCompleted(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sign Out Section
            const _SectionHeader('Session'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: Icon(Icons.logout, color: scheme.error),
                title: Text('Sign out', style: TextStyle(color: scheme.error)),
                subtitle: const Text('Log out from this device'),
                onTap: () => _confirmSignOut(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
