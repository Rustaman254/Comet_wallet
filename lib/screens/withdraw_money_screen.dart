import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../services/toast_service.dart';
import '../services/wallet_service.dart';
import 'mobile_withdraw_screen.dart';

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
      'account': 'Safaricom M-Pesa',
      'isAvailable': true,
    },
    {
      'name': 'T-Kash',
      'icon': Icons.account_balance_wallet,
      'account': 'Telkom T-Kash',
      'isAvailable': true,
      'color': Color(0xFF0066CC),
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
    _fetchBalance();
  }


  Future<void> _fetchBalance() async {
    try {
      final balanceData = await WalletService.getWalletBalance();
      if (mounted) {
        setState(() {
          _balance = double.tryParse(balanceData['balance'].toString()) ?? 0.0;
          selectedCurrency = balanceData['currency'] ?? 'KES';
          _isBalanceLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBalanceLoading = false);
        ToastService().showError(context, 'Failed to load balance');
      }
    }
  }

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
                        'Withdraw Money',
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
              const SizedBox(height: 24),
              // Available Balance Card (Same style as Send Money)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                    border: Border.all(color: cardBorder, width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Balance',
                        style: TextStyle(fontFamily: 'Satoshi',
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _isBalanceLoading
                          ? const SizedBox(
                              height: 35,
                              width: 35,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedCurrency,
                                  style: TextStyle(fontFamily: 'Satoshi',
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _balance.toStringAsFixed(2),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontFamily: 'Satoshi',
                                      color: Colors.white,
                                      fontSize: 35,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
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
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._withdrawMethods.map((method) {
                      final isSelected = selectedMethod == method['name'];
                      final isAvailable = method['isAvailable'] as bool;
                      final methodColor = method['color'] as Color?;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: isAvailable ? () {
                            setState(() {
                              selectedMethod = method['name'];
                            });
                            
                            if (method['name'] == 'Mobile Money' || method['name'] == 'T-Kash') {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MobileWithdrawScreen(
                                      currency: selectedCurrency,
                                      maxBalance: _balance,
                                      withdrawMethod: method['name'],
                                    ),
                                  ),
                                );
                            }
                          } : null,
                          child: Opacity(
                            opacity: isAvailable ? 1.0 : 0.5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.white12, width: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    method['icon'],
                                    color: isSelected ? (methodColor ?? buttonGreen) : (methodColor ?? Colors.white70),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          method['name'],
                                          style: TextStyle(fontFamily: 'Satoshi',
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          method['account'],
                                          style: TextStyle(fontFamily: 'Satoshi',
                                            color: isAvailable ? Colors.white54 : buttonGreen,
                                            fontSize: 12,
                                            fontWeight: !isAvailable ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected && isAvailable)
                                    Icon(
                                      Icons.arrow_forward_ios, // Changed to arrow to indicate navigation
                                      color: Colors.white54,
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
  }
}
