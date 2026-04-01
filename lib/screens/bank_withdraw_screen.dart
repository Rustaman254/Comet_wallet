import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';
import '../constants/api_constants.dart';
import '../constants/colors.dart';
import '../services/authenticated_http_client.dart';
import '../services/toast_service.dart';
import '../utils/input_decoration.dart';

// ─────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────
class Bank {
  final String bankCode;
  final String bankName;

  const Bank({required this.bankCode, required this.bankName});

  factory Bank.fromJson(Map<String, dynamic> json) => Bank(
        bankCode: json['bank_code'] as String,
        bankName: json['bank_name'] as String,
      );
}

// ─────────────────────────────────────────────
// Fallback list (used when API fails)
// ─────────────────────────────────────────────
const List<Map<String, String>> _kFallbackBanks = [
  {'bank_code': '0003', 'bank_name': 'Absa Bank Kenya PLC'},
  {'bank_code': '0019', 'bank_name': 'Bank of Africa Kenya Limited'},
  {'bank_code': '0006', 'bank_name': 'Bank of Baroda (Kenya Limited)'},
  {'bank_code': '0005', 'bank_name': 'Bank of India'},
  {'bank_code': '0009', 'bank_name': 'Central Bank of Kenya'},
  {'bank_code': '0030', 'bank_name': 'Chase Bank Limited'},
  {'bank_code': '0016', 'bank_name': 'Citibank N A'},
  {'bank_code': '0036', 'bank_name': 'Commercial Bank of Africa Limited'},
  {'bank_code': '0023', 'bank_name': 'Consolidated Bank of Kenya Limited'},
  {'bank_code': '0011', 'bank_name': 'Co-operative Bank of Kenya Limited'},
  {'bank_code': '0025', 'bank_name': 'Credit Bank Limited'},
  {'bank_code': '0077', 'bank_name': 'Credit Bank Limited'},
  {'bank_code': '0079', 'bank_name': 'Development Bank of Kenya'},
  {'bank_code': '0050', 'bank_name': 'Diamond Trust Bank Kenya Limited'},
  {'bank_code': '0066', 'bank_name': 'DTB Bank Limited'},
  {'bank_code': '0045', 'bank_name': 'EcoBank Kenya Limited'},
  {'bank_code': '0062', 'bank_name': 'Equity Bank (Kenya) Limited'},
  {'bank_code': '0052', 'bank_name': 'Family Bank Limited'},
  {'bank_code': '0063', 'bank_name': 'First Community Bank Limited'},
  {'bank_code': '0075', 'bank_name': 'Guaranty Trust Bank (Kenya) Limited'},
  {'bank_code': '0064', 'bank_name': 'Gulf African Bank Limited'},
  {'bank_code': '0017', 'bank_name': 'Habib Bank A G Zurich'},
  {'bank_code': '0073', 'bank_name': 'HF Group PLC (HFC)'},
  {'bank_code': '0035', 'bank_name': 'I&M Bank PLC'},
  {'bank_code': '0001', 'bank_name': 'Kenya Commercial Bank Limited'},
  {'bank_code': '0068', 'bank_name': 'Kenya Women Finance Trust DTM'},
  {'bank_code': '0014', 'bank_name': 'M-Oriental Bank Limited'},
  {'bank_code': '0072', 'bank_name': 'Mayfair Bank Limited'},
  {'bank_code': '0018', 'bank_name': 'Middle East Bank Kenya Limited'},
  {'bank_code': '0012', 'bank_name': 'National Bank of Kenya Limited'},
  {'bank_code': '0007', 'bank_name': 'NCBA Bank Kenya PLC'},
  {'bank_code': '0078', 'bank_name': 'Postbank (Kenya Post Office Savings Bank)'},
  {'bank_code': '0010', 'bank_name': 'Prime Bank Limited'},
  {'bank_code': '0076', 'bank_name': 'Salaam African Bank Limited'},
  {'bank_code': '0074', 'bank_name': 'SBM Bank (Kenya) Limited'},
  {'bank_code': '0054', 'bank_name': 'Sidian Bank Limited'},
  {'bank_code': '0056', 'bank_name': 'Spire Bank Limited'},
  {'bank_code': '0031', 'bank_name': 'Stanbic Bank Kenya Limited'},
  {'bank_code': '0002', 'bank_name': 'Standard Chartered Bank Kenya Limited'},
  {'bank_code': '0026', 'bank_name': 'Trans-National Bank Limited'},
  {'bank_code': '0071', 'bank_name': 'UBA Kenya Bank Limited'},
];

// ─────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────
class BankWithdrawScreen extends StatefulWidget {
  const BankWithdrawScreen({super.key});

  @override
  State<BankWithdrawScreen> createState() => _BankWithdrawScreenState();
}

class _BankWithdrawScreenState extends State<BankWithdrawScreen> {

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountController = TextEditingController();
  final _narrationController = TextEditingController();
  final _searchController = TextEditingController();

