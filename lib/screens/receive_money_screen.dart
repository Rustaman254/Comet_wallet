import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/colors.dart';
import '../services/wallet_service.dart';
import '../services/toast_service.dart';
import '../services/token_service.dart';
import '../utils/input_decoration.dart';
import 'payment_qr_display_screen.dart';
import 'sign_in_screen.dart';

class ReceiveMoneyScreen extends StatefulWidget {
  const ReceiveMoneyScreen({super.key});

  @override
  State<ReceiveMoneyScreen> createState() => _ReceiveMoneyScreenState();
}

class _ReceiveMoneyScreenState extends State<ReceiveMoneyScreen> {
  String walletAddress = 'Loading...';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    final phone = await TokenService.getPhoneNumber();
    if (mounted) {
      setState(() {
        walletAddress = phone ?? '+2547XXXXXXXX';
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _generateQR() async {
    if (_amountController.text.isEmpty) {
      ToastService().showError(context, 'Please enter an amount');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final response = await WalletService.createPaymentLink(
        amount: amount,
        currency: 'KES',
        description: _descriptionController.text.isEmpty
            ? 'Payment to $walletAddress'
            : _descriptionController.text,
      );

      final paymentUrl = response['payment_url'];

      if (mounted && paymentUrl != null) {
        ToastService().showSuccess(context, 'Payment link generated!');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaymentQRDisplayScreen(
              paymentUrl: paymentUrl,
              amount: amount,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        if (errorMsg.contains('401') || errorMsg.contains('expired')) {
          ToastService().showError(context, 'Session expired. Please login again.');
          await TokenService.logout();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SignInScreen()),
              (route) => false,
            );
          }
        } else {
          ToastService().showError(context, 'Failed to generate QR: $e');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
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
                      'Receive Money',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Satoshi',
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 30),

              // Wallet Number Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Mobile Wallet Number',
                    style: TextStyle(fontFamily: 'Satoshi',
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: walletAddress));
                            ToastService().showSuccess(context, 'Copied to clipboard!');
                          },
                          child: Text(
                            walletAddress,
                            style: TextStyle(fontFamily: 'Satoshi',
                              color: Colors.grey[600],
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: walletAddress));
                          ToastService().showSuccess(context, 'Copied to clipboard!');
                        },
                        icon: Icon(
                          Icons.copy_rounded,
                          color: buttonGreen,
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Inputs Group
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount (KES)',
                    style: TextStyle(fontFamily: 'Satoshi',
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    style: TextStyle(fontFamily: 'Satoshi',color: Colors.white, fontSize: 16),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: buildUnderlineInputDecoration(
                      context: context,
                      label: '',
                      hintText: 'Enter amount',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: TextStyle(fontFamily: 'Satoshi',
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    style: TextStyle(fontFamily: 'Satoshi',color: Colors.white, fontSize: 16),
                    decoration: buildUnderlineInputDecoration(
                      context: context,
                      label: '',
                      hintText: 'What is this for?',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generateQR,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Generate QR Code',
                          style: TextStyle(fontFamily: 'Satoshi',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
}
