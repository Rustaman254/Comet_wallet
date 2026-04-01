import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_state.dart';
import '../constants/colors.dart';
import '../services/toast_service.dart';
import '../services/wallet_service.dart';
import '../widgets/usda_logo.dart';
import '../utils/format_utils.dart';
import 'mobile_withdraw_screen.dart';
import 'send_money_screen.dart';
import 'send_mobile_number_screen.dart';
import 'bank_withdraw_screen.dart';

class WithdrawMoneyScreen extends StatefulWidget {
  const WithdrawMoneyScreen({super.key});

  @override
  State<WithdrawMoneyScreen> createState() => _WithdrawMoneyScreenState();
}

class _WithdrawMoneyScreenState extends State<WithdrawMoneyScreen> {
  String selectedMethod = 'Mobile Money';
  String selectedCurrency = 'KES';
  late PageController _balancePageController;
  int _currentBalancePage = 0;

  final List<Map<String, dynamic>> _withdrawMethods = [
    {
      'name': 'Withdraw to Another Wallet',
      'icon': Icons.account_balance_wallet_outlined,
      'account': 'Transfer to another wallet',
      'isAvailable': true,
    },
    {
      'name': 'Withdraw to Mobile Number',
      'icon': Icons.phone_android_outlined,
      'account': 'Send via mobile money',
      'isAvailable': true,
    },
    // {
    //   'name': 'Mobile Money',
    //   'icon': Icons.phone_android_outlined,
    //   'account': 'M-Pesa / T-Pesa',
    //   'isAvailable': true,
    // },
    {
      'name': 'Bank Account',
      'icon': Icons.account_balance_outlined,
      'account': 'Pesalink / Bank Transfer',
      'isAvailable': true,
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
    _balancePageController = PageController();
    _balancePageController.addListener(_onBalancePageChanged);
  }

  @override
  void dispose() {
    _balancePageController.dispose();
    super.dispose();
  }

  void _onBalancePageChanged() {
    if (_balancePageController.page != null) {
      final page = _balancePageController.page!.round();
      if (page != _currentBalancePage) {
        setState(() {
          _currentBalancePage = page;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        // Extract balances from state
        List<Map<String, dynamic>> balances = [];
        bool isLoading = state is WalletLoading;

        if (state is WalletLoaded) {
          balances = List<Map<String, dynamic>>.from(state.balances);
        } else if (state is WalletBalanceUpdated) {
          balances = List<Map<String, dynamic>>.from(state.balances);
        }

        // Get current balance info for method navigation
        double currentBalance = 0.0;
        String currentCurrency = 'KES';
        if (balances.isNotEmpty && _currentBalancePage < balances.length) {
          currentCurrency = balances[_currentBalancePage]['currency'] ?? 'KES';
          currentBalance = double.tryParse(
              balances[_currentBalancePage]['amount']?.toString() ?? '0') ?? 0.0;
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
                            style: TextStyle(fontFamily: 'Outfit',
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

                  // Scrollable Balance Section — PageView like Home screen
                  SizedBox(
                    height: 160.h,
                    child: isLoading && balances.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: primaryBrandColor,
                            ),
                          )
                        : (balances.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(20.r),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        primaryBrandColor,
                                        primaryBrandColor.withValues(alpha: 0.8),
                                        secondaryBrandColor.withValues(alpha: 0.8),
                                      ],
                                    ),
                                    border: Border.all(color: cardBorder, width: 1.w),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Available Balance',
                                        style: TextStyle(fontFamily: 'Outfit',
                                          color: Colors.white70,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        'KES 0.00',
                                        style: TextStyle(fontFamily: 'Outfit',
                                          color: Colors.white,
                                          fontSize: 32.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : PageView.builder(
                                controller: _balancePageController,
                                itemCount: balances.length,
                                itemBuilder: (context, index) {
                                  final balance = balances[index];
                                  final currency = balance['currency'] ?? '';
                                  final isUSDA = currency == 'USDA';
                                  final amount = double.tryParse(
                                      balance['amount']?.toString() ?? '0') ?? 0.0;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(20.r),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: Theme.of(context).brightness == Brightness.dark
                                              ? [
                                                  primaryBrandColor,
                                                  primaryBrandColor.withValues(alpha: 0.8),
                                                  secondaryBrandColor.withValues(alpha: 0.8),
                                                ]
                                              : [
                                                  const Color(0xFF2563EB),
                                                  const Color(0xFF3B82F6),
                                                  const Color(0xFF60A5FA),
                                                ],
                                        ),
                                        border: Border.all(color: cardBorder, width: 1.w),
                                        borderRadius: BorderRadius.circular(20.r),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Available Balance',
                                                style: TextStyle(fontFamily: 'Outfit',
                                                  color: Colors.white70,
                                                  fontSize: 14.sp,
                                                ),
                                              ),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(20.r),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    isUSDA
                                                        ? const USDALogo(size: 16)
                                                        : Text(
                                                            USDALogo.getFlag(currency),
                                                            style: TextStyle(fontSize: 14.sp),
                                                          ),
                                                    SizedBox(width: 4.w),
                                                    Text(
                                                      currency,
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        color: Colors.white,
                                                        fontSize: 12.sp,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 16.h),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                balance['symbol'] ?? (isUSDA ? '\$' : currency),
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  color: Colors.white.withValues(alpha: 0.7),
                                                  fontSize: 20.sp,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                FormatUtils.formatAmount(amount),
                                                style: TextStyle(fontFamily: 'Outfit',
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
                                  );
                                },
                              )),
                  ),

                  // Page Indicators
                  if (balances.length > 1) ...[
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        balances.length,
                        (index) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 3.w),
                          width: _currentBalancePage == index ? 24.w : 8.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: _currentBalancePage == index
                                ? primaryBrandColor
                                : Colors.grey[600],
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  // Withdrawal Method
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Withdrawal Method',
                          style: TextStyle(fontFamily: 'Outfit',
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
                                
                                if (method['name'] == 'Withdraw to Another Wallet') {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SendMoneyScreen(),
                                    ),
                                  );
                                } else if (method['name'] == 'Withdraw to Mobile Number') {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SendMobileNumberScreen(),
                                    ),
                                  );
                                } else if (method['name'] == 'Mobile Money') {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => MobileWithdrawScreen(
                                          currency: currentCurrency,
                                          maxBalance: currentBalance,
                                        ),
                                      ),
                                    );
                                } else if (method['name'] == 'Bank Account') {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const BankWithdrawScreen(),
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
                                        color: isSelected ? primaryBrandColor : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                                        size: 24.r,
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              method['name'],
                                              style: TextStyle(fontFamily: 'Outfit',
                                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                              fontSize: 16.sp,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            method['account'] ?? '',
                                            style: TextStyle(fontFamily: 'Outfit',
                                              color: isAvailable ? (Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black45) : primaryBrandColor,
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
