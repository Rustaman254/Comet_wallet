import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../services/vibration_service.dart';
import '../services/toast_service.dart';
import '../services/wallet_service.dart';
import '../services/token_service.dart';
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
  bool _isLoading = false;

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
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    if (_pin.length < 4 && !_isLoading) {
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
    if (_pin.isNotEmpty && !_isLoading) {
      VibrationService.lightImpact();
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    if (_pin == _correctPin) {
      setState(() {
        _isLoading = true;
      });

      try {
        Map<String, dynamic> response;
        if (widget.onVerify != null) {
          response = await widget.onVerify!();
        } else {
          final amount = double.tryParse(widget.amount.replaceAll(',', '')) ?? 0.0;
          response = await WalletService.sendMoney(
            recipientPhone: widget.recipientName,
            amount: amount,
            currency: widget.currency,
            description: widget.description,
          );
        }

        if (mounted) {
          _showSuccessDialog(response['transaction_id'] ?? response['gateway_transaction_id'] ?? 'N/A');
        }
      } catch (e) {
        if (mounted) {
          final errorMsg = e.toString();
          if (errorMsg.contains('401') || errorMsg.contains('expired')) {
            ToastService().showError(context, 'Session expired. Please login again.');
            await TokenService.logout();
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                (route) => false,
              );
            }
          } else {
            ToastService().showError(context, 'Transaction failed: $e');
            setState(() {
              _pin = '';
              _isLoading = false;
            });
          }
        }
      }
    } else {
      VibrationService.errorVibrate();
      _shakeController.forward(from: 0.0).then((_) {
        setState(() {
          _pin = '';
        });
      });
      
      if (mounted) {
        ToastService().showError(
          context,
          'Incorrect PIN. Please try again.',
        );
      }
    }
  }

  void _showSuccessDialog(String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
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
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              '${widget.currency} ${widget.amount}',
              style: GoogleFonts.poppins(
                color: buttonGreen,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              'sent to ${widget.recipientName}',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'ID: $transactionId',
              style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 12.sp,
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
                  style: GoogleFonts.poppins(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            children: [
              SizedBox(height: 20.h),
              // Back button
              Row(
                children: [
                  GestureDetector(
                    onTap: _isLoading ? null : () => Navigator.pop(context),
                    child: Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20.r,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40.h),
              // Profile picture
              Container(
                width: 80.r,
                height: 80.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: buttonGreen, width: 3.w),
                  color: Colors.grey[800],
                ),
                child: Center(
                  child: Text(
                    widget.recipientName.isNotEmpty ? widget.recipientName[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              // Recipient name
              Text(
                'Sending to',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                widget.recipientName,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 50.h),
              
              if (_isLoading) ...[
                const CircularProgressIndicator(color: buttonGreen),
                SizedBox(height: 20.h),
                Text(
                  'Processing transaction...',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14.sp),
                ),
              ] else ...[
                // Enter PIN text
                Text(
                  'Enter your PIN',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 30.h),
                // PIN dots with shake animation
                AnimatedBuilder(
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
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 16.r,
                          height: 16.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index < _pin.length
                                ? buttonGreen
                                : Colors.white.withValues(alpha: 0.3),
                            border: Border.all(
                              color: index < _pin.length
                                  ? buttonGreen
                                  : Colors.white.withValues(alpha: 0.3),
                              width: 2.w,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
              const Spacer(),
              // Numeric keypad
              if (!_isLoading) _buildKeypad(),
              SizedBox(height: 40.h),
            ],
          ),
        ),
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
            _buildKeyActionButton(
              onPressed: () {},
              icon: Icons.fingerprint,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String number) {
    return GestureDetector(
      onTap: () => _onNumberPressed(number),
      child: Container(
        width: 70.r,
        height: 70.r,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            number,
            style: GoogleFonts.poppins(
              color: Colors.white,
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
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 70.r,
        height: 70.r,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.white,
            size: 24.r,
          ),
        ),
      ),
    );
  }
}
