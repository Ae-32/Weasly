import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_shell_screen.dart';
import 'services/firebase_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();

  runApp(
    const ProviderScope(
      child: WeaslyApp(),
    ),
  );
}

class WeaslyApp extends ConsumerWidget {
  const WeaslyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Weasly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const HomeShellScreen();
          }
          return const LoginScreen();
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => const LoginScreen(),
      ),
    );
  }
}
