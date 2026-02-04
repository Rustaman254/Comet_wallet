import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/colors.dart';
import '../services/wallet_service.dart';
import '../services/toast_service.dart';

import '../utils/input_decoration.dart';
import 'mobile_payment_confirm_screen.dart';

class SendMobileNumberScreen extends StatefulWidget {
  const SendMobileNumberScreen({super.key});

  @override
  State<SendMobileNumberScreen> createState() => _SendMobileNumberScreenState();
}

class _SendMobileNumberScreenState extends State<SendMobileNumberScreen> {
  final ScrollController _scrollController = ScrollController();
  final PageController _balancePageController = PageController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  String selectedCurrency = 'KES'; // Default to KES
  int _currentBalancePage = 0;
  bool _isLoadingBalance = true;

  // Phone input related variables
  String _selectedCountryCode = '+254';
  final List<Map<String, String>> _countryCodes = [
    {'code': '+254', 'country': 'Kenya'},
    {'code': '+255', 'country': 'Tanzania'},
    {'code': '+256', 'country': 'Uganda'},
    {'code': '+250', 'country': 'Rwanda'},
  ];

  List<Map<String, dynamic>> _balances = [];

  @override
  void initState() {
    super.initState();
    _balancePageController.addListener(_onBalancePageChanged);
    _fetchWalletBalance();
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final balanceData = await WalletService.getWalletBalance();
      if (mounted) {
        setState(() {
          _balances = [
            {
              'currency': balanceData['currency'] ?? 'KES',
              'amount': (balanceData['balance'] ?? 0.0).toString(),
              'date': 'Today',
              'change': '+0.00',
            }
          ];
          selectedCurrency = _balances[0]['currency'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _balances = [
            {
              'currency': 'KES',
              'amount': '0.00',
              'date': 'Today',
              'change': '0.00',
            }
          ];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBalance = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _balancePageController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _balancePageController.removeListener(_onBalancePageChanged);
    super.dispose();
  }

  void _onBalancePageChanged() {
    if (_balancePageController.page != null && _balances.isNotEmpty) {
      final page = _balancePageController.page!.round();
      if (page < _balances.length) {
        setState(() {
          _currentBalancePage = page;
          selectedCurrency = _balances[page]['currency'];
        });
      }
    }
  }

  void _proceedToConfirm() {
    final rawPhone = _phoneController.text.trim();
    final amountText = _amountController.text.trim();

    if (rawPhone.isEmpty) {
      ToastService().showError(context, 'Please enter a mobile number');
      return;
    }

    if (rawPhone.startsWith('0')) {
       ToastService().showError(context, 'Phone number should not start with 0');
       return;
    }
    if (rawPhone.length != 9) {
       ToastService().showError(context, 'Phone number must be 9 digits');
       return;
    }

    if (amountText.isEmpty) {
      ToastService().showError(context, 'Please enter an amount');
      return;
    }

    final amountVal = double.tryParse(amountText) ?? 0.0;
    if (amountVal <= 0) {
      ToastService().showError(context, 'Please enter a valid amount');
      return;
    }

    final fullPhoneNumber = '$_selectedCountryCode$rawPhone';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobilePaymentConfirmScreen(
          phoneNumber: fullPhoneNumber,
          amount: amountText,
          currency: selectedCurrency,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20.h),
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Send to Mobile Number',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 40.w),
                ],
              ),
            ),
            SizedBox(height: 40.h),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance Section at Top
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Available Balance',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                color: Colors.white70,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            if (_balances.isNotEmpty && _currentBalancePage < _balances.length)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_balances[_currentBalancePage]['currency']} ',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      color: buttonGreen,
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${_balances[_currentBalancePage]['amount']}',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      color: buttonGreen,
                                      fontSize: 36.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                'KES 0.00',
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  color: buttonGreen,
                                  fontSize: 36.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32.h),
                      
                      // Title
                      Text(
                        'Please enter the payment details',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      
                      // Mobile Number
                      Text(
                        'Mobile Number',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Country Code Dropdown
                          Container(
                            width: 100.w,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[700]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCountryCode,
                                dropdownColor: cardBackground,
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 20),
                                isExpanded: true,
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedCountryCode = newValue;
                                    });
                                  }
                                },
                                items: _countryCodes.map<DropdownMenuItem<String>>((Map<String, String> country) {
                                  return DropdownMenuItem<String>(
                                    value: country['code'],
                                    child: Text(country['code']!),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          // Number Input
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              keyboardType: TextInputType.phone,
                              maxLength: 9,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: buildUnderlineInputDecoration(
                                context: context,
                                label: '',
                                hintText: '712 345 678',
                              ).copyWith(counterText: ''),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      
                      // Amount
                      Text(
                        'Amount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: _amountController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: buildUnderlineInputDecoration(
                          context: context,
                          label: '',
                          hintText: 'Enter amount',
                        ),
                      ),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _proceedToConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Send money',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
