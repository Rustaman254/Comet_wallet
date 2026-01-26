import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../services/wallet_service.dart';
import '../services/logger_service.dart';
import '../services/toast_service.dart';
import '../services/token_service.dart';
import '../utils/input_decoration.dart';

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
  String _selectedCountryCode = '+254';
  String _selectedPaymentMethod = 'mpesa'; // 'mpesa' or 'tkash'
  bool _isLoading = false;
  String? _userPhoneNumber;

  final List<Map<String, String>> _countryCodes = [
    {'code': '+254', 'country': 'Kenya'},
    {'code': '+255', 'country': 'Tanzania'},
    {'code': '+256', 'country': 'Uganda'},
    {'code': '+250', 'country': 'Rwanda'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
    _amountController.addListener(() => setState(() {}));
  }

  Future<void> _loadUserPhone() async {
    try {
      final phone = await TokenService.getPhoneNumber();
      if (phone != null && mounted) {
        setState(() {
          _userPhoneNumber = phone;
          for (var country in _countryCodes) {
            final codeWithPlus = country['code']!;
            final codeWithoutPlus = codeWithPlus.substring(1);
            if (phone.startsWith(codeWithPlus)) {
              _selectedCountryCode = codeWithPlus;
              _phoneController.text = phone.substring(codeWithPlus.length).trim();
              return;
            } else if (phone.startsWith(codeWithoutPlus)) {
              _selectedCountryCode = codeWithPlus;
              _phoneController.text = phone.substring(codeWithoutPlus.length).trim();
              return;
            }
          }
          // Fallback if no matching code found: just strip + and leading digits if needed, 
          // but for simplicity we'll just put the whole thing in if it's long
          _phoneController.text = phone;
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
      // If T-Kash is selected, show instructions dialog instead of processing payment
      if (_selectedPaymentMethod == 'tkash') {
        _showTKashInstructionsDialog();
        return;
      }

      setState(() => _isLoading = true);

      try {
        final amount = double.parse(_amountController.text);
        final rawNumber = _phoneController.text.trim();
        // Format as MSISDN without spaces for API, but use the selection
        final phoneNumber = '$_selectedCountryCode$rawNumber'.replaceAll(RegExp(r'\s+'), '');

        // Show initial feedback
        if (mounted) {
          ToastService().showInfo(context, 'Sending STK push to your phone...');
        }

        final response = await WalletService.topupWallet(
          phoneNumber: phoneNumber,
          amount: amount,
          currency: _selectedCurrency,
        );

        if (mounted) {
          // Show intermediate success
          ToastService().showSuccess(context, 'Payment Processed successfully!');
          
          // Small delay to allow STK push to appear on phone first
          await Future.delayed(const Duration(seconds: 2));
          
          if (mounted) {
            _showSuccessSheet(response);
            
            AppLogger.success(
              LogTags.payment,
              'Wallet top-up completed',
              data: {
                'amount': amount,
                'currency': _selectedCurrency,
                'response': response,
              },
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ToastService().showError(context, 'Top-up failed: ${e.toString()}');
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

  void _showTKashInstructionsDialog() {
    final amount = _amountController.text;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Color(0xFF0066CC), size: 24),
            const SizedBox(width: 8),
            Text(
              'T-Kash Payment',
              style: TextStyle(fontFamily: 'Satoshi',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF0066CC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFF0066CC), width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Amount:',
                          style: TextStyle(fontFamily: 'Satoshi',
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '$_selectedCurrency $amount',
                          style: TextStyle(fontFamily: 'Satoshi',
                            color: Color(0xFF0066CC),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Account:',
                          style: TextStyle(fontFamily: 'Satoshi',
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _userPhoneNumber ?? 'Your phone',
                          style: TextStyle(fontFamily: 'Satoshi',
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Follow these steps on your phone:',
                style: TextStyle(fontFamily: 'Satoshi',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _buildInstructionStep('1', 'Dial *334#'),
              _buildInstructionStep('2', 'Select Option 6: Lipa na M-PESA'),
              _buildInstructionStep('3', 'Select Option 4: T-Kash'),
              _buildInstructionStep('4', 'Select Option 1: Pay Bill'),
              _buildInstructionStep('5', 'Enter 888999'),
              _buildInstructionStep('6', 'Account: ${_userPhoneNumber ?? "your phone number"}'),
              _buildInstructionStep('7', 'Amount: $amount'),
              _buildInstructionStep('8', 'Press 1 to confirm'),
              _buildInstructionStep('9', 'Enter M-Pesa Pin'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your wallet will be credited automatically once payment is confirmed.',
                        style: TextStyle(fontFamily: 'Satoshi',
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(fontFamily: 'Satoshi',
                color: Color(0xFF0066CC),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSheet(Map<String, dynamic> response) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: buttonGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_outline, color: buttonGreen, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              response['message'] ?? 'Top-up successful!',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Satoshi',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Transaction ID', response['transaction_id'] ?? 'N/A'),
            _buildDetailRow('Amount', '${response['currency'] ?? _selectedCurrency} ${response['amount']}'),
            _buildDetailRow('Phone', response['phone_number'] ?? _phoneController.text),
            _buildDetailRow('Status', response['status'] ?? 'Success'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  // If we want to stay on page or go back based on success
                  if (response['status'] == 'success' || response['status'] == 'completed') {
                    Navigator.pop(context, true); // Go back home
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back to Home',
                  style: TextStyle(fontFamily: 'Satoshi',fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
          Text(
            label,
            style: TextStyle(fontFamily: 'Satoshi',color: Colors.white70, fontSize: 14),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontFamily: 'Satoshi',
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Color(0xFF0066CC),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(fontFamily: 'Satoshi',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(fontFamily: 'Satoshi',
                fontSize: 13,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
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
          style: TextStyle(fontFamily: 'Satoshi',
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
                      style: TextStyle(fontFamily: 'Satoshi',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the amount you want to add to your wallet. Funds will be transferred immediately upon successful payment.',
                      style: TextStyle(fontFamily: 'Satoshi',
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Payment Method Selection
              Text(
                'Payment Method',
                style: TextStyle(fontFamily: 'Satoshi',
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
                  value: _selectedPaymentMethod,
                  dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                  style: TextStyle(fontFamily: 'Satoshi',
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 16,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'mpesa',
                      child: Row(
                        children: [
                          Icon(Icons.phone_android, color: buttonGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'M-Pesa STK Push',
                            style: TextStyle(fontFamily: 'Satoshi',
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'tkash',
                      child: Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Color(0xFF0066CC), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'T-Kash (Telkom)',
                            style: TextStyle(fontFamily: 'Satoshi',
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPaymentMethod = value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),

              // T-Kash Instructions (shown only when T-Kash is selected)
              if (_selectedPaymentMethod == 'tkash') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF0066CC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF0066CC), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF0066CC), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Deposit via Telkom',
                            style: TextStyle(fontFamily: 'Satoshi',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Follow these steps to deposit:',
                        style: TextStyle(fontFamily: 'Satoshi',
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInstructionStep('1', 'Dial *334#'),
                      _buildInstructionStep('2', 'Select Option 6: Lipa na M-PESA'),
                      _buildInstructionStep('3', 'Select Option 4: T-Kash'),
                      _buildInstructionStep('4', 'Select Option 1: Pay Bill'),
                      _buildInstructionStep('5', 'Enter 888999'),
                      _buildInstructionStep('6', 'Account: enter ${_userPhoneNumber ?? "your phone number"}'),
                      _buildInstructionStep('7', 'Enter Amount'),
                      _buildInstructionStep('8', 'Press 1 to confirm'),
                      _buildInstructionStep('9', 'Enter M-Pesa Pin'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF0066CC).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.account_circle, color: Color(0xFF0066CC), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your phone number: ${_userPhoneNumber ?? "Loading..."}',
                                style: TextStyle(fontFamily: 'Satoshi',
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Phone Number Field
              Text(
                'Phone Number',
                style: TextStyle(fontFamily: 'Satoshi',
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Country Code Dropdown
                  Container(
                    width: 100,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3) ?? Colors.grey,
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
                        style: TextStyle(fontFamily: 'Satoshi',
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
                  // Number Field
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(fontFamily: 'Satoshi',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLength: 9,
                      decoration: buildUnderlineInputDecoration(
                        context: context,
                        label: '',
                        hintText: '7XX XXX XXX',
                      ).copyWith(counterText: ''),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (value.startsWith('0')) {
                          return 'Should not start with 0';
                        }
                        if (!value.startsWith('7')) {
                          return 'Must start with 7';
                        }
                        if (value.length != 9) {
                          return 'Must be 9 digits';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Amount Field
              Text(
                'Amount',
                style: TextStyle(fontFamily: 'Satoshi',
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(fontFamily: 'Satoshi',
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
                style: TextStyle(fontFamily: 'Satoshi',
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
                  style: TextStyle(fontFamily: 'Satoshi',
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 16,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'KES',
                      child: Text(
                        'KES (Kenyan Shilling)',
                        style: TextStyle(fontFamily: 'Satoshi',
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'USD',
                      child: Text(
                        'USD (US Dollar)',
                        style: TextStyle(fontFamily: 'Satoshi',
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'EUR',
                      child: Text(
                        'EUR (Euro)',
                        style: TextStyle(fontFamily: 'Satoshi',
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
                          style: TextStyle(fontFamily: 'Satoshi',
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          _amountController.text.isEmpty
                              ? '$_selectedCurrency 0.00'
                              : '$_selectedCurrency ${_amountController.text}',
                          style: TextStyle(fontFamily: 'Satoshi',
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
                          style: TextStyle(fontFamily: 'Satoshi',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _amountController.text.isEmpty
                              ? '$_selectedCurrency 0.00'
                              : '$_selectedCurrency ${_amountController.text}',
                          style: TextStyle(fontFamily: 'Satoshi',
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
                        _selectedPaymentMethod == 'tkash' 
                            ? 'View Instructions' 
                            : 'Proceed to Payment',
                        style: TextStyle(fontFamily: 'Satoshi',
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
                style: TextStyle(fontFamily: 'Satoshi',
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
