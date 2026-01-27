import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'enter_pin_screen.dart';

class MobilePaymentConfirmScreen extends StatelessWidget {
  final String phoneNumber;
  final String amount;
  final String currency;

  const MobilePaymentConfirmScreen({
    super.key,
    required this.phoneNumber,
    required this.amount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header
              Row(
                children: [
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
                        Icons.arrow_back_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Confirm Payment',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 40),
              // Center amount display
              Column(
                children: [
                   Text(
                    'Sending',
                    style: TextStyle(fontFamily: 'Outfit',
                      color: Colors.white60,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currency,
                        style: TextStyle(fontFamily: 'Outfit',
                          color: buttonGreen,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        amount,
                        style: TextStyle(fontFamily: 'Outfit',
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 60),

              // Recipient Details
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    _buildModernDetailRow(
                      icon: Icons.person_outline,
                      label: 'To Recipient',
                      value: phoneNumber,
                      isPhone: true,
                    ),
                     const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: Colors.white10),
                    ),
                    _buildModernDetailRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'Transaction Fee',
                      value: 'Free',
                      valueColor: buttonGreen,
                    ),
                     const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: Colors.white10),
                    ),
                     _buildModernDetailRow(
                      icon: Icons.description_outlined,
                      label: 'Description',
                      value: 'Withdrawal to M-Pesa',
                    ),
                  ],
                ),
              ),

              const Spacer(),
              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EnterPinScreen(
                          recipientName: phoneNumber,
                          amount: amount,
                          currency: currency,
                          description: 'Withdrawal to M-Pesa',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: buttonGreen.withValues(alpha: 0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fingerprint, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Confirm & Send',
                        style: TextStyle(fontFamily: 'Outfit',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Cancel Transaction',
                    style: TextStyle(fontFamily: 'Outfit',
                      color: Colors.white60,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
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

  Widget _buildModernDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isPhone = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontFamily: 'Outfit',
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
               const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontFamily: 'Outfit',
                  color: valueColor ?? Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: isPhone ? 0.5 : 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
