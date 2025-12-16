import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../services/vibration_service.dart';
import '../services/toast_service.dart';

class EnterPinScreen extends StatefulWidget {
  final String recipientName;
  final String amount;
  final String currency;
  
  const EnterPinScreen({
    super.key,
    required this.recipientName,
    required this.amount,
    required this.currency,
  });

  @override
  State<EnterPinScreen> createState() => _EnterPinScreenState();
}

class _EnterPinScreenState extends State<EnterPinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  final String _correctPin = '1234';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
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
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: buttonGreen.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: buttonGreen,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Payment Successful!',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${widget.currency} ${widget.amount}',
                style: GoogleFonts.poppins(
                  color: buttonGreen,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'sent to ${widget.recipientName}',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ToastService().showSuccess(
                      context,
                      'Transaction completed successfully!',
                    );
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      VibrationService.heavyImpact();
      _shakeController.forward().then((_) {
        _shakeController.reverse();
        setState(() {
          _pin = '';
        });
      });
      
      if (mounted) {
        ToastService().showError(
          context,
          'Incorrect PIN. Please try again.',
        );
      }
    }
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
              const SizedBox(height: 20),
              // Back button
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
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
                child: Center(
                  child: Text(
                    widget.recipientName[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Recipient name
              Text(
                'Sending to',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.recipientName,
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
              // PIN dots with shake animation
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
              // Numeric keypad
              _buildKeypad(),
              const SizedBox(height: 40),
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
              onPressed: () {},
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
