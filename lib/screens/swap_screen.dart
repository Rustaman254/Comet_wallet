import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';
import '../constants/colors.dart';
import '../services/toast_service.dart';
import '../services/session_service.dart';
import '../utils/input_decoration.dart';
import '../widgets/usda_logo.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _fromCurrency = 'KES';
  String _toCurrency = 'USD';
  
  final List<String> _availableCurrencies = [
    'KES', 'USD', 'TZS', 'UGX', 'EUR', 'GBP', 'ZAR', 'RWF', 'USDA'
  ];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      SessionService.recordActivity();
      setState(() {});
    });
  }

  // Get balance for a specific currency from wallet state
  double _getBalanceForCurrency(String currency, WalletState state) {
    if (state is WalletLoaded) {
      final balance = state.balances.firstWhere(
        (b) => b['currency'] == currency,
        orElse: () => {'balance': 0.0},
      );
      return (balance['balance'] ?? 0.0).toDouble();
    }
    return 0.0;
  }

  // Get exchange rate between two currencies
  // Using approximate rates - in production, fetch from API
  double _getExchangeRate(String from, String to) {
    if (from == to) return 1.0;
    
    // Base rates to USD
    final Map<String, double> toUSD = {
      'KES': 0.0077,  // 1 KES = 0.0077 USD
      'USD': 1.0,
      'TZS': 0.00039, // 1 TZS = 0.00039 USD
      'UGX': 0.00027, // 1 UGX = 0.00027 USD
      'EUR': 1.09,    // 1 EUR = 1.09 USD
      'GBP': 1.27,    // 1 GBP = 1.27 USD
      'ZAR': 0.055,   // 1 ZAR = 0.055 USD
      'RWF': 0.00078, // 1 RWF = 0.00078 USD
      'USDA': 1.0,    // 1 USDA = 1 USD
    };
    
    final fromRate = toUSD[from] ?? 1.0;
    final toRate = toUSD[to] ?? 1.0;
    
    return fromRate / toRate;
  }

  // Calculate estimated receive amount
  double _calculateEstimatedAmount() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final rate = _getExchangeRate(_fromCurrency, _toCurrency);
    return amount * rate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _handleSwap() {
    SessionService.recordActivity();
    
    if (_formKey.currentState!.validate()) {
      if (_fromCurrency == _toCurrency) {
        ToastService().showError(context, 'Please select different currencies');
        return;
      }

      final amount = double.tryParse(_amountController.text) ?? 0.0;
      
      context.read<WalletBloc>().add(SwapCurrencies(
        fromCurrency: _fromCurrency,
        toCurrency: _toCurrency,
        amount: amount,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is WalletSwapSuccess) {
          ToastService().showSuccess(context, state.message);
          Navigator.of(context).pop(true);
        } else if (state is WalletError) {
          ToastService().showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Swap Currencies',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            final isLoading = state is WalletSwapLoading;

            return SingleChildScrollView(
              padding: EdgeInsets.all(24.r),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info Card
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? buttonGreen.withOpacity(0.1)
                            : buttonGreen.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: buttonGreen,
                          width: 1.w,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exchange Currencies',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: getTextColor(context),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Instantly swap between your currency wallets with real-time rates.',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 12.sp,
                              color: getSecondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // From Currency
                    _buildCurrencyDropdown(
                      label: 'From',
                      value: _fromCurrency,
                      onChanged: (val) {
                        SessionService.recordActivity();
                        setState(() => _fromCurrency = val!);
                      },
                    ),
                    SizedBox(height: 8.h),

                    // Available Balance
                    Row(
                      children: [
                        if (_fromCurrency == 'USDA') ...[
                          const USDALogo(size: 16),
                          SizedBox(width: 6.w),
                        ],
                        Text(
                          'Available: ${_getBalanceForCurrency(_fromCurrency, state).toStringAsFixed(2)} $_fromCurrency',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 12.sp,
                            color: buttonGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Conversion Rate Display
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '1 $_fromCurrency = ${_getExchangeRate(_fromCurrency, _toCurrency).toStringAsFixed(4)} $_toCurrency',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 13.sp,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.8) : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Swap Icon
                    Center(
                      child: IconButton(
                        icon: Icon(Icons.swap_vert, color: buttonGreen, size: 32.r),
                        onPressed: () {
                          SessionService.recordActivity();
                          setState(() {
                            final temp = _fromCurrency;
                            _fromCurrency = _toCurrency;
                            _toCurrency = temp;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 8.h),

                    // To Currency
                    _buildCurrencyDropdown(
                      label: 'To',
                      value: _toCurrency,
                      onChanged: (val) {
                        SessionService.recordActivity();
                        setState(() => _toCurrency = val!);
                      },
                    ),
                    SizedBox(height: 32.h),

                    // Amount Field
                    Text(
                      'Amount to Swap',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : Colors.black54,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: buildUnderlineInputDecoration(
                        context: context,
                        label: '',
                        hintText: '0.00',
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: Text(
                            _fromCurrency,
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null) return 'Invalid amount';
                        if (double.parse(value) <= 0) return 'Must be > 0';
                        
                        // Check if user has sufficient balance
                        final amount = double.parse(value);
                        final balance = _getBalanceForCurrency(_fromCurrency, state);
                        if (amount > balance) return 'Insufficient balance';
                        
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Estimated Receive Amount
                    if (_amountController.text.isNotEmpty && double.tryParse(_amountController.text) != null)
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: buttonGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: buttonGreen.withOpacity(0.3), width: 1.w),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'You will receive:',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 13.sp,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : Colors.black54,
                              ),
                            ),
                            Text(
                              '${_calculateEstimatedAmount().toStringAsFixed(2)} $_toCurrency',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: buttonGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 32.h),

                    // Swap Button
                    ElevatedButton(
                      onPressed: isLoading ? null : _handleSwap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonGreen,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        disabledBackgroundColor: buttonGreen.withOpacity(0.5),
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 24.r,
                              width: 24.r,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.w,
                              ),
                            )
                          : Text(
                              'Swap Now',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : Colors.black54,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Theme.of(context).brightness == Brightness.dark ? cardBackground : lightCardBackground,
              icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
              items: _availableCurrencies.map((String currency) {
                return DropdownMenuItem<String>(
                  value: currency,
                  child: Text(
                    currency,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
