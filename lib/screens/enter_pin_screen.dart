import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/colors.dart';
import '../services/vibration_service.dart';
import '../services/toast_service.dart';
import '../services/wallet_service.dart';
import '../services/token_service.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../utils/responsive_utils.dart';
import 'sign_in_screen.dart';

class EnterPinScreen extends StatefulWidget {
  final String recipientName;
  final String amount;
  final String currency;
  final String description;
  final Future<Map<String, dynamic>> Function()? onVerify;

  const EnterPinScreen({
    super.key,
    required this.recipientName,
    required this.amount,
    required this.currency,
    this.description = 'Money transfer',
    this.onVerify,
  });

  @override
  State<EnterPinScreen> createState() => _EnterPinScreenState();
}

class _EnterPinScreenState extends State<EnterPinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  final String _correctPin = '1234';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isVerifying = false; // for loader dialog state
  
  // Biometric state
  bool _biometricsAvailable = false;
  bool _hasFaceID = false;
  bool _hasFingerprint = false;

  @override
  void initState() {
    super.initState();
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
    
    // Check biometric availability
    _checkBiometrics();
  }
  
  Future<void> _checkBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('biometric_enabled') ?? false;
    
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
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    if (_pin.length < 4 && !_isVerifying) {
      VibrationService.selectionClick();
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
      VibrationService.selectionClick();
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
      // 1. Verify PIN via API
      final isVerified = await AuthService.verifyPin(_pin);
      
      if (!isVerified) {
        await _hideLoaderDialog();
        if (mounted) {
          VibrationService.errorVibrate();
          _shakeController.forward(from: 0.0).then((_) {
            if (mounted) {
              setState(() {
                _pin = '';
              });
            }
          });
          ToastService().showError(
            context,
            'Incorrect PIN. Please try again.',
          );
        }
        return;
      }

      // 2. PIN Verified, proceed with transaction
      Map<String, dynamic> response;
      if (widget.onVerify != null) {
        response = await widget.onVerify!();
      } else {
        final amount =
            double.tryParse(widget.amount.replaceAll(',', '')) ?? 0.0;
        response = await WalletService.sendMoney(
          recipientPhone: widget.recipientName,
          amount: amount,
          currency: widget.currency,
          description: widget.description,
        );
      }

      await _hideLoaderDialog();

      if (mounted) {
        VibrationService.lightImpact();
        _showSuccessDialog(
          response['transaction_id'] ??
              response['gateway_transaction_id'] ??
              'N/A',
        );
      }
    } catch (e) {
      await _hideLoaderDialog();
      if (!mounted) return;

      final errorMsg = e.toString();
      
      // Handle session expiration separately (requires logout + navigation)
      if (errorMsg.contains('401') || errorMsg.contains('expired') || errorMsg.contains('unauthorized')) {
        ToastService()
            .showError(context, 'Session expired. Please login again.');
        await TokenService.logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SignInScreen()),
            (route) => false,
          );
        }
      } else {
        // Show user-friendly error dialog for all other errors
        VibrationService.errorVibrate();
        setState(() {
          _pin = '';
        });
        _shakeController.forward(from: 0.0);
        
        if (mounted) {
          final friendlyMessage = _parseErrorMessage(errorMsg);
          _showFailureDialog(friendlyMessage);
        }
      }
    }
  }

  Future<void> _onBiometric() async {
    if (!_biometricsAvailable || _isVerifying) return;
    
    try {
      final authenticated = await BiometricService.authenticate(
        localizedReason: 'Authenticate to authorize this payment',
        useErrorDialogs: true,
        stickyAuth: true,
      ).timeout(
        const Duration(seconds: 30), 
        onTimeout: () => false,
      );
      
      if (!mounted) return;

      if (authenticated) {
        // Biometric authentication successful, proceed with payment
        await _showLoaderDialog();
        
        try {
          // Process the transaction
          Map<String, dynamic> response;
          if (widget.onVerify != null) {
            response = await widget.onVerify!();
          } else {
            final amount =
                double.tryParse(widget.amount.replaceAll(',', '')) ?? 0.0;
            response = await WalletService.sendMoney(
              recipientPhone: widget.recipientName,
              amount: amount,
              currency: widget.currency,
              description: widget.description,
            );
          }

          await _hideLoaderDialog();

          if (mounted) {
            VibrationService.lightImpact();
            _showSuccessDialog(
              response['transaction_id'] ??
                  response['gateway_transaction_id'] ??
                  'N/A',
            );
          }
        } catch (e) {
          await _hideLoaderDialog();
          if (!mounted) return;

          final errorMsg = e.toString();
          
          // Handle session expiration
          if (errorMsg.contains('401') || errorMsg.contains('expired') || errorMsg.contains('unauthorized')) {
            ToastService()
                .showError(context, 'Session expired. Please login again.');
            await TokenService.logout();
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                (route) => false,
              );
            }
          } else {
            VibrationService.errorVibrate();
            if (mounted) {
              final friendlyMessage = _parseErrorMessage(errorMsg);
              _showFailureDialog(friendlyMessage);
            }
          }
        }
      } else {
        // Biometric authentication failed or cancelled
        VibrationService.errorVibrate();
      }
    } catch (e) {
      debugPrint('Biometric error: $e');
      if (mounted) {
        VibrationService.errorVibrate();
      }
    }
  }

  void _showFailureDialog(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.r,
              height: 80.r,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 50.r,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Transaction Failed',
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: Colors.white70,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 30.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Try Again',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _parseErrorMessage(String error) {
    // Remove "Exception:" prefix
    String cleaned = error.replaceAll('Exception:', '').trim();
    
    // Handle common error patterns
    if (cleaned.toLowerCase().contains('socketexception') || 
        cleaned.toLowerCase().contains('failed host lookup') ||
        cleaned.toLowerCase().contains('network')) {
      return 'Network connection error. Please check your internet connection and try again.';
    }
    
    if (cleaned.toLowerCase().contains('insufficient') && 
        cleaned.toLowerCase().contains('fund')) {
      return 'Insufficient funds in your wallet. Please top up and try again.';
    }
    
    if (cleaned.toLowerCase().contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    if (cleaned.toLowerCase().contains('not found') || 
        cleaned.toLowerCase().contains('404')) {
      return 'Recipient not found. Please verify the phone number.';
    }
    
    if (cleaned.toLowerCase().contains('unauthorized') || 
        cleaned.toLowerCase().contains('401')) {
      return 'Session expired. Please login again.';
    }
    
    // If we have a clean message without technical jargon, use it
    if (!cleaned.contains('error:') && 
        !cleaned.contains('Error:') && 
        cleaned.length < 100) {
      return cleaned;
    }
    
    // Default fallback
    return 'Transaction failed. Please try again or contact support.';
  }

  void _showSuccessDialog(String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.r,
              height: 80.r,
              decoration: BoxDecoration(
                color: buttonGreen.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: buttonGreen,
                size: 50.r,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Payment Successful!',
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              '${widget.currency} ${widget.amount}',
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: buttonGreen,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              'sent to ${widget.recipientName}',
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: Colors.white70,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 30.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonGreen,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Done',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 16.sp,
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
                  // Dash background
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
                  // Asterisk when filled
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

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((n) => _buildKeypadButton(n)).toList(),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((n) => _buildKeypadButton(n)).toList(),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((n) => _buildKeypadButton(n)).toList(),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeyActionButton(
              onPressed: _onBackspace,
              icon: Icons.backspace_outlined,
            ),
            _buildKeypadButton('0'),
            _biometricsAvailable
                ? _buildKeyActionButton(
                    onPressed: _onBiometric,
                    icon: _hasFaceID ? Icons.face : Icons.fingerprint,
                    color: buttonGreen,
                  )
                : SizedBox(width: 70.r, height: 70.r),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String number) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _onNumberPressed(number),
      child: Container(
        width: 70.r,
        height: 70.r,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF6F6F6),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            number,
            style: TextStyle(
              fontFamily: 'Satoshi',
              color: isDark ? Colors.white : Colors.black,
              fontSize: 24.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    Color? color,
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
        child: Center(
          child: Icon(
            icon,
            color: color ?? (isDark ? Colors.white : Colors.black),
            size: 24.r,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              // Back button
              GestureDetector(
                onTap: _isVerifying ? null : () => Navigator.pop(context),
                child: Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white.withValues(alpha: 0.1) 
                        : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: getTextColor(context),
                    size: 20.r,
                  ),
                ),
              ),
              SizedBox(height: 40.h),
              Text(
                'Enter your PIN',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: getTextColor(context),
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Confirm this transaction securely.',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: getSecondaryTextColor(context),
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 32.h),
              // Amount & recipient (still themed)
              Text(
                '${widget.currency} ${widget.amount}',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: buttonGreen,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'to ${widget.recipientName}',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: getTextColor(context),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 40.h),
              // PIN dashes
              _buildDashPin(),
              const Spacer(),
              _buildKeypad(),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
