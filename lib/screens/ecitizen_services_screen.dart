import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/colors.dart';
import '../utils/input_decoration.dart';
import '../services/ecitizen_service.dart';
import '../models/ecitizen_bill.dart';
import 'ecitizen_details_screen.dart';
import '../widgets/usda_logo.dart';

class ECitizenServicesScreen extends StatefulWidget {
  const ECitizenServicesScreen({super.key});

  @override
  State<ECitizenServicesScreen> createState() => _ECitizenServicesScreenState();
}

class _ECitizenServicesScreenState extends State<ECitizenServicesScreen> {
  final TextEditingController _referenceController = TextEditingController();
  String selectedCurrency = 'USD';
  bool isLoading = false;

  final List<String> currencies = ['USD', 'KES', 'EUR', 'USDA'];

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  void _checkStatus() async {
    if (_referenceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a reference number',
            style: const TextStyle(fontFamily: 'Satoshi'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final bill = await ECitizenService.validateBill(
        refNo: _referenceController.text.trim(),
      );

      if (mounted) {
        setState(() {
          isLoading = false;
        });

        if (bill != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ECitizenDetailsScreen(
                bill: bill,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(fontFamily: 'Satoshi'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCurrencyDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Select Currency',
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.map((currency) {
            final isUsda = currency == 'USDA';
            return ListTile(
              leading: isUsda
                  ? USDALogo(size: 20)
                  : null,
              title: Text(
                currency,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: textColor,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                setState(() {
                  selectedCurrency = currency;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final labelColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final iconColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.white24 : Colors.black12;
    final arrowBg = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
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
                                color: arrowBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_back_outlined,
                                color: iconColor,
                                size: 20.r,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'E-Citizen Services',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                color: textColor,
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

                    // Reference Number Input
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reference Number',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              color: labelColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          TextField(
                            controller: _referenceController,
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              color: textColor,
                              fontSize: 16.sp,
                            ),
                            decoration: buildUnderlineInputDecoration(
                              context: context,
                              label: '',
                              prefixIcon: Icon(
                                Icons.numbers_outlined,
                                color: iconColor,
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            'Currency',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              color: labelColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          GestureDetector(
                            onTap: _showCurrencyDialog,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: borderColor,
                                    width: 1.w,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  selectedCurrency == 'USDA'
                                      ? USDALogo(size: 20)
                                      : Icon(
                                          Icons.monetization_on_outlined,
                                          color: iconColor,
                                        ),
                                  SizedBox(width: 12.w),
                                  Text(
                                    selectedCurrency,
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      color: textColor,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    color: iconColor.withOpacity(0.7),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Check Status Button (Fixed at bottom)
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _checkStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: buttonGreen.withOpacity(0.5),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 24.r,
                          height: 24.r,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.w,
                          ),
                        )
                      : Text(
                          'Check Status',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
