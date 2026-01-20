import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../utils/responsive_utils.dart';
import '../services/vibration_service.dart';
import 'main_wrapper.dart';
import '../services/token_service.dart';

class VerifyPinScreen extends StatefulWidget {
  final Widget? nextScreen;
  const VerifyPinScreen({super.key, this.nextScreen});

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  final String _correctPin = '1234'; 
  String _userName = 'User'; // Default value
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  Future<void> _loadUserData() async {
    final name = await TokenService.getUserName();
    if (name != null && name.isNotEmpty && mounted) {
      setState(() {
        _userName = name;
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    if (_pin.length < 4) {
      VibrationService.lightImpact();
      setState(() {
        _pin += number;
      });

      // Auto-verify when 4 digits entered
      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      VibrationService.lightImpact();
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _verifyPin() {
    if (_pin == _correctPin) {
      // Correct PIN - navigate to next screen or home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => widget.nextScreen ?? const MainWrapper()),
      );
    } else {
      VibrationService.errorVibrate();
      _shakeController.forward(from: 0.0).then((_) {
        setState(() {
          _pin = '';
        });
      });
    }
  }

  void _onBiometric() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            children: [
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
                child: Icon(
                  Icons.person_outline,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  size: 40.r,
                ),
              ),
              SizedBox(height: 20.h),
              // Welcome text
              Text(
                'Welcome back,',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _userName,
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 50.h),
              // Enter PIN text
              Text(
                'Enter your PIN',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 30.h),
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
              const Spacer(),
              _buildKeypad(),
              SizedBox(height: 20.h),
              TextButton(
                onPressed: () {
                  // Handle forgot PIN
                },
                child: Text(
                  'Forgot PIN?',
                  style: GoogleFonts.poppins(
                    color: buttonGreen,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        SizedBox(height: 16.r.h),
        _buildKeypadRow(['4', '5', '6']),
        SizedBox(height: 16.r.h),
        _buildKeypadRow(['7', '8', '9']),
        SizedBox(height: 16.r.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton(
              onPressed: _onBackspace,
              child: Icon(
                Icons.backspace_outlined,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                size: 24.r,
              ),
            ),
            _buildKeypadButton(
              onPressed: () => _onNumberPressed('0'),
              child: Text(
                '0',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _buildKeypadButton(
              onPressed: _onBiometric,
              child: Icon(
                Icons.fingerprint,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                size: 28.r,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) {
        return _buildKeypadButton(
          onPressed: () => _onNumberPressed(number),
          child: Text(
            number,
            style: GoogleFonts.poppins(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 24.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 70.r,
        height: 70.r,
        decoration: BoxDecoration(
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }
}
