import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


import '../constants/colors.dart';
import 'add_contact_screen.dart';
import '../services/wallet_service.dart';
import '../services/wallet_provider.dart';
import '../services/token_service.dart';
import '../services/logger_service.dart';
import '../services/toast_service.dart';
import '../utils/input_decoration.dart';

class SendMoneyScreen extends StatefulWidget {
  final String? initialEmail;
  final String? initialAmount;

  const SendMoneyScreen({
    super.key,
    this.initialEmail,
    this.initialAmount,
  });

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final ScrollController _scrollController = ScrollController();
  final PageController _balancePageController = PageController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  String selectedCurrency = 'KES';
  int _currentBalancePage = 1; 
  bool _isAmountFocused = false;
  bool _isLoading = false;

  final List<String> _favorites = [
    'yeshbloger@gmail.com',
    'support@antigravity.ai',
  ];



  @override
  void initState() {
    super.initState();
    _balancePageController.addListener(_onBalancePageChanged);
    _amountFocusNode.addListener(_onAmountFocusChange);
    
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!;
    }

    // Set initial page to KES if it's there
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _balancePageController.jumpToPage(1);
    });
  }

  void _onAmountFocusChange() {
    setState(() {
      _isAmountFocused = _amountFocusNode.hasFocus;
    });
  }

  void _onAmountChanged(String value) {
    setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _balancePageController.dispose();
    _amountController.dispose();
    _emailController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _onBalancePageChanged() {
    if (_balancePageController.hasClients && _balancePageController.page != null) {
      final page = _balancePageController.page!.round();
      if (_currentBalancePage != page) {
        setState(() {
          _currentBalancePage = page;
          if (WalletProvider.instance.balances.isNotEmpty && page < WalletProvider.instance.balances.length) {
            selectedCurrency = WalletProvider.instance.balances[page]['currency'];
          }
        });
      }
    }
  }

  Future<void> _handleTransfer() async {
    final email = _emailController.text.trim();
    final amountText = _amountController.text.trim();
    
    if (email.isEmpty) {
      ToastService().showError(context, 'Please enter recipient email');
      return;
    }
    
    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) {
      ToastService().showError(context, 'Please enter a valid amount');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await WalletService.transferWallet(
        toEmail: email,
        amount: amount,
        currency: selectedCurrency,
      );

      if (mounted) {
        _showSuccessSheet(response);
      }
    } catch (e) {
      if (mounted) {
        ToastService().showError(context, e.toString().replaceAll('Exception:', '').trim());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSheet(Map<String, dynamic> response) {
    final transfer = response['transfer'] ?? {};
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: darkBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: buttonGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_outline, color: buttonGreen, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              response['message'] ?? 'Transfer Successful',
              style: TextStyle(fontFamily: 'Satoshi',
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('To', transfer['to_user_name'] ?? transfer['to_user_email'] ?? 'N/A'),
            _buildDetailRow('Amount', '${transfer['amount']} ${transfer['currency']}'),
            _buildDetailRow('From', transfer['from_user_email'] ?? 'N/A'),
            _buildDetailRow('Status', response['status']?.toUpperCase() ?? 'SUCCESS'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  Navigator.pop(context); // Go back to Home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Done', style: TextStyle(fontFamily: 'Satoshi',fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontFamily: 'Satoshi',color: Colors.white70, fontSize: 14)),
          Text(value, style: TextStyle(fontFamily: 'Satoshi',color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showCurrencyDialog() {
    final balances = WalletProvider.instance.balances;
    if (balances.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Select Currency',
          style: TextStyle(fontFamily: 'Satoshi',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: balances.map((balance) {
            return ListTile(
              title: Text(
                balance['currency'],
                style: TextStyle(fontFamily: 'Satoshi',color: Colors.white, fontSize: 16),
              ),
              onTap: () {
                final index = balances.indexOf(balance);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: WalletProvider.instance,
          builder: (context, child) {
            final provider = WalletProvider.instance;
            final balances = provider.balances;
            
            // Ensure selectedCurrency is valid or default
            if (balances.isNotEmpty && _currentBalancePage < balances.length) {
              // Ensure we don't overwrite if user manually changed it, 
              // but here the page view drives the currency selection logic in the original code.
              // So we stick to that pattern: visible card = selected currency for context.
              // However, for sending, we might want to select ANY currency. 
              // But let's follow the existing pattern where swiping changes context.
            }

            return Column(
              children: [
                const SizedBox(height: 20),
                // Fixed Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                          'Send to Another Wallet',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Satoshi',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                                if (balances.isNotEmpty && _currentBalancePage < balances.length)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${balances[_currentBalancePage]['currency']} ',
                                        style: TextStyle(
                                          fontFamily: 'Satoshi',
                                          color: buttonGreen,
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${balances[_currentBalancePage]['amount']}',
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
                          
                          // Recipient Email
                          Text(
                            'Recipient Email',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: buildUnderlineInputDecoration(
                              context: context,
                              label: '',
                              hintText: 'Enter recipient email address',
                            ),
                            onChanged: (v) => setState(() {}),
                          ),
                          SizedBox(height: 24.h),
                          
                          // Currency
                          Text(
                            'Currency',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          GestureDetector(
                            onTap: _showCurrencyDialog,
                            child: Container(
                              padding: EdgeInsets.only(bottom: 12.h),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey[700]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selectedCurrency,
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                  Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                                ],
                              ),
                            ),
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
                          TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: buildUnderlineInputDecoration(
                              context: context,
                              label: '',
                              hintText: 'Enter amount',
                            ),
                          ),
                          SizedBox(height: 24.h),
                          
                          // Payment Reason (optional)
                          Text(
                            'Payment Reason',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          TextFormField(
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: buildUnderlineInputDecoration(
                              context: context,
                              label: '',
                              hintText: 'Optional',
                            ),
                          ),
                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleTransfer,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Send money',
                      style: TextStyle(fontFamily: 'Satoshi',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddContactButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AddContactScreen()));
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.add_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add',
            style: TextStyle(fontFamily: 'Satoshi',
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactAvatar(String name) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            shape: BoxShape.circle,
            border: Border.all(color: buttonGreen, width: 2),
          ),
          child: Center(
            child: Text(
              name[0],
              style: TextStyle(fontFamily: 'Satoshi',
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(fontFamily: 'Satoshi',
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
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
