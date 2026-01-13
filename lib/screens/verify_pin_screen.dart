import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
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
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
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
      _shakeController.forward().then((_) {
        _shakeController.reverse();
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Profile picture
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: buttonGreen, width: 3),
                  color: Colors.grey[800],
                ),
                child: Icon(
                  Icons.person_outline,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              // Welcome text
              Text(
                'Welcome back,',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _userName,
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 50),
              // Enter PIN text
              Text(
                'Enter your PIN',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < _pin.length
                              ? buttonGreen
                              : Colors.white.withValues(alpha: 0.3),
                          border: Border.all(
                            color: index < _pin.length
                                ? buttonGreen
                                : Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const Spacer(),
              _buildKeypad(),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // Handle forgot PIN
                },
                child: Text(
                  'Forgot PIN?',
                  style: GoogleFonts.poppins(
                    color: buttonGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
        const SizedBox(height: 16),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: 16),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton(
              onPressed: _onBackspace,
              child: Icon(
                Icons.backspace_outlined,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                size: 24,
              ),
            ),
            _buildKeypadButton(
              onPressed: () => _onNumberPressed('0'),
              child: Text(
                '0',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _buildKeypadButton(
              onPressed: _onBiometric,
              child: Icon(
                Icons.fingerprint,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                size: 28,
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
              fontSize: 24,
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
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }
}
