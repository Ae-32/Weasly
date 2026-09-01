import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../providers/pin_provider.dart';
import '../../utils/app_colors.dart';

/// Screen presented when biometric lock is active upon app launch.
class BiometricLockScreen extends ConsumerStatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  ConsumerState<BiometricLockScreen> createState() =>
      _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometricAuth();
    });
  }

  Future<void> _triggerBiometricAuth() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final biometricService = ref.read(biometricServiceProvider);
    final authenticated = await biometricService.authenticate(
      localizedReason: 'Authenticate to access your Weasly stashes',
    );

    if (!mounted) return;

    if (authenticated) {
      ref.read(biometricUnlockedProvider.notifier).unlock();
      ref.read(isPinUnlockedProvider.notifier).unlock();
    } else {
      setState(() {
        _isAuthenticating = false;
        _errorMessage =
            'Biometric authentication cancelled or failed. Tap below to try again or use PIN/password.';
      });
    }
  }

  void _usePinInstead() {
    ref.read(biometricUnlockedProvider.notifier).unlock();
  }

  Future<void> _usePasswordInstead() async {
    ref.read(biometricUnlockedProvider.notifier).lock();
    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final userEmail = user?.email ?? 'Logged in user';
    final isPinSet = ref.watch(isPinSetProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Weasly App Logo Badge
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/images/Weasly_Logo.png'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(43, 36, 32, 0.08),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Weasly is Locked',
                style: GoogleFonts.quicksand(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Signed in as $userEmail',
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.stateError.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.stateError.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      color: AppColors.stateError,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Unlock Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isAuthenticating ? null : _triggerBiometricAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.fingerprint_rounded, size: 24),
                  label: Text(
                    _isAuthenticating ? 'Authenticating...' : 'Unlock with Biometrics',
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Use PIN instead / Use password instead Option
              TextButton(
                onPressed: isPinSet ? _usePinInstead : _usePasswordInstead,
                child: Text(
                  isPinSet ? 'Use PIN instead' : 'Use password instead',
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentPrimary,
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
