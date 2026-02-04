import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../utils/input_decoration.dart';
import '../services/ecitizen_service.dart';
import '../models/ecitizen_bill.dart';
import 'ecitizen_details_screen.dart';

class ECitizenServicesScreen extends StatefulWidget {
  const ECitizenServicesScreen({super.key});

  @override
  State<ECitizenServicesScreen> createState() => _ECitizenServicesScreenState();
}

class _ECitizenServicesScreenState extends State<ECitizenServicesScreen> {
  final TextEditingController _referenceController = TextEditingController();
  String selectedCurrency = 'USD';
  bool isLoading = false;

  final List<String> currencies = ['USD', 'KES', 'EUR'];

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  void _checkStatus() async {
    if (_referenceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a reference number',
            style: const TextStyle(fontFamily: 'Satoshi'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final bill = await ECitizenService.validateBill(
        refNo: _referenceController.text.trim(),
      );

      if (mounted) {
        setState(() {
          isLoading = false;
        });

        if (bill != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ECitizenDetailsScreen(
                bill: bill,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(fontFamily: 'Satoshi'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Select Currency',
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.map((currency) {
            return ListTile(
              title: Text(
                currency,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                setState(() {
                  selectedCurrency = currency;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // match login page
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'E-Citizen Services',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
              
                    // Reference Number Input
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reference Number',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              color: Colors.grey[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _referenceController,
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: buildUnderlineInputDecoration(
                              context: context,
                              label: '',
                              prefixIcon: const Icon(
                                Icons.numbers_outlined,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Currency',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              color: Colors.grey[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _showCurrencyDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.white24,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.monetization_on_outlined,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    selectedCurrency,
                                    style: const TextStyle(
                                      fontFamily: 'Satoshi',
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24), // Add some bottom spacing for scrollable content
                  ],
                ),
              ),
            ),
            
            // Check Status Button (Fixed at bottom)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), // 24 bottom padding
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _checkStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        buttonGreen.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Check Status',
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
