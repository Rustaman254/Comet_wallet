import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_state.dart';
import '../constants/colors.dart';
import '../services/toast_service.dart';
import '../services/wallet_service.dart';
import 'mobile_withdraw_screen.dart';
import '../widgets/usda_logo.dart';

class WithdrawMoneyScreen extends StatefulWidget {
  const WithdrawMoneyScreen({super.key});

  @override
  State<WithdrawMoneyScreen> createState() => _WithdrawMoneyScreenState();
}

class _WithdrawMoneyScreenState extends State<WithdrawMoneyScreen> {
  String selectedMethod = 'Mobile Money';
  String selectedCurrency = 'KES';
  double _balance = 0.0;
  bool _isBalanceLoading = true;

  final List<Map<String, dynamic>> _withdrawMethods = [
    {
      'name': 'Mobile Money',
      'icon': Icons.phone_android_outlined,
      'account': 'M-Pesa / T-Pesa',
      'isAvailable': true,
    },
    {
      'name': 'Bank Account',
      'icon': Icons.account_balance_outlined,
      'account': 'Coming Soon',
      'isAvailable': false,
    },
    {
      'name': 'ATM Withdraw',
      'icon': Icons.atm_outlined,
      'account': 'Coming Soon',
      'isAvailable': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Balance is now managed by WalletBloc
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        // Extract balance and currency from state
        double balance = 0.0;
        String currency = 'KES';
        bool isLoading = state is WalletLoading;

        if (state is WalletLoaded) {
          if (state.balances.isNotEmpty) {
            currency = state.balances[0]['currency'];
            balance = double.tryParse(state.balances[0]['amount'].toString()) ?? 0.0;
          }
        } else if (state is WalletBalanceUpdated) {
          if (state.balances.isNotEmpty) {
            currency = state.balances[0]['currency'];
            balance = double.tryParse(state.balances[0]['amount'].toString()) ?? 0.0;
          }
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                            width: 40.r,
                            height: 40.r,
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withValues(alpha: 0.3) : Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back_outlined,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              size: 20.r,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Withdraw Money',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Satoshi',
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Available Balance Card (Original Style preserved)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            darkGreen,
                            darkGreen.withValues(alpha: 0.8),
                            lightGreen.withValues(alpha: 0.3),
                          ],
                        ),
                        border: Border.all(color: cardBorder, width: 1.w),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Balance',
                            style: TextStyle(fontFamily: 'Satoshi',
                              color: Colors.white70,
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          isLoading && balance == 0.0
                              ? SizedBox(
                                  height: 32.r,
                                  width: 32.r,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.w),
                                )
                              : Text(
                                  '${USDALogo.getFlag(currency)} $currency ${balance.toStringAsFixed(2)}',
                                  style: TextStyle(fontFamily: 'Satoshi',
                                    color: Colors.white,
                                    fontSize: 32.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Withdrawal Method
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Withdrawal Method',
                          style: TextStyle(fontFamily: 'Satoshi',
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        ..._withdrawMethods.map((method) {
                          final isSelected = selectedMethod == method['name'];
                          final isAvailable = method['isAvailable'] as bool;
                          
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: GestureDetector(
                              onTap: isAvailable ? () {
                                setState(() {
                                  selectedMethod = method['name'];
                                });
                                
                                if (method['name'] == 'Mobile Money') {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => MobileWithdrawScreen(
                                          currency: currency,
                                          maxBalance: balance,
                                        ),
                                      ),
                                    );
                                }
                              } : null,
                              child: Opacity(
                                opacity: isAvailable ? 1.0 : 0.5,
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey[300]!, width: 0.5.h),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        method['icon'],
                                        color: isSelected ? buttonGreen : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                                        size: 24.r,
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              method['name'],
                                              style: TextStyle(fontFamily: 'Satoshi',
                                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                              fontSize: 16.sp,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            method['account'],
                                            style: TextStyle(fontFamily: 'Satoshi',
                                              color: isAvailable ? (Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black45) : buttonGreen,
                                              fontSize: 12,
                                              fontWeight: !isAvailable ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected && isAvailable)
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.grey,
                                        size: 16,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
    },
  );
}
}
