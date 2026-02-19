import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/colors.dart';
import '../utils/responsive_utils.dart';
import '../services/vibration_service.dart';
import '../services/biometric_service.dart';
import 'main_wrapper.dart';
import '../services/token_service.dart';
import '../services/auth_service.dart';
import 'sign_in_screen.dart';

class VerifyPinScreen extends StatefulWidget {
  final Widget? nextScreen;
  const VerifyPinScreen({super.key, this.nextScreen});

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen>
    with TickerProviderStateMixin {
  String _pin = '';
  final String _correctPin = '1234';
  String _userName = 'User';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  // Biometric Animation
  late AnimationController _biometricPulseController;
  late Animation<double> _biometricScaleAnimation;
  late Animation<Color?> _biometricColorAnimation;

  bool _isVerifying = false;
  bool _biometricsAvailable = false;
  bool _hasFaceID = false;
  bool _hasFingerprint = false;
  bool _isBiometricScanning = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // Shake Animation
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

    // Biometric Pulse Animation
    _biometricPulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _biometricScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _biometricPulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    _biometricColorAnimation = ColorTween(
      begin: buttonGreen,
      end: buttonGreen.withOpacity(0.5),
    ).animate(
      CurvedAnimation(
        parent: _biometricPulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Check biometrics and auto-trigger
    _checkBiometrics();
  }

  Future<void> _loadUserData() async {
    final name = await TokenService.getUserName();
    if (name != null && name.isNotEmpty && mounted) {
      setState(() {
        _userName = name;
      });
    }
  }

  Future<void> _checkBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('biometric_enabled') ?? false; // Default to false if not set
    
    if (!isEnabled) {
      if (mounted) setState(() => _biometricsAvailable = false);
      return;
    }

    final isAvailable = await BiometricService.isAvailable();
    final hasFace = await BiometricService.hasFaceID();
    final hasFingerprint = await BiometricService.hasFingerprint();
    
    if (mounted) {
      setState(() {
        _biometricsAvailable = isAvailable;
        _hasFaceID = hasFace;
        _hasFingerprint = hasFingerprint;
      });
      
      // Auto-prompt biometric authentication if available
      if (_biometricsAvailable) {
        // Small delay to let UI settle
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _onBiometric();
        }
      }
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _biometricPulseController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    if (_pin.length < 4 && !_isVerifying) {
      VibrationService.lightImpact();
      setState(() {
        _pin += number;
      });

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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                minWidth: 150.w,
                maxWidth: 280.w,
              ),
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: buttonGreen),
                  SizedBox(height: 16.h),
                  Text(
                    'Verifying PIN...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
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
      }
    } on TokenExpiredException catch (e) {
      // Token expired - redirect to login
      if (!mounted) return;
      await _hideLoaderDialog();
      
      if (mounted && context.mounted) {
        // Navigate to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      await _hideLoaderDialog();
      
      VibrationService.errorVibrate();
      _shakeController.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() {
            _pin = '';
          });
        }
      });
    }
  }

  Future<void> _onBiometric() async {
    if (!_biometricsAvailable || _isVerifying || _isBiometricScanning) return;
    
    setState(() {
      _isBiometricScanning = true;
    });
    _biometricPulseController.repeat(reverse: true);

    try {
      // Add timeout to prevent infinite loop
      final authenticated = await BiometricService.authenticate(
        localizedReason: 'Authenticate to access your wallet',
        useErrorDialogs: true,
        stickyAuth: true,
      ).timeout(
        const Duration(seconds: 30), 
        onTimeout: () => false,
      );
      
      if (!mounted) return;

      if (authenticated) {
        // Stop animation immediately on success
        _biometricPulseController.stop();
        
        // Use WidgetsBinding to ensure navigation happens in next frame with valid context
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => widget.nextScreen ?? const MainWrapper()),
            );
          }
        });
      } else {
        // Handle failure/cancel
        VibrationService.errorVibrate();
      }
    } catch (e) {
      debugPrint('Biometric error: $e');
      if (mounted) {
        VibrationService.errorVibrate();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBiometricScanning = false;
        });
        _biometricPulseController.stop();
        _biometricPulseController.reset();
      }
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                            : (isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withOpacity(0.3)),
                      ),
                    ),
                  ),
                  // * when filled
                  if (isFilled)
                    Text(
                      '*',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: isDark ? Colors.white : Colors.black,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) {
        return _buildKeypadButton(
          onPressed: () => _onNumberPressed(number),
          child: Text(
            number,
            style: TextStyle(
              fontFamily: 'Satoshi',
              color: isDark ? Colors.white : Colors.black,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: _isVerifying ? null : onPressed,
      child: Container(
        width: 70.r,
        height: 70.r,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF6F6F6),
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return GestureDetector(
      onTap: _isVerifying ? null : _onBiometric,
      child: AnimatedBuilder(
        animation: _biometricPulseController,
        builder: (context, child) {
          return Container(
            width: 70.r,
            height: 70.r,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: _isBiometricScanning
                  ? [
                      BoxShadow(
                        color: buttonGreen.withOpacity(0.3),
                        blurRadius: 10 * _biometricPulseController.value,
                        spreadRadius: 2 * _biometricPulseController.value,
                      )
                    ]
                  : [],
            ),
            child: Transform.scale(
              scale: _isBiometricScanning ? _biometricScaleAnimation.value : 1.0,
              child: Center(
                child: Icon(
                  _hasFaceID ? Icons.face : Icons.fingerprint,
                  color: _isBiometricScanning 
                      ? _biometricColorAnimation.value 
                      : buttonGreen,
                  size: 28,
                ),
              ),
            ),
          );
        },
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
              child: Icon(
                Icons.backspace_outlined,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
            ),
            _buildKeypadButton(
              onPressed: () => _onNumberPressed('0'),
              child: Text(
                '0',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _biometricsAvailable
                ? _buildBiometricButton()
                : SizedBox(width: 70.r, height: 70.r),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.r, vertical: 12.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24.h,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20.h),
                      Center(
                        child: Container(
                          width: 80.r,
                          height: 80.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey[800] 
                                : const Color(0xFFF6F6F6),
                          ),
                          child: Center(
                            child: Text(
                              getInitials(_userName),
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white 
                                    : Colors.black,
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
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white.withOpacity(0.7) 
                                    : Colors.black.withOpacity(0.7),
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              _userName,
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white 
                                    : Colors.black,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30.h),
                      Center(
                        child: Text(
                          'Enter your PIN',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white 
                                : Colors.black,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      _buildDashPin(),
                      const Spacer(),
                      SizedBox(height: 20.h),
                      _buildKeypad(),
                      SizedBox(height: 16.h),
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
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}
