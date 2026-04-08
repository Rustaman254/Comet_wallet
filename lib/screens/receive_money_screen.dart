import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

import '../constants/colors.dart';
import '../services/wallet_service.dart';
import '../services/toast_service.dart';
import '../services/token_service.dart';
import '../utils/input_decoration.dart';
import 'payment_qr_display_screen.dart';
import 'sign_in_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_state.dart';
import '../widgets/currency_selection_sheet.dart';
import '../widgets/usda_logo.dart';

class ReceiveMoneyScreen extends StatefulWidget {
  const ReceiveMoneyScreen({super.key});

  @override
  State<ReceiveMoneyScreen> createState() => _ReceiveMoneyScreenState();
}

class _ReceiveMoneyScreenState extends State<ReceiveMoneyScreen> {
  String walletAddress = 'Loading...';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCurrency = 'KES';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    final phone = await TokenService.getPhoneNumber();
    if (mounted) {
      setState(() {
        walletAddress = phone ?? '+2547XXXXXXXX';
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _generateQR() async {
    if (_amountController.text.isEmpty) {
      ToastService().showError(context, 'Please enter an amount');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final response = await WalletService.createPaymentLink(
        amount: amount,
        currency: _selectedCurrency,
        description: _descriptionController.text.isEmpty
            ? 'Payment to $walletAddress'
            : _descriptionController.text,
      );

      final paymentUrl = response['payment_url'];

      if (mounted && paymentUrl != null) {
        ToastService().showSuccess(context, 'Payment link generated!');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaymentQRDisplayScreen(
              paymentUrl: paymentUrl,
              amount: amount,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        if (errorMsg.contains('401') || errorMsg.contains('expired')) {
          ToastService().showError(
              context, 'Session expired. Please login again.');
          await TokenService.logout();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SignInScreen()),
              (route) => false,
            );
          }
        } else {
          ToastService().showError(context, 'Failed to generate QR: $e');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCurrencyPicker() {
    final state = context.read<WalletBloc>().state;
    List<Map<String, String>> supportedCurrencies = [];

    if (state is WalletLoaded) {
      supportedCurrencies = state.supportedCurrencies ?? [];
    } else if (state is WalletBalanceUpdated) {
      supportedCurrencies = state.supportedCurrencies ?? [];
    }

    if (supportedCurrencies.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CurrencySelectionSheet(
        currencies: supportedCurrencies,
        selectedCurrency: _selectedCurrency,
        onCurrencySelected: (currency) {
          setState(() {
            _selectedCurrency = currency;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_outlined,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        size: 20.r,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Receive Money',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 30),

              // Wallet Number Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Mobile Wallet Number',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: walletAddress));
                            ToastService()
                                .showSuccess(context, 'Copied to clipboard!');
                          },
                          child: Text(
                            walletAddress,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[600]
                                  : Colors.black,
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: walletAddress));
                          ToastService()
                              .showSuccess(context, 'Copied to clipboard!');
                        },
                        icon: Icon(
                          Icons.copy_rounded,
                          color: primaryBrandColor,
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Inputs Group
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.black.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showCurrencyPicker,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: primaryBrandColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                                color: primaryBrandColor.withValues(alpha: 0.3),
                                width: 1.w),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _selectedCurrency == 'USDA'
                                  ? const USDALogo(size: 16)
                                  : Text(
                                      USDALogo.getFlag(_selectedCurrency),
                                      style: TextStyle(fontSize: 14.sp),
                                    ),
                              SizedBox(width: 4.w),
                              Text(
                                _selectedCurrency,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: primaryBrandColor,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_down,
                                  size: 14, color: primaryBrandColor),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        fontSize: 16),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: buildUnderlineInputDecoration(
                      context: context,
                      label: '',
                      hintText: 'Enter amount',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        fontSize: 16),
                    decoration: buildUnderlineInputDecoration(
                      context: context,
                      label: '',
                      hintText: 'What is this for?',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generateQR,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBrandColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24.r,
                          width: 24.r,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.w))
                      : Text(
                          'Generate QR Code',
                          style: TextStyle(fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
