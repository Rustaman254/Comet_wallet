import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../utils/responsive_utils.dart';
import '../services/vibration_service.dart';
import 'main_wrapper.dart';
import '../services/token_service.dart';
import '../services/auth_service.dart';

class VerifyPinScreen extends StatefulWidget {
  final Widget? nextScreen;
  const VerifyPinScreen({super.key, this.nextScreen});

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  final String _correctPin = '1234';
  String _userName = 'User';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -10, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _loadUserData() async {
    final name = await TokenService.getUserName();
    if (name != null && name.isNotEmpty && mounted) {
      setState(() {
        _userName = name;
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    if (_pin.length < 4 && !_isVerifying) {
      VibrationService.lightImpact();
      setState(() {
        _pin += number;
      });

      // Auto-verify when 4 digits entered
      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty && !_isVerifying) {
      VibrationService.lightImpact();
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _showLoaderDialog() async {
    setState(() {
      _isVerifying = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) {
        return Center(
          child: Container(
            width: 140.r,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: buttonGreen.withValues(alpha: 0.4),
                width: 1.5.w,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: buttonGreen),
                SizedBox(height: 16.h),
                Text(
                  'Verifying PIN...',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _hideLoaderDialog() async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (mounted) {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    await _showLoaderDialog();

    // Use try-catch for network/API errors
    try {
      final isVerified = await AuthService.verifyPin(_pin);
      
      if (!mounted) return;
      await _hideLoaderDialog();

      if (isVerified) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => widget.nextScreen ?? const MainWrapper(),
          ),
        );
      } else {
        VibrationService.errorVibrate();
        _shakeController.forward(from: 0.0).then((_) {
          if (mounted) {
            setState(() {
              _pin = '';
            });
          }
        });
        
        // Optional: Show toast or snackbar for feedback
        // ToastService().showError(context, 'Incorrect PIN');
      }
    } catch (e) {
      if (!mounted) return;
      await _hideLoaderDialog();
      
      // Handle error (network, server, etc.)
       VibrationService.errorVibrate();
       _shakeController.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() {
            _pin = '';
          });
        }
      });
      // ToastService().showError(context, e.toString());
    }
  }

  void _onBiometric() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainWrapper()),
    );
  }

  String getInitials(String name) {
    List<String> nameParts = name.trim().split(' ');
    String initials = '';

    if (nameParts.isNotEmpty) {
      initials = nameParts[0][0].toUpperCase();
      if (nameParts.length > 1) {
        initials += nameParts[nameParts.length - 1][0].toUpperCase();
      }
    }
    return initials;
  }

  /// Dashes + asterisk for filled ones
  Widget _buildDashPin() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final isFilled = index < _pin.length;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: SizedBox(
              width: 32.w,
              height: 32.h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // dash background
                  Positioned(
                    bottom: 8.h,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 2.h,
                      width: 32.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999.r),
                        color: isFilled
                            ? buttonGreen
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  // * when filled
                  if (isFilled)
                    Text(
                      '*',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) {
        return _buildKeypadButton(
          onPressed: () => _onNumberPressed(number),
          child: Text(
            number,
            style: TextStyle(
              fontFamily: 'Satoshi',
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: _isVerifying ? null : onPressed,
      child: Container(
        width: 70.r,
        height: 70.r,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        SizedBox(height: 16.h),
        _buildKeypadRow(['4', '5', '6']),
        SizedBox(height: 16.h),
        _buildKeypadRow(['7', '8', '9']),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton(
              onPressed: _onBackspace,
              child: const Icon(
                Icons.backspace_outlined,
                color: Colors.white,
              ),
            ),
            _buildKeypadButton(
              onPressed: () => _onNumberPressed('0'),
              child: Text(
                '0',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _buildKeypadButton(
              onPressed: _onBiometric,
              child: const Icon(
                Icons.fingerprint,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // match login page
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40.h),
              Center(
                child: Container(
                  width: 80.r,
                  height: 80.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: buttonGreen, width: 3.w),
                    color: Colors.grey[800],
                  ),
                  child: Center(
                    child: Text(
                      getInitials(_userName),
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: Colors.white,
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _userName,
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50.h),
              Center(
                child: Text(
                  'Enter your PIN',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 30.h),
              _buildDashPin(),
              const Spacer(),
              _buildKeypad(),
              SizedBox(height: 20.h),
              Center(
                child: TextButton(
                  onPressed: _isVerifying
                      ? null
                      : () {
                          // TODO: forgot PIN flow
                        },
                  child: Text(
                    'Forgot PIN?',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: buttonGreen,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
