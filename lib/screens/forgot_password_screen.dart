import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../constants/colors.dart';
import '../utils/responsive_utils.dart';
import '../utils/input_decoration.dart';
import 'verify_token_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetToken() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      // POST {{BASE_URL}}/users/reset-token
      // Payload: {"email": "user@example.com"}
      final response = await http.post(
        Uri.parse(ApiConstants.resetTokenEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim()}),
      );

      // Success: {"message": "Reset token sent successfully", "token": "fc04..."}
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = (data['token'] ?? '') as String;
        final message = data['message'] ?? 'Reset token sent successfully';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 4),
          ),
        );

        // Navigate to verify token screen, passing the token
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VerifyTokenScreen(prefillToken: token),
          ),
        );
      } else {
        _showError(data['message'] ?? 'Something went wrong. Please try again.');
      }
    } catch (_) {
      if (mounted) _showError('Connection error. Please check your internet connection.');
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
                      'Forgot Password?',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: textColor,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Enter your email address and we\'ll send a reset token to get you back in.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: subTextColor,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 48.h),
                    Text(
                      'Email Address',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: textColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: textColor,
                        fontSize: 16,
                      ),
                      decoration: buildUnderlineInputDecoration(
                        context: context,
                        label: '',
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email_outlined, color: primaryBrandColor),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 48.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendResetToken,
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
                          'Send Reset Link',
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
