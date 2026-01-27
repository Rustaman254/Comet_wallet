import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/real_estate_models.dart';
import '../services/real_estate_service.dart';

class BuyTokensScreen extends StatefulWidget {
  final RealEstateProperty property;

  const BuyTokensScreen({super.key, required this.property});

  @override
  State<BuyTokensScreen> createState() => _BuyTokensScreenState();
}

class _BuyTokensScreenState extends State<BuyTokensScreen> {
  final TextEditingController _tokenController = TextEditingController();
  int _tokenCount = 10; // Minimum tokens
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tokenController.text = '10';
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  double get _totalAmount => _tokenCount * widget.property.pricePerToken;

  void _updateTokenCount(String value) {
    final count = int.tryParse(value) ?? 10;
    setState(() {
      _tokenCount = count.clamp(10, widget.property.availableTokens);
    });
  }

  Future<void> _processPurchase() async {
    if (_tokenCount < 10) {
      _showErrorDialog('Minimum purchase is 10 tokens');
      return;
    }

    if (_tokenCount > widget.property.availableTokens) {
      _showErrorDialog('Not enough tokens available');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await RealEstateService.buyPropertyTokens(
        propertyId: widget.property.id,
        tokenCount: _tokenCount,
        totalAmount: _totalAmount,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        _showSuccessDialog(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorDialog('Purchase failed: $e');
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: buttonGreen.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_outline,
                  color: buttonGreen, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Purchase Successful!',
              style: TextStyle(fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result['message'] ?? 'Successfully purchased tokens',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Outfit',
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildReceiptRow('Property', widget.property.name),
                  const SizedBox(height: 8),
                  _buildReceiptRow('Tokens', '$_tokenCount'),
                  const SizedBox(height: 8),
                  _buildReceiptRow(
                      'Total Amount', 'KES ${_totalAmount.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _buildReceiptRow('Transaction ID',
                      result['transactionId'] ?? 'N/A',
                      isLast: true),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to property details
              Navigator.pop(context); // Go back to property list
            },
            child: Text(
              'Done',
              style: TextStyle(fontFamily: 'Outfit',
                color: buttonGreen,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text(
              'Error',
              style: TextStyle(fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontFamily: 'Outfit',
            color: Colors.white.withOpacity(0.8),
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(fontFamily: 'Outfit',
                color: buttonGreen,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
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
                      'Buy Tokens',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Outfit',
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property summary card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.property.images.first,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.home_work,
                                      color: Colors.grey),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.property.name,
                                  style: TextStyle(fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.property.location,
                                  style: TextStyle(fontFamily: 'Outfit',
                                    color: Colors.grey[400],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: buttonGreen.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'ROI: ${widget.property.expectedROI}%',
                                    style: TextStyle(fontFamily: 'Outfit',
                                      color: buttonGreen,
                                      fontSize: 11,
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

                    // Token count input
                    Text(
                      'Number of Tokens',
                      style: TextStyle(fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_tokenCount > 10) {
                              setState(() {
                                _tokenCount -= 10;
                                _tokenController.text = _tokenCount.toString();
                              });
                            }
                          },
                          icon: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cardBorder),
                            ),
                            child: const Icon(Icons.remove, color: Colors.white),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _tokenController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Outfit',
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: cardBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: cardBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: buttonGreen),
                              ),
                            ),
                            onChanged: _updateTokenCount,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (_tokenCount < widget.property.availableTokens) {
                              setState(() {
                                _tokenCount += 10;
                                _tokenController.text = _tokenCount.toString();
                              });
                            }
                          },
                          icon: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cardBorder),
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Min: 10 tokens • Max: ${widget.property.availableTokens} tokens',
                      style: TextStyle(fontFamily: 'Outfit',
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Investment summary
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Investment Summary',
                            style: TextStyle(fontFamily: 'Outfit',
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryRow('Price per Token',
                              'KES ${widget.property.pricePerToken.toStringAsFixed(0)}'),
                          const SizedBox(height: 12),
                          _buildSummaryRow('Number of Tokens', '$_tokenCount'),
                          const SizedBox(height: 12),
                          _buildSummaryRow('Transaction Fee', 'KES 0.00'),
                          const SizedBox(height: 16),
                          Divider(color: cardBorder),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount',
                                style: TextStyle(fontFamily: 'Outfit',
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'KES ${_totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(fontFamily: 'Outfit',
                                  color: buttonGreen,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: buttonGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: buttonGreen.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: buttonGreen, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Expected annual return: KES ${(_totalAmount * widget.property.expectedROI / 100).toStringAsFixed(2)}',
                                    style: TextStyle(fontFamily: 'Outfit',
                                      color: buttonGreen,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Buy button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: darkBackground,
                border: Border(top: BorderSide(color: cardBorder)),
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[700],
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Text(
                          'Confirm Purchase',
                          style: TextStyle(fontFamily: 'Outfit',
                            fontSize: 16,
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

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Outfit',
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(fontFamily: 'Outfit',
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontFamily: 'Outfit',
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 8),
          Divider(color: Colors.grey[800], height: 1),
        ],
      ],
    );
  }
}
