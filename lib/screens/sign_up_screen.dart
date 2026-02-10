import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../utils/responsive_utils.dart';
import '../services/toast_service.dart';
import '../services/vibration_service.dart';
import '../utils/input_decoration.dart';
import 'sign_in_screen.dart';
import 'verify_pin_screen.dart';
import 'kyc/id_upload_screen.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  final _locationController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscurePin = true;
  bool _isLoading = false;
  
  // Country code for phone number
  String _selectedCountryCode = '+254'; // Default to Kenya
  
  // East African country codes that should be converted to 0 prefix
  final Map<String, String> _countryCodeMap = {
    '+254': 'Kenya',
    '+256': 'Uganda',
    '+255': 'Tanzania',
    '+250': 'Rwanda',
  };
  
  final Set<String> _eastAfricanCodes = {'+254', '+256', '+255', '+250'};
  
  /// Convert phone number based on country code
  String _formatPhoneNumber(String phone, String countryCode) {
    // Remove any leading zeros or spaces
    phone = phone.trim().replaceAll(RegExp(r'^0+'), '');
    
    // For East African countries, convert to 0 prefix
    if (_eastAfricanCodes.contains(countryCode)) {
      return '0$phone';
    }
    
    // For other countries, keep the country code
    return '$countryCode$phone';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    VibrationService.selectionClick();
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Format phone number based on selected country code
        final formattedPhone = _formatPhoneNumber(
          _phoneController.text.trim(),
          _selectedCountryCode,
        );
        
        await AuthService.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          phoneNumber: formattedPhone,
          location: _locationController.text.trim(),
          pin: _pinController.text.trim(),
        );
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ToastService().showSuccess(context, "Account created successfully!");
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const IDUploadScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          VibrationService.errorVibrate();
          String errorMessage = e.toString().replaceFirst('Exception: ', '');
          ToastService().showError(context, errorMessage);
        }
      }
    } else {
      VibrationService.errorVibrate();
      ToastService().showError(context, "Please fill in all fields correctly");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 60.h),
                  Text(
                    'Register',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Create your profile',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 40.h),
                  
                  // Name field (moved to first position)
                  Text(
                    'Full Name',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                    decoration: buildUnderlineInputDecoration(
                      context: context,
                      label: '',
                      hintText: 'Enter your full name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24.h),
                  
                  // Email field
                  Text(
                    'Email address',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                    decoration: buildUnderlineInputDecoration(
                      context: context,
                      label: '',
                      hintText: 'Enter your email address',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24.h),
                  
                  // Password field (moved before phone)
                  Text(
                    'Password',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                    decoration: buildUnderlineInputDecoration(
                      context: context,
                      label: '',
                      hintText: 'Enter your password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
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
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24.h),
                  
                  // PIN field
                  Text(
                    'PIN (4 digits)',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _pinController,
                    obscureText: _obscurePin,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                    decoration: buildUnderlineInputDecoration(
                      context: context,
                      label: '',
                      hintText: 'Enter 4-digit PIN',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePin ? Icons.visibility_off : Icons.visibility,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePin = !_obscurePin;
                          });
                        },
                      ),
                    ).copyWith(counterText: ''),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a 4-digit PIN';
                      }
                      if (value.length != 4) {
                        return 'PIN must be exactly 4 digits';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24.h),
                  
                  // Phone field with country code selector
                  Text(
                    'Phone number',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Country code dropdown
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12, 
                              width: 1
                            ),
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedCountryCode,
                          dropdownColor: Theme.of(context).brightness == Brightness.dark ? cardBackground : lightCardBackground,
                          underline: const SizedBox(),
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            fontSize: 16.sp,
                          ),
                          items: _countryCodeMap.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.key),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCountryCode = value;
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // Phone number input
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                          decoration: buildUnderlineInputDecoration(
                            context: context,
                            label: '',
                            hintText: 'e.g. 712345678',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            // Remove leading zeros for validation
                            final cleanNumber = value.trim().replaceAll(RegExp(r'^0+'), '');
                            if (cleanNumber.length < 9) {
                              return 'Phone number too short';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  
                  // Location field (moved to last position)
                  Text(
                    'Location',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _locationController,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                    decoration: buildUnderlineInputDecoration(
                      context: context,
                      label: '',
                      hintText: 'Enter your location',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your location';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 40.h),
                  // Terms checkbox
                  // Row(
                  //   crossAxisAlignment: CrossAxisAlignment.start,
                  //   children: [
                  //     Checkbox(
                  //       value: true,
                  //       onChanged: (value) {},
                  //       side: BorderSide(color: Colors.grey[600]!),
                  //       fillColor: MaterialStateProperty.all(Colors.transparent),
                  //     ),
                  //     Expanded(
                  //       child: Padding(
                  //         padding: EdgeInsets.only(top: 12.h),
                  //         child: RichText(
                  //           text: TextSpan(
                  //             style: TextStyle(
                  //               color: Colors.white,
                  //               fontSize: 14.sp,
                  //             ),
                  //             children: [
                  //               const TextSpan(text: 'I agree to the '),
                  //               TextSpan(
                  //                 text: 'terms',
                  //                 style: TextStyle(color: Colors.red[400]),
                  //               ),
                  //               const TextSpan(text: ' and '),
                  //               TextSpan(
                  //                 text: 'privacy policy',
                  //                 style: TextStyle(color: Colors.red[400]),
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16.h),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                      fontSize: 14.sp,
                    ),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                          color: buttonGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
