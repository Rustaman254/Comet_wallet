import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../constants/colors.dart';
import '../utils/responsive_utils.dart';
import '../utils/input_decoration.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // OTP field left empty
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _verifyToken() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      // POST {{BASE_URL}}/users/verify-token
      // Payload: {"email": "...", "otp": "..."}
      final response = await http.post(
        Uri.parse(ApiConstants.verifyTokenEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'otp': _tokenController.text.trim(),
        }),
      );

      // Success: {"message": "Token is valid", "user_id": 122}
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['message'] == 'Token is valid') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Token verified!'),
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
        _showError(data['message'] ?? 'Invalid or expired token.');
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
                      'Verify Token',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: textColor,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Enter the reset token from the API response to verify your identity.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: subTextColor,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 48.h),
                    Text(
                      'OPT Code',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: textColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _tokenController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: textColor,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      minLines: 1,
                      decoration: buildUnderlineInputDecoration(
                        context: context,
                        label: '',
                        hintText: 'Enter 6-digit OTP',
                        prefixIcon: Icon(Icons.password_outlined, color: primaryBrandColor),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the reset token';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 48.h),
                    SizedBox(
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
                        child: Text(
                          'Verify Token',
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
