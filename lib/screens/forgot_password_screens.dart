import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Ensure you have google_fonts added to pubspec.yaml if you uncomment GoogleFonts
// import 'package:google_fonts/google_fonts.dart';

const String baseUrl = '{{BASE_URL}}';
const Color primaryBlue = Color(0xFF1976D2);
const Color successGreen = Color(0xFF4CAF50);
const Color errorRed = Color(0xFFF44336);

/// Helper method for styled Text (falling back to standard TextStyle if GoogleFonts isn't available)
TextStyle _poppinsStyle({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
}) {
  return TextStyle(
    fontFamily: 'Poppins',
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );
}

// ==========================================
// 1. Forgot Password Screen
// ==========================================
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendResetToken() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/reset-token'),
        headers: {'Content-Type': 'application/json'},
        // Payload: {"email": "anwarmagara@gmail.com"}
        body: jsonEncode({"email": _emailController.text.trim()}),
      );

      // Expected Response (success): 
      // {"message": "Reset token sent successfully", "token": "fc04..."}

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String?;
        final message = data['message'] ?? 'Reset token sent successfully';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: successGreen),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyTokenScreen(initialToken: token ?? ''),
            ),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        _showError(data['message'] ?? 'Failed to send reset token');
      }
    } catch (e) {
      _showError('Connection error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: errorRed),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(context),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Forgot Password?',
                      style: _poppinsStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter your email address to receive a password reset token.',
                      textAlign: TextAlign.center,
                      style: _poppinsStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration(
                        label: 'Email',
                        icon: Icons.email_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    _buildPrimaryButton(
                      text: 'Send Reset Token',
                      onPressed: _sendResetToken,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoading) _buildLoadingOverlay(),
      ],
    );
  }
}

// ==========================================
// 2. Verify Token Screen
// ==========================================
class VerifyTokenScreen extends StatefulWidget {
  final String initialToken;

  const VerifyTokenScreen({super.key, required this.initialToken});

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
    _tokenController.text = widget.initialToken;
  }

  Future<void> _verifyToken() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/verify-token'),
        headers: {'Content-Type': 'application/json'},
        // Payload: {"token": "fc04..."}
        body: jsonEncode({"token": _tokenController.text.trim()}),
      );

      // Expected Response (success): {"message": "Token is valid", "user_id": 122}

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['message'] == "Token is valid") {
        final userId = data['user_id'] as int?;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Token verified successfully'),
              backgroundColor: successGreen,
            ),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(
                token: _tokenController.text.trim(),
                userId: userId,
              ),
            ),
          );
        }
      } else {
        _showError(data['message'] ?? 'Invalid token');
      }
    } catch (e) {
      _showError('Connection error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: errorRed),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(context),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Verify Token',
                      style: _poppinsStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter the reset token that was sent to your email.',
                      textAlign: TextAlign.center,
                      style: _poppinsStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _tokenController,
                      decoration: _buildInputDecoration(
                        label: 'Token',
                        icon: Icons.vpn_key_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter the token';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    _buildPrimaryButton(
                      text: 'Verify Token',
                      onPressed: _verifyToken,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoading) _buildLoadingOverlay(),
      ],
    );
  }
}

// ==========================================
// 3. Reset Password Screen
// ==========================================
class ResetPasswordScreen extends StatefulWidget {
  final String token;
  final int? userId; // Included in case API needs it

  const ResetPasswordScreen({
    super.key,
    required this.token,
    this.userId,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/reset-password'),
        headers: {'Content-Type': 'application/json'},
        // Payload: {"token": "fc04...", "new_password": "testingpassword1234"}
        body: jsonEncode({
          "token": widget.token,
          "new_password": _passwordController.text,
        }),
      );

      // Expected Response (success): {"message": "Password reset successfully"}

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Password reset successfully'),
              backgroundColor: successGreen,
            ),
          );

          // Navigate back to login
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        final data = jsonDecode(response.body);
        _showError(data['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      _showError('Connection error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: errorRed),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(context),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'New Password',
                      style: _poppinsStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create a new strong password.',
                      textAlign: TextAlign.center,
                      style: _poppinsStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 48),
                    
                    // Pre-filled token (read-only)
                    TextFormField(
                      initialValue: widget.token,
                      readOnly: true,
                      decoration: _buildInputDecoration(
                        label: 'Token',
                        icon: Icons.vpn_key_outlined,
                      ).copyWith(
                        fillColor: Colors.grey[100],
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // New Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _buildInputDecoration(
                        label: 'New Password',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        // Min 12 chars, at least 1 uppercase, 1 lowercase, 1 number, 1 symbol
                        if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{12,}$').hasMatch(value)) {
                          return 'Min 12 chars, 1 uppercase, 1 lowercase, 1 number, 1 symbol (@$!%*?&)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: _buildInputDecoration(
                        label: 'Confirm Password',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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
                    const SizedBox(height: 32),
                    _buildPrimaryButton(
                      text: 'Reset Password',
                      onPressed: _resetPassword,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoading) _buildLoadingOverlay(),
      ],
    );
  }
}

// ==========================================
// Common UI Builders
// ==========================================

PreferredSizeWidget _buildAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black87),
      onPressed: () => Navigator.of(context).pop(),
    ),
  );
}

InputDecoration _buildInputDecoration({
  required String label,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: _poppinsStyle(color: Colors.grey[600]),
    prefixIcon: Icon(icon, color: Colors.grey[600]),
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: primaryBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: errorRed, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: errorRed, width: 2),
    ),
  );
}

Widget _buildPrimaryButton({required String text, required VoidCallback onPressed}) {
  return SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: primaryBlue.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        text,
        style: _poppinsStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

Widget _buildLoadingOverlay() {
  return Container(
    color: Colors.black.withValues(alpha: 0.3),
    alignment: Alignment.center,
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const CircularProgressIndicator(
        color: primaryBlue,
        strokeWidth: 3,
      ),
    ),
  );
}
