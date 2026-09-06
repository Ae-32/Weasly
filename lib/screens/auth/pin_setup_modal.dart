import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/pin_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/success_banner.dart';

enum PinSetupMode { setup, change, remove }

/// Modal bottom sheet for creating, changing, or removing a PIN lock.
class PinSetupModal extends ConsumerStatefulWidget {
  final PinSetupMode mode;

  const PinSetupModal({super.key, required this.mode});

  static Future<bool?> show(BuildContext context, {required PinSetupMode mode}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PinSetupModal(mode: mode),
    );
  }

  @override
  ConsumerState<PinSetupModal> createState() => _PinSetupModalState();
}

class _PinSetupModalState extends ConsumerState<PinSetupModal> {
  String _enteredPin = '';
  String _firstPinAttempt = '';
  String? _errorMessage;
  int _step = 0; // 0 = Current PIN (for change/remove) or New PIN (for setup), 1 = Confirm PIN

  @override
  void initState() {
    super.initState();
    if (widget.mode == PinSetupMode.setup) {
      _step = 0; // Create New PIN
    } else {
      _step = 0; // Enter Current PIN
    }
  }

  String get _stepTitle {
    if (widget.mode == PinSetupMode.setup) {
      return _step == 0 ? 'Create a 4-6 Digit PIN' : 'Confirm Your PIN';
    } else if (widget.mode == PinSetupMode.change) {
      if (_step == 0) return 'Enter Current PIN';
      if (_step == 1) return 'Create New 4-6 Digit PIN';
      return 'Confirm New PIN';
    } else {
      return 'Enter Current PIN to Remove';
    }
  }

  String get _stepSubtitle {
    if (widget.mode == PinSetupMode.setup) {
      return _step == 0
          ? 'Enter 4 to 6 numbers to secure your app'
          : 'Re-enter your PIN to confirm';
    } else if (widget.mode == PinSetupMode.change) {
      if (_step == 0) return 'Verify your identity before changing';
      if (_step == 1) return 'Enter your new 4 to 6 digit PIN';
      return 'Re-enter your new PIN to confirm';
    } else {
      return 'Verify your current PIN to disable PIN lock';
    }
  }

  void _onKeyPress(String digit) {
    if (_enteredPin.length >= 6) return;
    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  void _onClear() {
    setState(() {
      _enteredPin = '';
      _errorMessage = null;
    });
  }

  Future<void> _onNextOrSubmit() async {
    if (_enteredPin.length < 4) {
      setState(() {
        _errorMessage = 'PIN must be at least 4 digits long.';
      });
      return;
    }

    final pinNotifier = ref.read(isPinSetProvider.notifier);

    // MODE: SETUP
    if (widget.mode == PinSetupMode.setup) {
      if (_step == 0) {
        _firstPinAttempt = _enteredPin;
        setState(() {
          _enteredPin = '';
          _step = 1;
          _errorMessage = null;
        });
      } else {
        if (_enteredPin != _firstPinAttempt) {
          setState(() {
            _errorMessage = 'PINs do not match. Please try again.';
            _enteredPin = '';
            _step = 0;
            _firstPinAttempt = '';
          });
        } else {
          await pinNotifier.setupPin(_enteredPin);
          if (mounted) {
            SuccessBanner.show(context, 'PIN set up successfully!');
            Navigator.of(context).pop(true);
          }
        }
      }
    }
    // MODE: CHANGE
    else if (widget.mode == PinSetupMode.change) {
      if (_step == 0) {
        final isValid = await pinNotifier.verifyPin(_enteredPin);
        if (!isValid) {
          setState(() {
            _errorMessage = 'Incorrect current PIN. Please try again.';
            _enteredPin = '';
          });
        } else {
          setState(() {
            _enteredPin = '';
            _step = 1;
            _errorMessage = null;
          });
        }
      } else if (_step == 1) {
        _firstPinAttempt = _enteredPin;
        setState(() {
          _enteredPin = '';
          _step = 2;
          _errorMessage = null;
        });
      } else {
        if (_enteredPin != _firstPinAttempt) {
          setState(() {
            _errorMessage = 'New PINs do not match. Try again.';
            _enteredPin = '';
            _step = 1;
            _firstPinAttempt = '';
          });
        } else {
          await pinNotifier.setupPin(_enteredPin);
          if (mounted) {
            SuccessBanner.show(context, 'PIN updated!');
            Navigator.of(context).pop(true);
          }
        }
      }
    }
    // MODE: REMOVE
    else if (widget.mode == PinSetupMode.remove) {
      final isValid = await pinNotifier.verifyPin(_enteredPin);
      if (!isValid) {
        setState(() {
          _errorMessage = 'Incorrect PIN. Cannot remove PIN lock.';
          _enteredPin = '';
        });
      } else {
        await pinNotifier.removePin();
        if (mounted) {
          SuccessBanner.show(context, 'PIN removed!');
          Navigator.of(context).pop(true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title & Subtitle
            Text(
              _stepTitle,
              style: GoogleFonts.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _stepSubtitle,
              style: GoogleFonts.quicksand(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // PIN Dots Display
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

            // Error Message Banner
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
            ],

            // Numeric Keypad Grid
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
                  // Clear Button
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
                  // Digit 0
                  return _buildKeypadButton('0');
                } else if (index == 11) {
                  // Backspace Button
                  return IconButton(
                    onPressed: _onBackspace,
                    icon: const Icon(
                      Icons.backspace_outlined,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  );
                }
                // Digits 1-9
                return _buildKeypadButton('${index + 1}');
              },
            ),
            const SizedBox(height: 20),

            // Continue / Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _enteredPin.length >= 4 ? _onNextOrSubmit : null,
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
                child: Text(
                  (_step == 0 && widget.mode == PinSetupMode.setup) ||
                          (_step < 2 && widget.mode == PinSetupMode.change)
                      ? 'Continue'
                      : (widget.mode == PinSetupMode.remove
                          ? 'Remove PIN'
                          : 'Save PIN'),
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
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