  List<Bank> _banks = [];
  List<Bank> _filteredBanks = [];
  Bank? _selectedBank;
  bool _loadingBanks = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchBanks();
    _searchController.addListener(_filterBanks);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    _narrationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Fetch banks from API ────────────────────
  Future<void> _fetchBanks() async {
    setState(() => _loadingBanks = true);
    try {
      final response = await AuthenticatedHttpClient.get(
        Uri.parse('${ApiConstants.baseUrl}/wallet/banks'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (data['banks'] as List)
            .map((b) => Bank.fromJson(b as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.bankName.toLowerCase().compareTo(b.bankName.toLowerCase()));
        
        setState(() {
          _banks = list;
          _filteredBanks = list;
          _loadingBanks = false;
        });
        return;
      }
    } catch (_) {
      // silently fall through to fallback
    }

    // Fallback
    final fallback = _kFallbackBanks
        .map((b) => Bank.fromJson(b))
        .toList()
      ..sort((a, b) => a.bankName.toLowerCase().compareTo(b.bankName.toLowerCase()));
    
    setState(() {
      _banks = fallback;
      _filteredBanks = fallback;
      _loadingBanks = false;
    });

    if (mounted && _banks.isEmpty) {
      ToastService().showError(
        context,
        'Could not load banks from server — using cached list',
      );
    }
  }

  void _filterBanks() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredBanks = _banks
          .where((b) =>
              b.bankName.toLowerCase().contains(q) ||
              b.bankCode.contains(q))
          .toList();
    });
  }

  // ── Show searchable bank picker ─────────────
  Future<void> _showBankPicker() async {
    _searchController.clear();
    _filteredBanks = List.from(_banks);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF1A2028) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        final subColor = isDark ? Colors.white54 : Colors.black45;

        return StatefulBuilder(builder: (ctx, setModal) {
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.92,
            minChildSize: 0.4,
            builder: (_, scrollCtrl) {
              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Handle
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[500],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Text(
                        'Select Bank',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Search box
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                            fontFamily: 'Outfit', color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Search bank name or code…',
                          hintStyle:
                              TextStyle(color: subColor, fontFamily: 'Outfit'),
                          prefixIcon:
                              Icon(Icons.search, color: primaryBrandColor),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) {
                          _filterBanks();
                          setModal(() {});
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollCtrl,
                        itemCount: _filteredBanks.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey[300]),
                        itemBuilder: (_, i) {
                          final bank = _filteredBanks[i];
                          final isSelected =
                              _selectedBank?.bankCode == bank.bankCode;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: primaryBrandColor
                                  .withValues(alpha: 0.12),
                              radius: 18,
                              child: Text(
                                bank.bankCode,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 9,
                                  color: primaryBrandColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              bank.bankName,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: textColor,
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: primaryBrandColor)
                                : null,
                            onTap: () {
                              setState(() => _selectedBank = bank);
                              Navigator.of(ctx).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        });
      },
    );
  }

  // ── Submit bank transfer ──────────────
  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedBank == null) {
        ToastService().showError(context, 'Please select a bank');
        return;
      }

      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final account = _accountController.text.trim();
      final narration = _narrationController.text.trim();

      context.read<WalletBloc>().add(
            BankTransfer(
              amount: amount,
              bankCode: _selectedBank!.bankCode,
              creditAccount: account,
              narration: narration.isEmpty ? 'pesalink to John Doe' : narration,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white54 : Colors.black45;

    return BlocListener<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is BankTransferLoading) {
          setState(() => _isSubmitting = true);
        } else if (state is BankTransferSuccess) {
          setState(() => _isSubmitting = false);
          ToastService().showSuccess(context, state.message);
          // Navigate back after small delay to let toast be seen
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.of(context).pop();
          });
        } else if (state is WalletError) {
          setState(() => _isSubmitting = false);
          ToastService().showError(context, state.message);
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back,
                      color: textColor, size: 20),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                'Withdraw to Bank Account',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
            ),
            body: SafeArea(
              child: _loadingBanks && _banks.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: primaryBrandColor))
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Amount ──────────────
                            Text(
                              'Amount (KES)',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: textColor,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: textColor,
                                  fontSize: 16),
                              decoration: buildUnderlineInputDecoration(
                                context: context,
                                label: '',
                                hintText: '0.00',
                                prefixIcon: Text(
                                  '  KES',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: primaryBrandColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please enter an amount';
                                }
                                final d = double.tryParse(v);
                                if (d == null || d <= 0) {
                                  return 'Please enter a valid amount';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),

                            // ── Bank Picker ──────────
                            Text(
                              'Select Bank',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: textColor,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _showBankPicker,
                              child: Container(
                                padding: EdgeInsets.only(bottom: 12.h),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.grey[400]!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.account_balance_outlined,
                                        color: primaryBrandColor, size: 22),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _selectedBank?.bankName ??
                                            'Tap to select a bank',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          color: _selectedBank != null
                                              ? textColor
                                              : subTextColor,
                                          fontSize: 15.sp,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.keyboard_arrow_down,
                                        color: subTextColor),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // ── Account Number ───────
                            Text(
                              'Account Number',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: textColor,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _accountController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: textColor,
                                  fontSize: 16),
                              decoration: buildUnderlineInputDecoration(
                                context: context,
                                label: '',
                                hintText: 'e.g. 00106534176150',
                                prefixIcon: Icon(
                                    Icons.credit_card_outlined,
                                    color: primaryBrandColor),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter the account number';
                                }
                                if (v.trim().length < 8) {
                                  return 'Account number too short';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),

                            // ── Narration ────────────
                            Text(
                              'Narration (Optional)',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: textColor,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _narrationController,
                              maxLength: 100,
                              style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: textColor,
                                  fontSize: 16),
                              decoration: buildUnderlineInputDecoration(
                                context: context,
                                label: '',
                                hintText: 'e.g. pesalink to John Doe',
                                prefixIcon: Icon(
                                    Icons.description_outlined,
                                    color: primaryBrandColor),
                              ),
                            ),
                            const SizedBox(height: 48),

                            // ── Submit ───────────────
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _isSubmitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBrandColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 16.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Withdraw',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          // Loading overlay while submitting
          if (_isSubmitting)
            const ModalBarrier(
                dismissible: false, color: Colors.black38),
          if (_isSubmitting)
            const Center(
              child: CircularProgressIndicator(color: primaryBrandColor),
            ),
        ],
      ),
    );
  }
}
