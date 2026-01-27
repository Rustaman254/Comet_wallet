import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/ecitizen_bill.dart';
import '../services/ecitizen_service.dart';
import '../services/wallet_service.dart';
import '../services/token_service.dart';
import 'enter_pin_screen.dart';

class ECitizenDetailsScreen extends StatefulWidget {
  final ECitizenBill bill;

  const ECitizenDetailsScreen({
    super.key,
    required this.bill,
  });

  @override
  State<ECitizenDetailsScreen> createState() => _ECitizenDetailsScreenState();
}

class _ECitizenDetailsScreenState extends State<ECitizenDetailsScreen> {
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
                        'Service Details',
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
              ),
              const SizedBox(height: 40),

              // Details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: buttonGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: buttonGreen,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.bill.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Satoshi',
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'Unpaid',
                        style: TextStyle(fontFamily: 'Satoshi',
                          color: Colors.green[300],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    _buildDetailRow('Reference', widget.bill.refNo),
                    const SizedBox(height: 24),
                    _buildDetailRow('Date', 'Today'),
                    const SizedBox(height: 24),
                    Divider(color: Colors.white.withValues(alpha: 0.1)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(fontFamily: 'Satoshi',
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${widget.bill.currency} ${widget.bill.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Pay Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EnterPinScreen(
                            recipientName: 'eCitizen - ${widget.bill.name}',
                            amount: widget.bill.amount.toStringAsFixed(2),
                            currency: widget.bill.currency,
                            onVerify: () async {
                              // 1. Perform wallet to wallet transfer
                              final transferResponse = await WalletService.transferWallet(
                                toEmail: 'colls@cradlevoices.com',
                                amount: widget.bill.amount,
                                currency: widget.bill.currency,
                              );

                              final transactionId = transferResponse['transaction_id'] ?? 'N/A';
                              
                              // Get user details for eCitizen confirmation
                              final customerName = await TokenService.getUserName() ?? 'Unknown User';
                              final customerPhone = await TokenService.getPhoneNumber() ?? 'Unknown';
                              
                              // Format date as YYYY-MM-DD HH:mm:ss
                              final now = DateTime.now();
                              final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

                              // 2. Confirm payment with eCitizen
                              return await ECitizenService.confirmPayment(
                                refNo: widget.bill.refNo,
                                amount: widget.bill.amount,
                                currency: widget.bill.currency,
                                transactionId: transactionId,
                                gatewayTransactionDate: dateStr,
                                customerName: customerName,
                                customerAccountNumber: customerPhone,
                              );
                            },
                          ),
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
                      'Pay Now',
                      style: TextStyle(fontFamily: 'Satoshi',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Satoshi',
            color: Colors.white70,
            fontSize: 15,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
