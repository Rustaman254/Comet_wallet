import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      // same as login
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Container(
                        width: 40.r,
                        height: 40.r,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back_outlined,
                          color: Colors.white,
                          size: 20.r,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Service Details',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: Colors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 40.w),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Details
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    Container(
                      width: 80.r,
                      height: 80.r,
                      decoration: BoxDecoration(
                        color: buttonGreen.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: buttonGreen,
                        size: 40.r,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      widget.bill.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20.r),
                        // removed border to stay consistent with pills on home/login
                      ),
                      child: Text(
                        'Unpaid',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: Colors.green[300],
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 40.h),
                    
                    _buildDetailRow('Reference', widget.bill.refNo),
                    SizedBox(height: 24.h),
                    _buildDetailRow('Date', 'Today'),
                    SizedBox(height: 24.h),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    SizedBox(height: 24.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            color: Colors.grey[400],
                            fontSize: 18.sp,
                          ),
                        ),
                        Text(
                          '${widget.bill.currency} ${widget.bill.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            color: Colors.white,
                            fontSize: 32.sp,
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
                padding: EdgeInsets.symmetric(horizontal: 24.w),
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
                              final transferResponse =
                                  await WalletService.transferWallet(
                                toEmail: 'colls@cradlevoices.com',
                                amount: widget.bill.amount,
                                currency: widget.bill.currency,
                              );

                              final transactionId =
                                  transferResponse['transaction_id'] ?? 'N/A';
                              
                              // Get user details for eCitizen confirmation
                              final customerName =
                                  await TokenService.getUserName() ??
                                      'Unknown User';
                              final customerPhone =
                                  await TokenService.getPhoneNumber() ??
                                      'Unknown';
                              
                              // Format date as YYYY-MM-DD HH:mm:ss
                              final now = DateTime.now();
                              final dateStr =
                                  "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} "
                                  "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

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
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Pay Now',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: Colors.grey[400],
            fontSize: 15.sp,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
