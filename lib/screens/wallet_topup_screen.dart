import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../services/wallet_service.dart';
import '../../services/logger_service.dart';
import '../../services/toast_service.dart';
import '../../services/token_service.dart';
import '../../utils/input_decoration.dart';

class WalletTopupScreen extends StatefulWidget {
  const WalletTopupScreen({super.key});

  @override
  State<WalletTopupScreen> createState() => _WalletTopupScreenState();
}

class _WalletTopupScreenState extends State<WalletTopupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedCurrency = 'KES';
  bool _isLoading = false;
  String? _userPhoneNumber;

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    try {
      final phone = await TokenService.getPhoneNumber();
      if (mounted) {
        setState(() {
          _userPhoneNumber = phone;
          if (phone != null) {
            _phoneController.text = phone;
          }
        });
      }
    } catch (e) {
      AppLogger.error(
        LogTags.storage,
        'Failed to load user phone',
        data: {'error': e.toString()},
      );
    }
  }

  Future<void> _handleTopup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final amount = double.parse(_amountController.text);
        final phoneNumber = _phoneController.text.trim();

        AppLogger.info(
          LogTags.payment,
          'Initiating wallet top-up',
          data: {
            'phone_number': phoneNumber,
            'amount': amount,
            'currency': _selectedCurrency,
          },
        );

        final response = await WalletService.topupWallet(
          phoneNumber: phoneNumber,
          amount: amount,
          currency: _selectedCurrency,
        );

        if (mounted) {
          ToastService().showSuccess(
            context,
            'Top-up of $_selectedCurrency $amount successful!',
          );

          AppLogger.success(
            LogTags.payment,
            'Wallet top-up completed',
            data: {
              'amount': amount,
              'currency': _selectedCurrency,
              'response': response,
            },
          );

          // Clear form and go back
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ToastService().showError(context, 'Top-up failed: ${e.toString()}');

          AppLogger.error(
            LogTags.payment,
            'Wallet top-up failed',
            data: {'error': e.toString()},
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      ToastService().showError(context, 'Please fill in all fields correctly');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Wallet Top-Up',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: buttonGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: buttonGreen, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Funds to Your Wallet',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the amount you want to add to your wallet. Funds will be transferred immediately upon successful payment.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Phone Number Field
              Text(
                'Phone Number',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                readOnly: _userPhoneNumber != null,
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 16,
                ),
                decoration: buildUnderlineInputDecoration(
                  context: context,
                  label: '',
                  hintText: 'Enter phone number',
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Phone number is required';
                  }
                  if (value!.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Amount Field
              Text(
                'Amount',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 16,
                ),
                decoration: buildUnderlineInputDecoration(
                  context: context,
                  label: '',
                  hintText: 'Enter amount',
                  prefixIcon: Icon(
                    Icons.money_outlined,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Amount is required';
                  }
                  try {
                    final amount = double.parse(value!);
                    if (amount <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    if (amount < 1) {
                      return 'Minimum top-up amount is 1 $_selectedCurrency';
                    }
                  } catch (e) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Currency Selection
              Text(
                'Currency',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3) ?? Colors.grey,
                      width: 1,
                    ),
                  ),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  underline: Container(),
                  value: _selectedCurrency,
                  dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 16,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'KES',
                      child: Text(
                        'KES (Kenyan Shilling)',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'USD',
                      child: Text(
                        'USD (US Dollar)',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'EUR',
                      child: Text(
                        'EUR (Euro)',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCurrency = value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Amount',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          _amountController.text.isEmpty
                              ? '$_selectedCurrency 0.00'
                              : '$_selectedCurrency ${_amountController.text}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _amountController.text.isEmpty
                              ? '$_selectedCurrency 0.00'
                              : '$_selectedCurrency ${_amountController.text}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: buttonGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Top-up Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleTopup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: buttonGreen.withOpacity(0.5),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(
                            Colors.white.withOpacity(0.7),
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Proceed to Payment',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Disclaimer
              Text(
                'Please ensure your phone number is correct. You will receive an SMS confirmation after successful payment.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
