import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
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
  String _selectedMobileProvider = 'M-Pesa';
  bool _isLoading = false;
  String? _userPhoneNumber;
  String? _cardanoAddress;

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
    _loadCardanoAddress();
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
          _phoneController.text = phone;
        });
      }
    } catch (e) {
      AppLogger.error(LogTags.storage, 'Failed to load user phone', data: {'error': e.toString()});
    }
  }

  Future<void> _loadCardanoAddress() async {
    try {
      final address = await TokenService.getCardanoAddress();
      if (mounted) {
        setState(() {
          _cardanoAddress = address;
        });
      }
    } catch (e) {
      AppLogger.error(LogTags.storage, 'Failed to load Cardano address', data: {'error': e.toString()});
    }
  }

  Future<void> _handleTopup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final amount = double.parse(_amountController.text);
        final rawNumber = _phoneController.text.trim();
        final phoneNumber = '$_selectedCountryCode$rawNumber'.replaceAll(RegExp(r'\s+'), '');

        if (mounted) {
          ToastService().showInfo(context, 'Sending STK push to your phone...');
        }

        final response = await WalletService.topupWallet(
          phoneNumber: phoneNumber,
          amount: amount,
          currency: _selectedCurrency,
        );

        if (mounted) {
          context.read<WalletBloc>().add(TopUpWallet(
            amount: amount,
            currency: _selectedCurrency,
          ));

          ToastService().showSuccess(context, 'Payment Processed successfully!');
          await Future.delayed(const Duration(seconds: 2));
          
          if (mounted) {
            _showSuccessSheet(response);
            AppLogger.success(LogTags.payment, 'Wallet top-up completed', data: {
              'amount': amount,
              'currency': _selectedCurrency,
              'response': response,
            });
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
              style: const TextStyle(fontFamily: 'Satoshi',
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
                  Navigator.pop(context);
                  if (response['status'] == 'success' || response['status'] == 'completed') {
                    Navigator.pop(context, true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Home', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.bold)),
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
          Text(label, style: const TextStyle(fontFamily: 'Satoshi', color: Colors.white70, fontSize: 14)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Satoshi', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Top-up Funds',
            style: TextStyle(fontFamily: 'Satoshi',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: buttonGreen,
            labelColor: buttonGreen,
            unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
            labelStyle: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Mobile Money'),
              Tab(text: 'USDA (Cardano)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMobileTopupTab(),
            _buildUSDATopupTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTopupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMobileProvider,
                isExpanded: true,
                dropdownColor: Theme.of(context).cardColor,
                items: ['M-Pesa', 'T-Kash'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedMobileProvider = newValue!;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_selectedMobileProvider == 'M-Pesa')
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoCard('Add Funds to Your Wallet', 'Enter the amount you want to add. Funds will be transferred via M-Pesa/Mobile Money.'),
                  const SizedBox(height: 32),
                  Text('Phone Number', style: TextStyle(fontFamily: 'Satoshi', color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 100,
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3) ?? Colors.grey, width: 1))),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCountryCode,
                            dropdownColor: Theme.of(context).brightness == Brightness.dark ? cardBackground : lightCardBackground,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                            isExpanded: true,
                            onChanged: (v) => setState(() => _selectedCountryCode = v!),
                            items: _countryCodes.map((c) => DropdownMenuItem(value: c['code'], child: Text(c['code']!))).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w500),
                          maxLength: 9,
                          decoration: buildUnderlineInputDecoration(context: context, label: '', hintText: '7XX XXX XXX').copyWith(counterText: ''),
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : (!v.startsWith('7') || v.length != 9) ? 'Invalid' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Amount', style: TextStyle(fontFamily: 'Satoshi', color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: buildUnderlineInputDecoration(context: context, label: '', hintText: 'Enter amount', prefixIcon: const Icon(Icons.money_outlined)),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : double.tryParse(v) == null || double.parse(v) <= 0 ? 'Invalid amount' : null,
                  ),
                  const SizedBox(height: 24),
                  _buildCurrencySelection(),
                  const SizedBox(height: 32),
                  _buildSummaryRow(),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleTopup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Proceed to Payment', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard('Deposit via Telkom', 'Follow these steps to deposit funds via T-Kash.'),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStepItem('1', 'Dial *334#'),
                      _buildStepItem('2', 'Select Option 6 Lipa na M-PESA'),
                      _buildStepItem('3', 'Select Option 4 T-Kash'),
                      _buildStepItem('4', 'Select Option 1 Pay Bill'),
                      _buildStepItem('5', 'Enter 888999'),
                      _buildStepItem('6', 'Enter Account Number: ${_userPhoneNumber ?? 'Your Phone Number'}'),
                      _buildStepItem('7', 'Enter Amount'),
                      _buildStepItem('8', 'Press 1 to confirm'),
                      _buildStepItem('9', 'Enter M-Pesa Pin'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Note: The account should be the user\'s mobile phone number.',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: buttonGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: buttonGreen,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUSDATopupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildInfoCard('Top-up with USDA', 'Send USDA to your Cardano wallet address. The funds will reflect once the transaction is confirmed on the blockchain.'),
          const SizedBox(height: 40),
          if (_cardanoAddress != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: _cardanoAddress!,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Your Cardano Address',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
              ),
              child: SelectableText(
                _cardanoAddress!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _cardanoAddress!));
                  ToastService().showSuccess(context, 'Address copied to clipboard');
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy Address', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: buttonGreen,
                  side: const BorderSide(color: buttonGreen),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else
            const Center(child: CircularProgressIndicator(color: buttonGreen)),
          const SizedBox(height: 40),
          Text(
            'Only send USDA to this address. Sending other assets may result in permanent loss.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, color: Colors.orange.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: buttonGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: buttonGreen, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildCurrencySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Currency', style: TextStyle(fontFamily: 'Satoshi', color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3) ?? Colors.grey, width: 1))),
          child: DropdownButton<String>(
            isExpanded: true,
            underline: Container(),
            value: _selectedCurrency,
            onChanged: (v) => setState(() => _selectedCurrency = v!),
            items: ['KES', 'USD', 'EUR'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.bold)),
          Text(
            _amountController.text.isEmpty ? '$_selectedCurrency 0.00' : '$_selectedCurrency ${_amountController.text}',
            style: const TextStyle(fontFamily: 'Satoshi', fontSize: 16, fontWeight: FontWeight.bold, color: buttonGreen),
          ),
        ],
      ),
    );
  }
}
