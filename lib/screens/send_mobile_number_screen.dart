import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    // Optional: Pre-fill user phone or default behavior if needed, generally send screens start empty 
    // or we could load contacts. For now starting empty.
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
              'date': 'Today', // API doesn't return date yet
              'change': '+0.00', // Placeholder
            }
          ];
          selectedCurrency = _balances[0]['currency'];
        });
      }
    } catch (e) {
      if (mounted) {
        // Fallback or empty balance state
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

  void _showCurrencyDialog() {
    if (_balances.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Select Currency',
          style: TextStyle(fontFamily: 'Outfit',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _balances.map((balance) {
            return ListTile(
              title: Text(
                balance['currency'],
                style: TextStyle(fontFamily: 'Outfit',color: Colors.white, fontSize: 16),
              ),
              onTap: () {
                final index = _balances.indexOf(balance);
                _balancePageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _proceedToConfirm() {
    final rawPhone = _phoneController.text.trim();
    final amountText = _amountController.text.trim();

    if (rawPhone.isEmpty) {
      ToastService().showError(context, 'Please enter a mobile number');
      return;
    }

    // Validate phone structure (basic check)
    if (rawPhone.startsWith('0')) {
       ToastService().showError(context, 'Phone number should not start with 0');
       return;
    }
    if (rawPhone.length != 9) { // Assuming 9 digits for 7XX...
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

    // Construct full phone with country code
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
        child: SingleChildScrollView(
          controller: _scrollController,
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
                        'Send to Mobile',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Outfit',
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
              // Total Balance Card - Scrollable
              SizedBox(
                height: 200,
                child: _isLoadingBalance 
                  ? Center(child: CircularProgressIndicator(color: buttonGreen))
                  : PageView(
                  controller: _balancePageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentBalancePage = index;
                      if (index < _balances.length) {
                        selectedCurrency = _balances[index]['currency'];
                      }
                    });
                  },
                  children: _balances.map((balance) {
                    return Padding(
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Balance',
                                  style: TextStyle(fontFamily: 'Outfit',
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _showCurrencyDialog,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      balance['currency'],
                                      style: TextStyle(fontFamily: 'Outfit',
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  balance['currency'],
                                  style: TextStyle(fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  balance['amount'],
                                  style: TextStyle(fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize: 35,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date',
                                      style: TextStyle(fontFamily: 'Outfit',
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      balance['date'],
                                      style: TextStyle(fontFamily: 'Outfit',
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      balance['change'],
                                      style: TextStyle(fontFamily: 'Outfit',
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.trending_up_outlined,
                                      color: buttonGreen,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              // Page indicators
              // Only show if we have multiple balances (future proofing)
              if (_balances.length > 1) 
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_balances.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _buildPageIndicator(index == _currentBalancePage),
                    );
                  }),
                ),
              if (_balances.length > 1) const SizedBox(height: 24) else const SizedBox(height: 32),

              // Mobile Number Input - MSISDN Style
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mobile Number',
                      style: TextStyle(fontFamily: 'Outfit',
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         // Country Code Dropdown
                        Container(
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3),
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
                              style: TextStyle(fontFamily: 'Outfit',
                                color: Colors.white,
                                fontSize: 16,
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
                        const SizedBox(width: 12),
                        // Number Input
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            style: TextStyle(fontFamily: 'Outfit',
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            keyboardType: TextInputType.phone,
                            maxLength: 9, // Enforce 9 chars for standard non-0 format
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
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Amount Input - Modern Underline Style
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Amount',
                      style: TextStyle(fontFamily: 'Outfit',
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      style: TextStyle(fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 24, // Highlighting amount
                        fontWeight: FontWeight.bold,
                      ),
                      keyboardType: TextInputType.number,
                      decoration: buildUnderlineInputDecoration(
                        context: context,
                        label: '',
                        hintText: '0.00',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            selectedCurrency,
                            style: TextStyle(fontFamily: 'Outfit',
                              color: buttonGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              // Continue button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _proceedToConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return Container(
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? buttonGreen : Colors.grey[600],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
