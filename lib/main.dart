import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/app_services.dart';
import 'services/firebase_bootstrap.dart';
import 'theme/app_theme.dart';
import 'widgets/loading_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final firebaseReady = await FirebaseBootstrap.init();

  runApp(
    FirebaseTaskManagerApp(
      services: firebaseReady
          ? AppServices.firebase(preferences)
          : AppServices.local(preferences),
    ),
  );
}

class FirebaseTaskManagerApp extends StatelessWidget {
  const FirebaseTaskManagerApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppServices>.value(value: services),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(services.preferences),
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider(services.auth)),
        // Not lazy: it must start following AuthProvider straight away.
        ChangeNotifierProvider(
          lazy: false,
          create: (context) => TaskProvider(
            services.tasks,
            context.read<AuthProvider>(),
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Task Manager',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

/// Persistent Authentication Gate
/// Automatically redirects users to HomeScreen if authenticated or LoginScreen if unauthenticated.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final Widget screen;
    if (!authProvider.isReady) {
      // The saved session is still being restored.
      screen = const Scaffold(key: ValueKey('splash'), body: LoadingWidget());
    } else if (authProvider.isAuthenticated) {
      screen = const HomeScreen(key: ValueKey('home'));
    } else {
      screen = const LoginScreen(key: ValueKey('login'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: screen,
    );
  }
}
