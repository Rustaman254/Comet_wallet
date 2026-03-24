import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';
import '../constants/colors.dart';
import '../constants/api_constants.dart';
import '../services/authenticated_http_client.dart';
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

  bool _isFetchingRate = false;
  // Always stores the latest rate from the API (no caching)
  double _currentRate = 0.0;

  // Cache last known balances so we don't lose them on WalletError state
  List<Map<String, dynamic>> _lastKnownBalances = [];

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
    _fetchExchangeRate();
  }

  /// Fetches the exchange rate for a specific currency pair from the API.
  /// Endpoint: /forex/rates/{FROM}/{TO}
  /// Response: {"from_currency": "KES", "rate": 0.0077, "status": "success", "to_currency": "USD"}
  Future<void> _fetchRateForPair(String from, String to) async {
    if (from == to) {
      if (mounted) {
        setState(() {
          _currentRate = 1.0;
          _isFetchingRate = false;
        });
      }
      return;
    }

    setState(() => _isFetchingRate = true);
    try {
      final url = '${ApiConstants.forexRatesEndpoint}/$from/$to';
      final response = await AuthenticatedHttpClient.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data['status'] == 'success') {
          final rate = double.tryParse(data['rate']?.toString() ?? '');
          if (rate != null && rate > 0) {
            _currentRate = rate;
          }
        }
      }
    } catch (_) {
      // Keep existing rate on error
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingRate = false;
        });
      }
    }
  }

  /// Returns how many [to] currency units you get for 1 [from] unit.
  /// Always returns the latest rate fetched from the API.
  double _lookupRate(String from, String to) {
    if (from == to) return 1.0;
    return _currentRate;
  }

  void _fetchExchangeRate() {
    if (_fromCurrency == _toCurrency) {
      setState(() {
        _currentRate = 1.0;
      });
      return;
    }

    // Always fetch fresh rate from server
    _fetchRateForPair(_fromCurrency, _toCurrency);
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

    // Cache balances whenever we have valid data
    if (balances.isNotEmpty) {
      _lastKnownBalances = balances;
    }

    // Use current balances if available, otherwise fall back to cached values
    final effectiveBalances = balances.isNotEmpty ? balances : _lastKnownBalances;

    if (effectiveBalances.isNotEmpty) {
      final balance = effectiveBalances.firstWhere(
        (b) => b['currency'] == currency,
        orElse: () => {'amount': '0.0'},
      );
      return double.tryParse(balance['amount']?.toString() ?? '0.0') ?? 0.0;
    }
    return 0.0;
  }



  double _calculateEstimatedAmount() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return 0.0;
    final rate = _lookupRate(_fromCurrency, _toCurrency);
    return amount * rate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Rounds a value to the nearest 100 and formats with 2 decimal places.
  String _formatBalance(double value) {
    return value.toStringAsFixed(2);
  }

  void _showSwapSuccessDialog(BuildContext context, WalletSwapSuccess state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: primaryBrandColor, size: 28.r),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Swap Successful',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: getTextColor(context),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.message,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  color: getSecondaryTextColor(context),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Updated Balances',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: getTextColor(context),
                ),
              ),
              SizedBox(height: 8.h),
              ...state.balances.entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildCurrencyIcon(entry.key, size: 20.r),
                          SizedBox(width: 8.w),
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: getTextColor(context),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatBalance(entry.value),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: getTextColor(context),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (state.txId != null && state.explorerLink != null) ...[
                SizedBox(height: 16.h),
                Text(
                  'Transaction details',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: getTextColor(context),
                  ),
                ),
                SizedBox(height: 8.h),
                InkWell(
                  onTap: () async {
                    final uri = Uri.parse(state.explorerLink!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.open_in_new, size: 16.r, color: primaryBrandColor),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          state.txId!,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            color: primaryBrandColor,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBrandColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Done',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
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
            _fetchExchangeRate();
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
          _showSwapSuccessDialog(context, state);
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
              fontFamily: 'Outfit',
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
                          // Fetch the exchange rate for the swapped currency pair
                          _fetchExchangeRate();
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: primaryBrandColor,
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
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              color: getSecondaryTextColor(context),
                            ),
                          ),
                          _isFetchingRate
                              ? SizedBox(
                                  height: 14.r,
                                  width: 14.r,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: getSecondaryTextColor(context),
                                  ),
                                )
                              : Text(
                                  '1 $_fromCurrency = ${_lookupRate(_fromCurrency, _toCurrency).toStringAsFixed(4)} $_toCurrency',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
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
                        backgroundColor: primaryBrandColor,
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
                                fontFamily: 'Outfit',
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
                  fontFamily: 'Outfit',
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
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      color: primaryBrandColor,
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
                          fontFamily: 'Outfit',
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
                            final rate = _lookupRate(_fromCurrency, 'USDA');
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
                          fontFamily: 'Outfit',
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
                          fontFamily: 'Outfit',
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
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: primaryBrandColor,
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
