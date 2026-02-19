import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';
import '../constants/colors.dart';
import '../services/toast_service.dart';
import '../services/session_service.dart';
import '../widgets/usda_logo.dart';
import '../widgets/currency_selection_sheet.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _fromCurrency = 'KES';
  String _toCurrency = 'USDA';
  
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

  double _getBalanceForCurrency(String currency, WalletState state) {
    List<Map<String, dynamic>> balances = [];
    if (state is WalletLoaded) {
      balances = state.balances;
    } else if (state is WalletBalanceUpdated) {
      balances = state.balances;
    } else if (state is WalletSwapLoading) {
      balances = state.balances;
    }

    if (balances.isNotEmpty) {
      final balance = balances.firstWhere(
        (b) => b['currency'] == currency,
        orElse: () => {'amount': '0.0'},
      );
      return double.tryParse(balance['amount']?.toString() ?? '0.0') ?? 0.0;
    }
    return 0.0;
  }

  double _getExchangeRate(String from, String to) {
    if (from == to) return 1.0;
    
    final Map<String, double> toUSD = {
      'KES': 0.0077,
      'USD': 1.0,
      'TZS': 0.00039,
      'UGX': 0.00027,
      'EUR': 1.09,
      'GBP': 1.27,
      'ZAR': 0.055,
      'RWF': 0.00078,
      'USDA': 1.0,
    };
    
    final fromRate = toUSD[from] ?? 1.0;
    final toRate = toUSD[to] ?? 1.0;
    
    return fromRate / toRate;
  }

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

  void _showCurrencyPicker(bool isFrom) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CurrencySelectionSheet(
          currencies: _availableCurrencies,
          selectedCurrency: isFrom ? _fromCurrency : _toCurrency,
          onCurrencySelected: (currency) {
             setState(() {
              if (isFrom) {
                _fromCurrency = currency;
              } else {
                _toCurrency = currency;
              }
            });
          },
        );
      },
    );
  }

  Widget _buildCurrencyIcon(String currency, {double size = 24}) {
    if (currency == 'USDA') {
      return USDALogo(size: size);
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Text(
        USDALogo.getFlag(currency),
        style: TextStyle(
          fontSize: size * 0.8,
        ),
      ),
    );
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
            icon: Icon(Icons.arrow_back, color: getTextColor(context)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Swap',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: getTextColor(context),
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            final isLoading = state is WalletSwapLoading;
            final fromBalance = _getBalanceForCurrency(_fromCurrency, state);

            return SingleChildScrollView(
              padding: EdgeInsets.all(24.r),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // TOP CARD (FROM)
                    _buildSwapCard(
                      isFrom: true,
                      currency: _fromCurrency,
                      balance: fromBalance,
                      controller: _amountController,
                      onCurrencyTap: () => _showCurrencyPicker(true),
                      onMaxTap: () {
                        _amountController.text = fromBalance.toString();
                        setState(() {});
                      },
                    ),

                    SizedBox(height: 12.h),

                    // SWAP BUTTON IN THE MIDDLE
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            final temp = _fromCurrency;
                            _fromCurrency = _toCurrency;
                            _toCurrency = temp;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: buttonGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 4.r,
                            ),
                          ),
                          child: Icon(Icons.swap_vert, color: Colors.white, size: 24.r),
                        ),
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // BOTTOM CARD (TO)
                    _buildSwapCard(
                      isFrom: false,
                      currency: _toCurrency,
                      balance: 0, // Not needed for "To" card usually
                      controller: TextEditingController(
                        text: _calculateEstimatedAmount().toStringAsFixed(2),
                      ),
                      onCurrencyTap: () => _showCurrencyPicker(false),
                    ),

                    SizedBox(height: 32.h),

                    // RATE INFO
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: getBorderColor(context)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Exchange Rate',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 14.sp,
                              color: getSecondaryTextColor(context),
                            ),
                          ),
                          Text(
                            '1 $_fromCurrency = ${_getExchangeRate(_fromCurrency, _toCurrency).toStringAsFixed(4)} $_toCurrency',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: getTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 48.h),

                    // SWAP BUTTON
                    ElevatedButton(
                      onPressed: isLoading ? null : _handleSwap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonGreen,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 18.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 24.r,
                              width: 24.r,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
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

  Widget _buildSwapCard({
    required bool isFrom,
    required String currency,
    required double balance,
    required TextEditingController controller,
    required VoidCallback onCurrencyTap,
    VoidCallback? onMaxTap,
  }) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isFrom ? 'You pay' : 'You receive',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 14.sp,
                  color: getSecondaryTextColor(context),
                ),
              ),
              if (isFrom)
                GestureDetector(
                  onTap: onMaxTap,
                  child: Text(
                    'Balance: ${balance.toStringAsFixed(2)} $currency',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 12.sp,
                      color: buttonGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: isFrom
                    ? TextFormField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: getTextColor(context),
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(color: getTertiaryTextColor(context)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) return 'Invalid';
                          if (double.parse(value) <= 0) return 'Must be > 0';
                          if (double.parse(value) > balance) return 'Insufficient balance';
                          
                          // Minimum swap amount checks
                          if (_toCurrency == 'USDA') {
                            final rate = _getExchangeRate(_fromCurrency, 'USDA');
                            final estimatedUSDA = double.parse(value) * rate;
                            if (estimatedUSDA < 1.0) {
                              return 'Min swap: 1 $_toCurrency (Cardano)';
                            }
                          }
                          if (_fromCurrency == 'USDA') {
                            if (double.parse(value) < 1.0) {
                              return 'Min swap: 1 $_fromCurrency (Cardano)';
                            }
                          }
                          
                          return null;
                        },
                      )
                    : Text(
                        controller.text,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: getTextColor(context),
                        ),
                      ),
              ),
              GestureDetector(
                onTap: onCurrencyTap,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCurrencyIcon(currency, size: 24.r),
                      SizedBox(width: 8.w),
                      Text(
                        currency == 'USDA' ? 'USDA (Cardano)' : currency,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: getTextColor(context),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(Icons.keyboard_arrow_down, color: getSecondaryTextColor(context), size: 18.r),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isFrom && onMaxTap != null) ...[
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onMaxTap,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'MAX',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: buttonGreen,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
