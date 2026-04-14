import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../constants/colors.dart';
import '../utils/responsive_utils.dart';
import '../utils/input_decoration.dart';
import 'sign_in_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordScreen({super.key, required this.email, required this.otp});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      // POST {{BASE_URL}}/users/reset-password
      // Payload: {"email": "...", "otp": "...", "new_password": "..."}
      final response = await http.post(
        Uri.parse(ApiConstants.resetPasswordEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'otp': widget.otp,
          'new_password': _passwordController.text,
          'confirm_password': _confirmController.text, // Backend asks for this if they enforce confirming
        }),
      );

      // Success: {"message": "Password reset successfully"}
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Password reset successfully!'),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 3),
          ),
        );

        // Return to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
          (route) => false,
        );
      } else {
        _showError(data['message'] ?? 'Failed to reset password. Please try again.');
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
                      'New Password',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: textColor,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Set a strong new password for your account.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: subTextColor,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 48.h),

                    // Removed Token read-only field


                    // New Password
                    Text(
                      'New Password',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: textColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: textColor,
                        fontSize: 16,
                      ),
                      decoration: buildUnderlineInputDecoration(
                        context: context,
                        label: '',
                        hintText: 'Enter new password',
                        prefixIcon: Icon(Icons.lock_outline, color: primaryBrandColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: primaryBrandColor,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        // Min 12 chars, 1 uppercase, 1 lowercase, 1 digit, 1 symbol
                        if (!RegExp(
                          r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{12,}$',
                        ).hasMatch(value)) {
                          return 'Min 12 chars with uppercase, lowercase, number & symbol (@\$!%*?&)';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 28.h),

                    // Confirm Password
                    Text(
                      'Confirm Password',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: textColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: textColor,
                        fontSize: 16,
                      ),
                      decoration: buildUnderlineInputDecoration(
                        context: context,
                        label: '',
                        hintText: 'Confirm new password',
                        prefixIcon: Icon(Icons.lock_outline, color: primaryBrandColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: primaryBrandColor,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 48.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBrandColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Reset Password',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          const ModalBarrier(dismissible: false, color: Colors.black38),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: primaryBrandColor),
          ),
      ],
    );
  }
}
