import 'package:flutter/material.dart';

import '../constants/colors.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Aimal Naseem');
  final TextEditingController _expiryController = TextEditingController(text: '09/06/2024');
  final TextEditingController _cvvController = TextEditingController(text: '6986');
  final TextEditingController _numberController = TextEditingController(text: '4562 1122 4595 7852');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Text(
                      'Add New Card',
                      style: TextStyle(fontFamily: 'Satoshi',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Card Preview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade900,
                        Colors.blue.shade800,
                        Colors.blue.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.sim_card, color: Colors.white.withValues(alpha: 0.5), size: 32),
                          Icon(Icons.wifi, color: Colors.white.withValues(alpha: 0.5), size: 24),
                        ],
                      ),
                      Text(
                        '4562  1122  4595  7852',
                        style: TextStyle(fontFamily: 'Satoshi',
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aimal Naseem',
                                style: TextStyle(fontFamily: 'Satoshi',
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Expiry Date',
                                        style: TextStyle(fontFamily: 'Satoshi',
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        '24/2000',
                                        style: TextStyle(fontFamily: 'Satoshi',
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'CVV',
                                        style: TextStyle(fontFamily: 'Satoshi',
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        '6986',
                                        style: TextStyle(fontFamily: 'Satoshi',
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            children: [
                              // Mastercard Circles
                              SizedBox(
                                height: 30,
                                width: 50,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 0,
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.9),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(alpha: 0.9),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mastercard',
                                style: TextStyle(fontFamily: 'Satoshi',
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    _buildInputField('Cardholder Name', _nameController, Icons.person_outline),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildInputField('Expiry Date', _expiryController, null)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildInputField('4-digit CVV', _cvvController, null)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInputField('Card Number', _numberController, Icons.credit_card),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Button (optional if design has one? Image 0 has no button at bottom visible, but likely needs one)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData? icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Satoshi',
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.transparent, // Design has underlines
            border: Border(bottom: BorderSide(color: cardBorder, width: 1)),
          ),
           // Wait, Image 0 has standard lines (underlined inputs?).
           // "Cardholder Name" -> Line. "Expiry Date" -> Line.
           // Let's use UnderlineInputBorder.
           child: TextField(
             controller: controller,
             style: TextStyle(fontFamily: 'Satoshi',
               color: Colors.white,
               fontSize: 15,
             ),
             decoration: InputDecoration(
               prefixIcon: icon != null ? Icon(icon, color: Colors.white70, size: 20) : null,
               border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
               enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
               focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: buttonGreen)),
               hintStyle: TextStyle(fontFamily: 'Satoshi',color: Colors.white30),
               contentPadding: const EdgeInsets.only(bottom: 8, top: 8),
             ),
           ),
        ),
      ],
    );
  }
}
