import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'add_card_screen.dart';

class MyCardsScreen extends StatelessWidget {
  const MyCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text(
                    'All Cards',
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
            // Cards List
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildCreditCard(
                    color1: Colors.blue.shade900,
                    color2: Colors.blue.shade600,
                    number: '4562 1122 4595 7852',
                    expiry: '24/2000',
                    cvv: '6986',
                    holder: 'Aimal Naseem',
                    type: 'mastercard',
                  ),
                  const SizedBox(height: 20),
                  _buildCreditCard(
                    color1: Colors.grey.shade900,
                    color2: Colors.grey.shade800,
                    number: '4562 1122 4595 7852',
                    expiry: '24/2000',
                    cvv: '6986',
                    holder: 'Aimal Naseem',
                    type: 'visa',
                  ),
                ],
              ),
            ),
            // Add Card Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddCardScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Add Card',
                        style: TextStyle(fontFamily: 'Satoshi',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.add, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCard({
    required Color color1,
    required Color color2,
    required String number,
    required String expiry,
    required String cvv,
    required String holder,
    required String type,
  }) {
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
        borderRadius: BorderRadius.circular(24),
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
            number, // Formatted with spaces
            style: TextStyle(
              fontFamily: 'Satoshi',
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aimal Naseem', // Placeholder
                    style: TextStyle(fontFamily: 'Satoshi',
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             'Expiry Date',
                             style: TextStyle(fontFamily: 'Satoshi',color: Colors.white70, fontSize: 10),
                           ),
                           Text(
                             expiry,
                             style: TextStyle(fontFamily: 'Satoshi',color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                           ),
                         ],
                       ),
                       const SizedBox(width: 24),
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             'CVV',
                             style: TextStyle(fontFamily: 'Satoshi',color: Colors.white70, fontSize: 10),
                           ),
                           Text(
                             cvv,
                             style: TextStyle(fontFamily: 'Satoshi',color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                           ),
                         ],
                       ),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                   // Type Logo
                   if (type == 'mastercard')
                     SizedBox(
                        height: 30,
                        width: 40,
                        child: Stack(
                          children: [
                            Positioned(left:0, child: CircleAvatar(backgroundColor: Colors.red.withValues(alpha: 0.9), radius: 10)),
                            Positioned(right:0, child: CircleAvatar(backgroundColor: Colors.orange.withValues(alpha: 0.9), radius: 10)),
                          ],
                        ),
                     )
                   else
                     const Text('VISA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, fontStyle: FontStyle.italic)),
                     
                   const SizedBox(height: 4),
                   Text(
                     type == 'mastercard' ? 'Mastercard' : '',
                     style: TextStyle(fontFamily: 'Satoshi',color: Colors.white, fontSize: 10),
                   ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}
