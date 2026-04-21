import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../constants/colors.dart';
import '../utils/responsive_utils.dart';
import 'reset_password_screen.dart';

class VerifyTokenScreen extends StatefulWidget {
  final String email;

  const VerifyTokenScreen({super.key, required this.email});

  @override
  State<VerifyTokenScreen> createState() => _VerifyTokenScreenState();
}

class _VerifyTokenScreenState extends State<VerifyTokenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus the hidden field to bring up the keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyToken() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.verifyTokenEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'otp': _tokenController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (data['message'] == 'OTP is valid' || data['message'] == 'Token is valid')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('OTP verified!'),
            backgroundColor: Colors.green[700],
          ),
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              email: widget.email,
              otp: _tokenController.text.trim(),
            ),
          ),
        );
      } else {
        _showError(data['message'] ?? 'Invalid or expired OTP.');
      }
    } catch (_) {
      if (mounted) _showError('Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[700]),
    );
  }

  Widget _buildDashPin() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final otpText = _tokenController.text;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < otpText.length;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: SizedBox(
            width: 40.w,
            height: 48.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // dash background
                Positioned(
                  bottom: 12.h,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 2.h,
                    width: 32.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999.r),
                      color: isFilled
                          ? primaryBrandColor
                          : (isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
                // digit when filled
                if (isFilled)
                  Text(
                    otpText[index],
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24.h),
                    Text(
                      'Verify OTP',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: textColor,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Enter the 6-digit OTP code sent to your email to verify your identity.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: subTextColor,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 64.h),
                    
                    // Hidden TextField for keyboard input
                    Opacity(
                      opacity: 0,
                      child: SizedBox(
                        height: 0,
                        child: TextFormField(
                          controller: _tokenController,
                          focusNode: _focusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          onChanged: (value) => setState(() {}),
                          validator: (value) {
                            if (value == null || value.trim().length < 6) {
                              return 'Please enter the 6-digit OTP';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    
                    GestureDetector(
                      onTap: () => _focusNode.requestFocus(),
                      child: Center(
                        child: _buildDashPin(),
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // Logic for resending OTP handled elsewhere or placeholder here
                        },
                        child: Text(
                          'Didn\'t receive code? Resend',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: primaryBrandColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyToken,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBrandColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Verify OTP',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          const ModalBarrier(dismissible: false, color: Colors.black38),
      ],
    );
  }
}
