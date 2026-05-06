import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


import '../constants/colors.dart';
import '../services/session_service.dart';
import 'enter_pin_screen.dart';
import 'add_contact_screen.dart';
import 'transaction_details_screen.dart';
import '../models/transaction.dart';
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
import '../widgets/currency_selection_sheet.dart';
import '../widgets/transaction_result_overlay.dart';

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
  TransactionOverlayController? _overlayController;

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

  void _handleTransfer() {
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

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EnterPinScreen(
          recipientName: email,
          amount: amountText,
          currency: selectedCurrency,
          description: 'Wallet Transfer',
          onVerify: (pin) => WalletService.transferWallet(
            toEmail: email,
            amount: amount,
            currency: selectedCurrency,
            pin: pin,
          ),
        ),
      ),
    );
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
    _overlayController = TransactionOverlayController.show(
      context,
      initialMessage: 'Initiating mobile transfer…',
    );

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

        final transactionId = response['transaction_id'] ?? 
                             response['gateway_transaction_id'] ?? 
                             response['transactionId'] ?? 
                             response['id'];

        if (transactionId != null) {
          final idStr = transactionId.toString();
          _overlayController?.showLoading(message: 'Finalizing…');
          
          // Start tracking status via Bloc
          context.read<WalletBloc>().add(TrackTransactionStatus(transactionId: idStr));
          
          // We no longer manually poll here. The BlocListener will handle it.
        } else {
          _overlayController?.showSuccess(
            title: 'Mobile Transfer Successful!',
            subtitle: 'Sent $_mobileCurrency ${FormatUtils.formatAmount(amount)} to $phone',
            onAutoDismiss: () => Navigator.of(context).popUntil((route) => route.isFirst),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        
        _overlayController?.showFailure(
          message: errorMessage,
          onRetry: null,
          onCancel: () => _overlayController?.dismiss(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleUSDATransfer() {
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

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EnterPinScreen(
          recipientName: address,
          amount: amountText,
          currency: 'USDA',
          description: 'USDA Transfer (Cardano)',
          onVerify: (pin) => WalletService.transferUSDA(
            recipientAddress: address,
            amount: amount,
          ),
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
          Text(label, style: TextStyle(fontFamily: 'Outfit',color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54, fontSize: 14.sp)),
          Text(value, style: TextStyle(fontFamily: 'Outfit',color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 14.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showCurrencyDialog() {
    final state = context.read<WalletBloc>().state;
    List<Map<String, String>> supportedCurrencies = [];
    List<Map<String, dynamic>> balances = [];
    
    if (state is WalletLoaded) {
      supportedCurrencies = state.supportedCurrencies ?? [];
      balances = state.balances;
    } else if (state is WalletBalanceUpdated) {
      supportedCurrencies = state.supportedCurrencies ?? [];
      balances = state.balances;
    }

    if (supportedCurrencies.isEmpty && balances.isNotEmpty) {
      // Fallback to balances if supportedCurrencies not yet fetched
      supportedCurrencies = balances.map((b) => {
        'code': b['currency'].toString(),
        'name': b['currency'].toString(),
      }).toList();
    }
    
    if (supportedCurrencies.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CurrencySelectionSheet(
        currencies: supportedCurrencies,
        selectedCurrency: selectedCurrency,
        onCurrencySelected: (currency) {
          final index = balances.indexWhere((b) => b['currency'] == currency);
          if (index != -1) {
             setState(() {
              selectedCurrency = currency;
            });
            _balancePageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
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
          child: BlocListener<WalletBloc, WalletState>(
            listener: (context, state) {
              if (state is TransactionStatusUpdate) {
                final status = state.status.toLowerCase();
                if (status == 'completed' || status == 'success' || status == 'complete') {
                  _overlayController?.showSuccess(
                    title: 'Withdrawal Successful',
                    subtitle: state.message,
                    onAutoDismiss: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  );
                } else if (status == 'failed' || status == 'timeout') {
                  _overlayController?.showFailure(
                    message: state.message,
                    onRetry: null,
                    onCancel: () => _overlayController?.dismiss(),
                  );
                }
              }
            },
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
                              'Withdraw Money', // Generic title
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: 'Outfit',
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
                          indicatorColor: primaryBrandColor, // Primary color for indicator
                          indicatorWeight: 2,
                          labelColor: primaryBrandColor, // Primary color for active text
                          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                          labelStyle: TextStyle(
                            fontFamily: 'Outfit',
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
              },
            ),
          ),
        ),
      ),
    );
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
                      fontFamily: 'Outfit',
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
                          fontFamily: 'Outfit',
                          color: primaryBrandColor,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        FormatUtils.formatAmount(double.tryParse(mobileBalance) ?? 0.0),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: primaryBrandColor,
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
                fontFamily: 'Outfit',
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
                  backgroundColor: primaryBrandColor,
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
                        style: TextStyle(fontFamily: 'Outfit',
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
                      fontFamily: 'Outfit',
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
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
                          '${USDALogo.getFlag(selectedCurrency)} $selectedCurrency ',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: primaryBrandColor,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          FormatUtils.formatAmount(
                            double.tryParse(
                              balances.firstWhere(
                                (b) => b['currency'] == selectedCurrency,
                                orElse: () => {'amount': '0.0'},
                              )['amount']?.toString() ?? '0.0'
                            ) ?? 0.0
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: primaryBrandColor,
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
                        fontFamily: 'Outfit',
                        color: primaryBrandColor,
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
                fontFamily: 'Outfit',
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
                            fontFamily: 'Outfit',
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
                  backgroundColor: primaryBrandColor,
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
                        'Withdraw money',
                        style: TextStyle(fontFamily: 'Outfit',
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
                          fontFamily: 'Outfit',
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        ' Balance',
                        style: TextStyle(
                          fontFamily: 'Outfit',
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
                      Image.asset(
                        'assets/images/usda_logo_new.png',
                        width: 28.r,
                        height: 28.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        FormatUtils.formatAmount(double.tryParse(usdABalance) ?? 0.0),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: primaryBrandColor,
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
                fontFamily: 'Outfit',
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
                hintText: 'Enter addr1...',
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.qr_code_scanner,
                    color: primaryBrandColor,
                  ),
                  onPressed: () async {
                    // TODO: Implement QR scanner
                    // ToastService().showInfo(context, 'QR Scanner coming soon');
                  },
                ),
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
                  backgroundColor: primaryBrandColor,
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
                        style: TextStyle(fontFamily: 'Outfit',
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
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200],
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.3) : Colors.grey[400]!,
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
            style: TextStyle(fontFamily: 'Outfit',
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
            border: Border.all(color: primaryBrandColor, width: 2.w),
          ),
          child: Center(
            child: Text(
              name[0],
              style: TextStyle(fontFamily: 'Outfit',
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
          style: TextStyle(fontFamily: 'Outfit',
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
        color: isActive ? primaryBrandColor : Colors.grey[600],
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }

}
