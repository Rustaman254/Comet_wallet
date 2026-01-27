import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../services/toast_service.dart';
import '../utils/input_decoration.dart';
import 'enter_pin_screen.dart';

class MobileWithdrawScreen extends StatefulWidget {
  final String currency;
  final double maxBalance;

  const MobileWithdrawScreen({
    super.key,
    this.currency = 'KES',
    this.maxBalance = 0.0,
  });

  @override
  State<MobileWithdrawScreen> createState() => _MobileWithdrawScreenState();
}

class _MobileWithdrawScreenState extends State<MobileWithdrawScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    final amountText = _amountController.text.trim();
    final phoneText = _phoneController.text.trim();

    if (phoneText.isEmpty) {
      ToastService().showError(context, 'Please enter a phone number');
      return;
    }

    final amountVal = double.tryParse(amountText) ?? 0.0;
    
    if (amountVal <= 0) {
      ToastService().showError(context, 'Please enter a valid amount');
      return;
    }

    if (amountVal > widget.maxBalance) {
      ToastService().showError(context, 'Insufficient balance');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EnterPinScreen(
          recipientName: phoneText, // Standard field for recipient phone
          amount: amountText,
          currency: widget.currency,
          description: 'Withdrawal to M-Pesa',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mobile Money',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phone Input
              Text(
                'Phone Number',
                style: TextStyle(fontFamily: 'Outfit',
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(fontFamily: 'Outfit',color: Colors.white),
                decoration: buildUnderlineInputDecoration(
                  context: context,
                  label: '',
                  hintText: 'e.g. 254712345678',
                ),
              ),
              const SizedBox(height: 24),

              // Amount Input (MSISDN Style)
              Text(
                'Enter Amount',
                style: TextStyle(fontFamily: 'Outfit',
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Currency Label
                  Container(
                    width: 80,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      widget.currency,
                      style: TextStyle(fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Number Field
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: buildUnderlineInputDecoration(
                        context: context,
                        label: '',
                        hintText: '0.00',
                      ),
                    ),
                  ),
                ],
              ),
              
               const SizedBox(height: 40),

               SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
