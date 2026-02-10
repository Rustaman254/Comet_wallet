import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constants/colors.dart';
import '../services/wallet_service.dart';
import '../services/toast_service.dart';
import '../utils/format_utils.dart';
import '../widgets/usda_logo.dart';
import '../utils/input_decoration.dart';
import 'mobile_payment_confirm_screen.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_state.dart';

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
  String _selectedCurrency = 'KES'; // Track selected currency
  final List<Map<String, String>> _countryCodes = [
    {'code': '+254', 'country': 'Kenya', 'currency': 'KES', 'flag': '🇰🇪'},
    {'code': '+255', 'country': 'Tanzania', 'currency': 'TZS', 'flag': '🇹🇿'},
    {'code': '+256', 'country': 'Uganda', 'currency': 'UGX', 'flag': '🇺🇬'},
    {'code': '+250', 'country': 'Rwanda', 'currency': 'RWF', 'flag': '🇷🇼'},
  ];

  List<Map<String, dynamic>> _balances = [];

  @override
  void initState() {
    super.initState();
    _balancePageController.addListener(_onBalancePageChanged);
    _fetchWalletBalance();
  }

  Future<void> _fetchWalletBalance() async {
    // Balance is now fetched from WalletBloc in build method
    if (mounted) {
      setState(() {
        _isLoadingBalance = false;
      });
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

  String _getBalanceForCurrency(String currency, List<Map<String, dynamic>> balances) {
    try {
      // Find the balance for the selected currency
      final currencyBalance = balances.firstWhere(
        (b) => b['currency'] == currency,
        orElse: () => {'amount': '0.0'},
      );
      final balance = double.tryParse(currencyBalance['amount']?.toString() ?? '0.0') ?? 0.0;
      return FormatUtils.formatAmount(balance);
    } catch (e) {
      return '0.00';
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
          currency: _selectedCurrency,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        // Get balances from WalletBloc state
        final balances = state is WalletLoaded ? state.balances : 
                        (state is WalletBalanceUpdated ? state.balances : <Map<String, dynamic>>[]);
        
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
                            if (balances.isNotEmpty)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${USDALogo.getFlag(_selectedCurrency)} $_selectedCurrency ',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      color: buttonGreen,
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _getBalanceForCurrency(_selectedCurrency, balances),
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
                            width: 150.w,
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
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    final country = _countryCodes.firstWhere((c) => c['code'] == newValue);
                                    setState(() {
                                      _selectedCountryCode = newValue;
                                      _selectedCurrency = country['currency']!;
                                    });
                                  }
                                },
                                items: _countryCodes.map<DropdownMenuItem<String>>((Map<String, String> country) {
                                  return DropdownMenuItem<String>(
                                    value: country['code'],
                                    child: Row(
                                      children: [
                                        Text(country['flag']!, style: TextStyle(fontSize: 16.sp)),
                                        SizedBox(width: 6.w),
                                        Text(country['code']!, style: TextStyle(fontSize: 14.sp)),
                                      ],
                                    ),
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
      },
    );
  }
}
