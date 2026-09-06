import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pin_provider.dart';
import '../../utils/app_colors.dart';

/// Screen presented when PIN lock is active upon app launch.
class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _enteredPin = '';
  String? _errorMessage;
  bool _isVerifying = false;

  void _onKeyPress(String digit) {
    if (_enteredPin.length >= 6 || _isVerifying) return;
    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty || _isVerifying) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  void _onClear() {
    if (_isVerifying) return;
    setState(() {
      _enteredPin = '';
      _errorMessage = null;
    });
  }

  Future<void> _verifyAndUnlock() async {
    if (_enteredPin.length < 4 || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final pinService = ref.read(pinServiceProvider);
    final isValid = await pinService.verifyPin(_enteredPin);

    if (!mounted) return;

    if (isValid) {
      ref.read(isPinUnlockedProvider.notifier).unlock();
    } else {
      setState(() {
        _isVerifying = false;
        _enteredPin = '';
        _errorMessage = 'Incorrect PIN. Please try again.';
      });
    }
  }

  Future<void> _handleForgotPin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Forgot your PIN?',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Logging out will reset your app lock. You can log back in anytime using your account password.',
          style: GoogleFonts.quicksand(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Log Out',
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(isPinUnlockedProvider.notifier).lock();
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final userEmail = user?.email ?? 'Logged in user';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            children: [
              const Spacer(),

              // Logo Badge
              Container(
                width: 84,
                height: 84,
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
              const SizedBox(height: 20),

              Text(
                'Weasly is Locked',
                style: GoogleFonts.quicksand(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                'Signed in as $userEmail',
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // PIN Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? AppColors.accentPrimary
                          : AppColors.borderDefault,
                      border: Border.all(
                        color: isFilled
                            ? AppColors.accentPrimary
                            : AppColors.textMutedLight,
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Error Message
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.stateError,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ] else
                const SizedBox(height: 12),

              // Keypad Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.6,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  if (index == 9) {
                    return TextButton(
                      onPressed: _onClear,
                      child: Text(
                        'Clear',
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                        ),
                      ),
                    );
                  } else if (index == 10) {
                    return _buildKeypadButton('0');
                  } else if (index == 11) {
                    return IconButton(
                      onPressed: _onBackspace,
                      icon: const Icon(
                        Icons.backspace_outlined,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    );
                  }
                  return _buildKeypadButton('${index + 1}');
                },
              ),
              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _enteredPin.length >= 4 && !_isVerifying
                      ? _verifyAndUnlock
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.accentPrimary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.lock_open_rounded, size: 20),
                  label: Text(
                    _isVerifying ? 'Verifying...' : 'Unlock',
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Forgot PIN Button
              TextButton(
                onPressed: _handleForgotPin,
                child: Text(
                  'Forgot PIN?',
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

  Widget _buildKeypadButton(String digit) {
    return Material(
      color: AppColors.bgSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _onKeyPress(digit),
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Text(
            digit,
            style: GoogleFonts.quicksand(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
