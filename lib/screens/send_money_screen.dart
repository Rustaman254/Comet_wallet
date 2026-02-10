import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


import '../constants/colors.dart';
import 'add_contact_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';
import '../utils/format_utils.dart';
import '../services/wallet_service.dart';
import '../services/token_service.dart';
import '../services/logger_service.dart';
import '../services/toast_service.dart';
import '../services/session_service.dart';
import '../utils/input_decoration.dart';
import '../widgets/usda_logo.dart';

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
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _mobileAmountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  String selectedCurrency = 'KES';
  String _mobileCurrency = 'KES';
  int _currentBalancePage = 1;
  bool _isAmountFocused = false;
  bool _isLoading = false;

  final List<String> _favorites = [];
  
  // Phone number prefix mapping
  final Map<String, String> _countryPrefixes = {
    '+254': 'KES', // Kenya
    '+256': 'UGX', // Uganda
    '+255': 'TZS', // Tanzania
    '+250': 'RWF', // Rwanda
    '+27': 'ZAR',  // South Africa
    '+234': 'NGN', // Nigeria
    '+233': 'GHS', // Ghana
  };

  @override
  void initState() {
    super.initState();
    _balancePageController.addListener(_onBalancePageChanged);
    _amountFocusNode.addListener(_onAmountFocusChange);
    _phoneController.addListener(_onPhoneChanged);
    
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!;
    }

    // Set initial page to KES if it's there
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_balancePageController.hasClients) {
        _balancePageController.jumpToPage(1);
      }
    });
  }

  void _onPhoneChanged() {
    final phone = _phoneController.text.trim();
    String detectedCurrency = _mobileCurrency;
    
    // Check for country codes
    for (var prefix in _countryPrefixes.keys) {
      if (phone.startsWith(prefix)) {
        detectedCurrency = _countryPrefixes[prefix]!;
        break;
      }
    }

    if (detectedCurrency != _mobileCurrency) {
      setState(() {
        _mobileCurrency = detectedCurrency;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _balancePageController.dispose();
    _amountController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _mobileAmountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _onAmountFocusChange() {
    setState(() {
      _isAmountFocused = _amountFocusNode.hasFocus;
    });
  }

  void _onAmountChanged(String value) {
    SessionService.recordActivity();
    setState(() {});
  }

  void _onBalancePageChanged() {
    if (_balancePageController.hasClients && _balancePageController.page != null) {
      final page = _balancePageController.page!.round();
      if (_currentBalancePage != page) {
        final state = context.read<WalletBloc>().state;
        List<Map<String, dynamic>> balances = [];
        if (state is WalletLoaded) {
          balances = state.balances;
        } else if (state is WalletBalanceUpdated) {
          balances = state.balances;
        }

        setState(() {
          _currentBalancePage = page;
          if (balances.isNotEmpty && page < balances.length) {
            selectedCurrency = balances[page]['currency'];
          }
        });
      }
    }
  }

  Future<void> _handleTransfer() async {
    SessionService.recordActivity();
    
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
        context.read<WalletBloc>().add(SendMoney(
          amount: amount,
          recipientPhone: email,
          transactionType: 'transfer',
          currency: selectedCurrency,
        ));

        final successData = {
          'message': 'Transfer Successful',
          'status': 'SUCCESS',
          'transfer': {
            'to_user_name': response['user']?['name'] ?? email,
            'to_user_email': response['user']?['email'] ?? email,
            'amount': amount.toString(),
            'currency': selectedCurrency,
            'from_user_email': 'Me',
          }
        };
        _showSuccessSheet(successData);
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

  Future<void> _handleMobileTransfer() async {
    SessionService.recordActivity();
    
    final phone = _phoneController.text.trim();
    final amountText = _mobileAmountController.text.trim();
    
    if (phone.isEmpty) {
      ToastService().showError(context, 'Please enter recipient phone number');
      return;
    }
    
    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) {
      ToastService().showError(context, 'Please enter a valid amount');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await WalletService.sendMoney(
        recipientPhone: phone,
        amount: amount,
        currency: _mobileCurrency,
        description: 'Mobile Transfer',
      );

      if (mounted) {
        context.read<WalletBloc>().add(SendMoney(
          amount: amount,
          recipientPhone: phone,
          transactionType: 'mobile_transfer',
          currency: _mobileCurrency,
        ));

        final successData = {
          'message': 'Mobile Transfer Successful',
          'status': 'SUCCESS',
          'transfer': {
            'to_user_name': 'Mobile User',
            'to_user_email': phone,
            'amount': amount.toString(),
            'currency': _mobileCurrency,
            'from_user_email': 'Me',
          }
        };
        _showSuccessSheet(successData);
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

  Future<void> _handleUSDATransfer() async {
    SessionService.recordActivity();
    
    final address = _addressController.text.trim();
    final amountText = _amountController.text.trim();
    
    if (address.isEmpty) {
      ToastService().showError(context, 'Please enter recipient Cardano address');
      return;
    }
    
    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) {
      ToastService().showError(context, 'Please enter a valid amount');
      return;
    }

    setState(() => _isLoading = true);

    try {
      context.read<WalletBloc>().add(TransferUSDA(
        recipientAddress: address,
        amount: amount,
      ));

      final successData = {
        'message': 'USDA Transfer Successful',
        'status': 'SUCCESS',
        'transfer': {
          'to_user_name': 'Cardano Address',
          'to_user_email': address,
          'amount': amount.toString(),
          'currency': 'USDA',
          'from_user_email': 'Me',
        }
      };
      
      _showSuccessSheet(successData);
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
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? darkBackground : lightCardBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.r),
            topRight: Radius.circular(30.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.r,
              height: 80.r,
              decoration: BoxDecoration(
                color: buttonGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_outline, color: buttonGreen, size: 50.r),
            ),
            SizedBox(height: 16.h),
            Text(
              response['message'] ?? 'Transfer Successful',
              style: TextStyle(fontFamily: 'Satoshi',
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24.h),
            _buildDetailRow('To', transfer['to_user_name'] ?? transfer['to_user_email'] ?? 'N/A'),
            _buildDetailRow('Amount', '${transfer['amount']} ${transfer['currency']}'),
            _buildDetailRow('Email', transfer['to_user_email'] ?? 'N/A'),
            _buildDetailRow('Status', response['status']?.toUpperCase() ?? 'SUCCESS'),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('Done', style: TextStyle(fontFamily: 'Satoshi',fontWeight: FontWeight.bold, fontSize: 16.sp)),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontFamily: 'Satoshi',color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54, fontSize: 14.sp)),
          Text(value, style: TextStyle(fontFamily: 'Satoshi',color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 14.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showCurrencyDialog() {
    final state = context.read<WalletBloc>().state;
    List<Map<String, dynamic>> balances = [];
    if (state is WalletLoaded) {
      balances = state.balances;
    } else if (state is WalletBalanceUpdated) {
      balances = state.balances;
    }

    if (balances.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? cardBackground : lightCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Select Currency',
          style: TextStyle(fontFamily: 'Satoshi',
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: balances.map((balance) {
            final currency = balance['currency'];
            return ListTile(
              leading: currency == 'USDA' 
                ? const USDALogo(size: 28)
                : Container(
                    width: 28.r,
                    height: 28.r,
                    alignment: Alignment.center,
                    child: Text(
                      USDALogo.getFlag(currency),
                      style: TextStyle(fontSize: 20.sp),
                    ),
                  ),
              title: Text(
                '${USDALogo.getFlag(currency)} $currency',
                style: TextStyle(fontFamily: 'Satoshi',color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 16),
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
    return DefaultTabController(
      length: 2, // Changed to 2 tabs (Wallet and USDA)
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            final balances = state is WalletLoaded ? state.balances : 
                           (state is WalletBalanceUpdated ? state.balances : <Map<String, dynamic>>[]);
            
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
                        icon: Icon(
                          Icons.arrow_back,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          size: 24,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Send Money', // Generic title
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Satoshi',
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // TabBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    height: 45.h,
                    decoration: const BoxDecoration(
                      color: Colors.transparent, // Removed background color
                    ),
                    child: TabBar(
                      indicatorColor: buttonGreen, // Primary color for indicator
                      indicatorWeight: 2,
                      labelColor: buttonGreen, // Primary color for active text
                      unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                      labelStyle: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      tabs: const [
                        Tab(text: 'Wallet'),
                        Tab(text: 'USDA (Cardano)'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildSendToEmailTab(balances),
                      _buildTransferUSDATab(balances),
                    ],
                  ),
                ),
              ],
            );
          }
        ),
      ),
    ));
  }

  // ... (existing _buildSendToEmailTab implementation)
  
  Widget _buildSendToMobileTab(List<Map<String, dynamic>> balances) {
    // Find balance for detected mobile currency
    String mobileBalance = '0.00';
    try {
      final currencyWallet = balances.firstWhere(
        (b) => b['currency'] == _mobileCurrency,
        orElse: () => {'amount': '0.00'},
      );
      mobileBalance = currencyWallet['amount'].toString();
    } catch (_) {}

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Section at Top (Dynamic based on phone number)
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${USDALogo.getFlag(_mobileCurrency)} $_mobileCurrency ', // Dynamic currency
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: buttonGreen,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        FormatUtils.formatAmount(double.tryParse(mobileBalance) ?? 0.0),
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: buttonGreen,
                          fontSize: 36.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            
            // Title
            Text(
              'Send to Mobile Money',
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24.h),
            
            // Phone Number
            Text(
              'Recipient Phone Number',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 16,
              ),
              decoration: buildUnderlineInputDecoration(
                context: context,
                label: '',
                hintText: 'e.g. +2547...',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Currency detected: ${USDALogo.getFlag(_mobileCurrency)} $_mobileCurrency',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black45,
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 24.h),
            
            // Amount
            Text(
              'Amount',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _mobileAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 16,
              ),
              decoration: buildUnderlineInputDecoration(
                context: context,
                label: '',
                hintText: 'Enter amount',
              ),
            ),
            SizedBox(height: 48.h),

            // Send Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleMobileTransfer,
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
                        'Send to Mobile',
                        style: TextStyle(fontFamily: 'Satoshi',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  // ... (existing _buildTransferUSDATab implementation)

  Widget _buildSendToEmailTab(List<Map<String, dynamic>> balances) {
    return SingleChildScrollView(
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
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
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
                          '${USDALogo.getFlag(balances[_currentBalancePage]['currency'])} ${balances[_currentBalancePage]['currency']} ',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            color: buttonGreen,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          FormatUtils.formatAmount(double.tryParse(balances[_currentBalancePage]['amount'].toString()) ?? 0.0),
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
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24.h),
            
            // Recipient Email
            Text(
              'Recipient Email',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _emailController,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 16,
              ),
              decoration: buildUnderlineInputDecoration(
                context: context,
                label: '',
                hintText: 'Enter recipient email address',
              ),
              onChanged: (v) {
                SessionService.recordActivity();
                setState(() {});
              },
            ),
            SizedBox(height: 24.h),
            
            // Currency
            Text(
              'Currency',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
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
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[400]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (selectedCurrency == 'USDA')
                          const USDALogo(size: 24)
                        else
                          Text(
                            USDALogo.getFlag(selectedCurrency),
                            style: TextStyle(fontSize: 18.sp),
                          ),
                        SizedBox(width: 8.w),
                        Text(
                          selectedCurrency,
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.keyboard_arrow_down, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 20),
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
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 16,
              ),
              decoration: buildUnderlineInputDecoration(
                context: context,
                label: '',
                hintText: 'Enter amount',
              ),
            ),
            SizedBox(height: 32.h),

            // Send Button
            SizedBox(
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
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferUSDATab(List<Map<String, dynamic>> balances) {
    // Find USDA balance
    String usdABalance = '0.00';
    try {
      final usdaWallet = balances.firstWhere((b) => b['currency'] == 'USDA');
      usdABalance = usdaWallet['amount'].toString();
    } catch (_) {}

    return SingleChildScrollView(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Available ',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const USDABadge(height: 20),
                      Text(
                        ' Balance',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const USDALogo(size: 28),
                      SizedBox(width: 8.w),
                      Text(
                        FormatUtils.formatAmount(double.tryParse(usdABalance) ?? 0.0),
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: buttonGreen,
                          fontSize: 36.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            
            // Title
            Text(
              'Transfer USDA (Cardano) to Address',
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24.h),
            
            // Recipient Address
            Text(
              'Recipient Cardano Address',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _addressController,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 16,
              ),
              decoration: buildUnderlineInputDecoration(
                context: context,
                label: '',
                hintText: 'Enter addr_test...',
              ),
              onChanged: (v) => setState(() {}),
            ),
            SizedBox(height: 24.h),
            
            // Amount
            Text(
              'Amount in USDA (Cardano)',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 16,
              ),
              decoration: buildUnderlineInputDecoration(
                context: context,
                label: '',
                hintText: 'Enter amount',
              ),
            ),
            SizedBox(height: 48.h),

            // Send Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleUSDATransfer,
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
                        'Transfer USDA (Cardano)',
                        style: TextStyle(fontFamily: 'Satoshi',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
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
            width: 60.r,
            height: 60.r,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.3) : Colors.grey[400]!,
                width: 2.w,
              ),
            ),
            child: Icon(
              Icons.add_outlined,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              size: 30.r,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add',
            style: TextStyle(fontFamily: 'Satoshi',
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              fontSize: 14.sp,
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
          width: 60.r,
          height: 60.r,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            shape: BoxShape.circle,
            border: Border.all(color: buttonGreen, width: 2.w),
          ),
          child: Center(
            child: Text(
              name[0],
              style: TextStyle(fontFamily: 'Satoshi',
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          name,
          style: TextStyle(fontFamily: 'Satoshi',
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return Container(
      width: isActive ? 24.w : 8.w,
      height: 8.h,
      decoration: BoxDecoration(
        color: isActive ? buttonGreen : Colors.grey[600],
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }

}
