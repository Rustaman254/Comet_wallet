import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/toast_service.dart';
import '../services/session_service.dart';

class ResetPinScreen extends StatefulWidget {
  const ResetPinScreen({super.key});

  @override
  State<ResetPinScreen> createState() => _ResetPinScreenState();
}

class _ResetPinScreenState extends State<ResetPinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // PIN state
  String _newPin = '';
  String _confirmPin = '';
  bool _isConfirmingPin = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    SessionService.recordActivity();
    setState(() {
      if (!_isConfirmingPin) {
        if (_newPin.length < 4) {
          _newPin += number;
          if (_newPin.length == 4) {
            // Move to confirm step after a brief delay
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) setState(() => _isConfirmingPin = true);
            });
          }
        }
      } else {
        if (_confirmPin.length < 4) {
          _confirmPin += number;
          if (_confirmPin.length == 4) {
            // Auto-submit after confirm PIN is complete
            Future.delayed(const Duration(milliseconds: 300), () {
              _handleSubmit();
            });
          }
        }
      }
    });
  }

  void _onBackspace() {
    SessionService.recordActivity();
    setState(() {
      if (!_isConfirmingPin) {
        if (_newPin.isNotEmpty) {
          _newPin = _newPin.substring(0, _newPin.length - 1);
        }
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          // Go back to entering new PIN
          _isConfirmingPin = false;
          _newPin = '';
        }
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (_passwordController.text.isEmpty) {
      ToastService().showError(context, 'Please enter your password');
      return;
    }

    if (_newPin.length < 4) {
      ToastService().showError(context, 'PIN must be 4 digits');
      return;
    }

    if (_newPin != _confirmPin) {
      ToastService().showError(context, 'PINs do not match');
      setState(() {
        _confirmPin = '';
        _isConfirmingPin = false;
        _newPin = '';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.resetPin(
        password: _passwordController.text,
        newPin: _newPin,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ToastService().showSuccess(context, result['message'] ?? 'PIN reset successfully');
        Navigator.of(context).pop(true);
      } else {
        ToastService().showError(context, result['message'] ?? 'Failed to reset PIN');
        setState(() {
          _confirmPin = '';
          _newPin = '';
          _isConfirmingPin = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastService().showError(context, 'Failed to reset PIN. Please try again.');
        setState(() {
          _confirmPin = '';
          _newPin = '';
          _isConfirmingPin = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPin = _isConfirmingPin ? _confirmPin : _newPin;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: getTextColor(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Reset PIN',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: getTextColor(context),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 24.h),

                      // Password field
                      Text(
                        'Current Password',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: getSecondaryTextColor(context),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 16.sp,
                          color: getTextColor(context),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle: TextStyle(
                            fontFamily: 'Satoshi',
                            color: getTertiaryTextColor(context),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(color: getBorderColor(context)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(color: getBorderColor(context)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(color: primaryBrandColor, width: 1.5),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: getSecondaryTextColor(context),
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),

                      SizedBox(height: 40.h),

                      // PIN instruction
                      Text(
                        _isConfirmingPin ? 'Confirm New PIN' : 'Enter New PIN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: getTextColor(context),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _isConfirmingPin
                            ? 'Re-enter your new 4-digit PIN'
                            : 'Choose a 4-digit PIN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 14.sp,
                          color: getSecondaryTextColor(context),
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // PIN dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final isFilled = index < currentPin.length;
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 12.w),
                            width: 20.r,
                            height: 20.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFilled ? primaryBrandColor : Colors.transparent,
                              border: Border.all(
                                color: isFilled
                                    ? primaryBrandColor
                                    : (isDark ? Colors.white30 : Colors.grey.shade400),
                                width: 2,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Keypad
            if (_isLoading)
              Padding(
                padding: EdgeInsets.all(48.r),
                child: CircularProgressIndicator(color: primaryBrandColor),
              )
            else
              _buildKeypad(isDark),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 48.w),
      child: Column(
        children: [
          _buildKeypadRow(['1', '2', '3'], isDark),
          SizedBox(height: 16.h),
          _buildKeypadRow(['4', '5', '6'], isDark),
          SizedBox(height: 16.h),
          _buildKeypadRow(['7', '8', '9'], isDark),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Empty space
              SizedBox(width: 64.r, height: 64.r),
              // 0
              _buildKeypadButton('0', isDark),
              // Backspace
              SizedBox(
                width: 64.r,
                height: 64.r,
                child: IconButton(
                  onPressed: _onBackspace,
                  icon: Icon(
                    Icons.backspace_outlined,
                    color: getTextColor(context),
                    size: 24.r,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> numbers, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((n) => _buildKeypadButton(n, isDark)).toList(),
    );
  }

  Widget _buildKeypadButton(String number, bool isDark) {
    return GestureDetector(
      onTap: () => _onNumberPressed(number),
      child: Container(
        width: 64.r,
        height: 64.r,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          number,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: getTextColor(context),
          ),
        ),
      ),
    );
  }
}
