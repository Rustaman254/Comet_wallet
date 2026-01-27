import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../utils/responsive_utils.dart';
import '../services/vibration_service.dart';
import '../services/toast_service.dart';
import '../utils/input_decoration.dart';
import 'sign_up_screen.dart';
import 'verify_pin_screen.dart';
import '../services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    VibrationService.selectionClick();
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      try {
        await AuthService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) Navigator.pop(context);

        if (mounted) {
          ToastService().showSuccess(context, "Login successful! Welcome back!");
          VibrationService.lightImpact();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const VerifyPinScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          VibrationService.errorVibrate();
          String errorMessage = e.toString().replaceFirst('Exception: ', '');
          ToastService().showError(context, errorMessage);
        }
      }
    } else {
      VibrationService.errorVibrate();
      ToastService().showError(context, "Please check your inputs");
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
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),
                  // Back button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Title
                  Text(
                    'Sign In',
                    style: TextStyle(fontFamily: 'Satoshi',
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 40.r.h),
                  // Email field
                  Text(
                    'Email Address',
                    style: TextStyle(fontFamily: 'Satoshi',
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(fontFamily: 'Satoshi',
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 16.sp,
                    ),
                    decoration: buildUnderlineInputDecoration(
                      context: context,
                      label: '',
                      hintText: 'Enter your email address',
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
                  SizedBox(height: 24.h),
                  // Password field
                  Text(
                    'Password',
                    style: TextStyle(fontFamily: 'Satoshi',
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(fontFamily: 'Satoshi',
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 16.sp,
                    ),
                    decoration: buildUnderlineInputDecoration(
                      context: context,
                      label: '',
                      hintText: 'Enter your password',
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
                  SizedBox(height: 40.r.h),
                  // Sign In button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonGreen,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Sign In',
                        style: TextStyle(fontFamily: 'Satoshi',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // Sign Up link
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontFamily: 'Satoshi',
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                          ),
                          children: [
                            const TextSpan(text: "I'm a new user. "),
                            TextSpan(
                              text: 'Sign UP',
                              style: TextStyle(fontFamily: 'Satoshi',
                                color: buttonGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40.r.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
