import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:qr_flutter/qr_flutter.dart';
import '../constants/colors.dart';
import 'qr_scan_screen.dart';

class RequestMoneyScreen extends StatefulWidget {
  const RequestMoneyScreen({super.key});

  @override
  State<RequestMoneyScreen> createState() => _RequestMoneyScreenState();
}

class _RequestMoneyScreenState extends State<RequestMoneyScreen> {
  String _selectedMode = 'Payment Link'; // Payment Link or Wallet to Wallet
  final String _paymentLink = 'https://comet.wallet/pay/tanya-m';
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                          color: Colors.white.withValues(alpha: 0.1),
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
                        'Request Money',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Outfit',
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 32),
                // Toggle Buttons - Connected like My Cards
                Row(
                  children: [
                    // My Payment Link Button (Left)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMode = 'Payment Link';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedMode == 'Payment Link'
                                ? buttonGreen
                                : cardBackground,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            border: Border.all(
                              color: _selectedMode == 'Payment Link'
                                  ? buttonGreen
                                  : cardBorder,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'My Payment Link',
                            style: TextStyle(fontFamily: 'Outfit',
                              color: _selectedMode == 'Payment Link'
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 14,
                              fontWeight: _selectedMode == 'Payment Link'
                                  ? FontWeight.bold
                                  : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    // Wallet to Wallet Button (Right)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMode = 'Wallet to Wallet';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedMode == 'Wallet to Wallet'
                                ? buttonGreen
                                : cardBackground,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            border: Border.all(
                              color: _selectedMode == 'Wallet to Wallet'
                                  ? buttonGreen
                                  : cardBorder,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Wallet to Wallet',
                            style: TextStyle(fontFamily: 'Outfit',
                              color: _selectedMode == 'Wallet to Wallet'
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 14,
                              fontWeight: _selectedMode == 'Wallet to Wallet'
                                  ? FontWeight.bold
                                  : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Content based on selected mode
                if (_selectedMode == 'Payment Link')
                  _buildPaymentLinkContent()
                else
                  _buildWalletToWalletContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentLinkContent() {
    return Column(
      children: [
        // QR Code
        Container(
          width: 280,
          height: 280,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Real QR Code generated from payment link
              QrImageView(
                data: _paymentLink,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
              ),
              const SizedBox(height: 12),
              Text(
                'Scan to Pay',
                style: TextStyle(fontFamily: 'Outfit',
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Payment Link
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Link',
                style: TextStyle(fontFamily: 'Outfit',
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _paymentLink,
                      style: TextStyle(fontFamily: 'Outfit',
                        color: buttonGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _paymentLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Payment link copied to clipboard',
                            style: TextStyle(fontFamily: 'Outfit',),
                          ),
                          backgroundColor: buttonGreen,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: buttonGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.copy_outlined,
                        color: buttonGreen,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Share Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Share functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.share_outlined),
            label: Text(
              'Share Payment Link',
              style: TextStyle(fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletToWalletContent() {
    return Column(
      children: [
        // Scan QR Button
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QRScanScreen()),
            );
          },
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cardBorder, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: buttonGreen.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.qr_code_scanner,
                    size: 60,
                    color: buttonGreen,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Scan QR Code',
                  style: TextStyle(fontFamily: 'Outfit',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to open camera',
                  style: TextStyle(fontFamily: 'Outfit',
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Or divider
        Row(
          children: [
            Expanded(
              child: Divider(color: Colors.white.withValues(alpha: 0.2), thickness: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(fontFamily: 'Outfit',
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: Colors.white.withValues(alpha: 0.2), thickness: 1),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Amount Input
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request Amount',
                style: TextStyle(fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                style: TextStyle(fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(fontFamily: 'Outfit',
                    color: Colors.white38,
                  ),
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(fontFamily: 'Outfit',
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Generate Request Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please enter an amount',
                      style: TextStyle(fontFamily: 'Outfit',),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              // Generate request
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Payment request generated',
                    style: TextStyle(fontFamily: 'Outfit',),
                  ),
                  backgroundColor: buttonGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Generate Request',
              style: TextStyle(fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
