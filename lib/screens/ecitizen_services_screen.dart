import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../utils/input_decoration.dart';
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
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        isLoading = false;
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ECitizenDetailsScreen(
            referenceNumber: _referenceController.text,
            currency: selectedCurrency,
          ),
        ),
      );
    }
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Select Currency',
          style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
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
                          color: Colors.black.withValues(alpha: 0.3),
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
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
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
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _referenceController,
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 16,
                      ),
                      decoration: buildUnderlineInputDecoration(
                        context: context,
                        label: '',
                        prefixIcon: Icon(
                          Icons.numbers_outlined,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Currency',
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showCurrencyDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3) ?? Colors.transparent, 
                              width: 1
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.monetization_on_outlined,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              selectedCurrency,
                              style: GoogleFonts.poppins(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              
              // Check Status Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _checkStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: buttonGreen.withValues(alpha: 0.5),
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
                            style: GoogleFonts.poppins(
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
      ),
    );
  }
}
