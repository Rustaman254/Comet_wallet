import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';
import '../constants/colors.dart';
import '../services/toast_service.dart';
import '../utils/input_decoration.dart';

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
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _handleSwap() {
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
        backgroundColor: darkBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Swap Currencies',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
                        color: buttonGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: buttonGreen, width: 1.w),
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
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Instantly swap between your currency wallets with real-time rates.',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 12.sp,
                              color: Colors.white.withOpacity(0.7),
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
                      onChanged: (val) => setState(() => _fromCurrency = val!),
                    ),
                    SizedBox(height: 24.h),

                    // Swap Icon
                    Center(
                      child: IconButton(
                        icon: Icon(Icons.swap_vert, color: buttonGreen, size: 32.r),
                        onPressed: () {
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
                      onChanged: (val) => setState(() => _toCurrency = val!),
                    ),
                    SizedBox(height: 32.h),

                    // Amount Field
                    Text(
                      'Amount to Swap',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: Colors.white,
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
                              color: Colors.white,
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
                        return null;
                      },
                    ),
                    SizedBox(height: 48.h),

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
            color: Colors.white.withOpacity(0.7),
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: cardBackground,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              items: _availableCurrencies.map((String currency) {
                return DropdownMenuItem<String>(
                  value: currency,
                  child: Text(
                    currency,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: Colors.white,
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
