import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/onboarding_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_shell_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/firebase_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const WeaslyApp(),
    ),
  );
}

class WeaslyApp extends ConsumerWidget {
  const WeaslyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final hasSeenOnboarding = ref.watch(onboardingControllerProvider);

    return MaterialApp(
      title: 'Weasly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const HomeShellScreen();
          }
          if (!hasSeenOnboarding) {
            return const OnboardingScreen();
          }
          return const LoginScreen();
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => hasSeenOnboarding ? const LoginScreen() : const OnboardingScreen(),
      ),
    );
  }
}
