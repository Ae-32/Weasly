import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/biometric_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/pin_provider.dart';
import 'screens/auth/biometric_lock_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/pin_lock_screen.dart';
import 'screens/home_shell_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/firebase_service.dart';
import 'utils/app_theme.dart';
import 'widgets/loading_screen.dart';

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
    final isBiometricEnabled = ref.watch(biometricEnabledProvider);
    final isBiometricUnlocked = ref.watch(biometricUnlockedProvider);
    final isPinSet = ref.watch(isPinSetProvider);
    final isPinUnlocked = ref.watch(isPinUnlockedProvider);

    return MaterialApp(
      title: 'Weasly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.when(
        data: (user) {
          debugPrint('=== WEASLY AUTH ROUTING DEBUG ===');
          debugPrint('User signed in: ${user?.email}');
          debugPrint('isBiometricEnabled: $isBiometricEnabled');
          debugPrint('isBiometricUnlocked: $isBiometricUnlocked');
          debugPrint('isPinSet: $isPinSet');
          debugPrint('isPinUnlocked: $isPinUnlocked');
          debugPrint('=================================');

          if (user != null) {
            if (isBiometricEnabled && !isBiometricUnlocked) {
              debugPrint('ROUTING -> BiometricLockScreen');
              return const BiometricLockScreen();
            }
            if (isPinSet && !isPinUnlocked) {
              debugPrint('ROUTING -> PinLockScreen');
              return const PinLockScreen();
            }
            debugPrint('ROUTING -> HomeShellScreen (Dashboard)');
            return const HomeShellScreen();
          }
          if (!hasSeenOnboarding) {
            debugPrint('ROUTING -> OnboardingScreen');
            return const OnboardingScreen();
          }
          debugPrint('ROUTING -> LoginScreen');
          return const LoginScreen();
        },
        loading: () => const LoadingScreen(),
        error: (error, stack) => hasSeenOnboarding ? const LoginScreen() : const OnboardingScreen(),
      ),
    );
  }
}
