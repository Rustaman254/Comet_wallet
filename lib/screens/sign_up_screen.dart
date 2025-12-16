import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../services/toast_service.dart';
import '../utils/input_decoration.dart';
import 'sign_in_screen.dart';
import 'verify_pin_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Aimal Naseem');
  final _phoneController = TextEditingController(text: '+000 00 00 000');
  final _emailController = TextEditingController(text: 'aimalnaseem@gmail.com');
  final _passwordController = TextEditingController(text: '********');
  bool _obscurePassword = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isSignedUp', true);
      await prefs.setBool('isFirstTime', false);

      if (mounted) {
        ToastService().showSuccess(context, "Account created successfully!");
        Navigator.of(
          context,
        ).pushReplacement(
            MaterialPageRoute(builder: (_) => const VerifyPinScreen()));
      }
    } else {
      ToastService().showError(context, "Please fill in all fields correctly");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Back button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Center(
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Full Name field
                  Text(
                    'Full Name',
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 16,
                    ),
                    decoration: buildUnderlineInputDecoration(
                      context: context,
                      label: '',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Phone Number field
                  Text(
                    'Phone Number',
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    keyboardType: TextInputType.phone,
                    decoration: buildUnderlineInputDecoration(
                      context: context,
                      label: '',
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Email field
                  Text(
                    'Email Address',
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: buildUnderlineInputDecoration(
                      context: context,
                      label: '',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Password field
                  Text(
                    'Password',
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: buildUnderlineInputDecoration(
                      context: context,
                      label: '',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  // Sign Up button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Sign In link
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const SignInScreen(),
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          children: [
                            const TextSpan(text: 'Already have an account. '),
                            TextSpan(
                              text: 'Sign In',
                              style: GoogleFonts.poppins(
                                color: buttonGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
