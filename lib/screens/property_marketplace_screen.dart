import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/real_estate_models.dart';
import '../services/real_estate_service.dart';

class PropertyMarketplaceScreen extends StatefulWidget {
  const PropertyMarketplaceScreen({super.key});

  @override
  State<PropertyMarketplaceScreen> createState() =>
      _PropertyMarketplaceScreenState();
}

class _PropertyMarketplaceScreenState extends State<PropertyMarketplaceScreen> {
  List<MarketplaceListing> _listings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() => _isLoading = true);
    try {
      final listings = await RealEstateService.getMarketplaceListings();
      setState(() {
        _listings = listings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading listings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBuyDialog(MarketplaceListing listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirm Purchase',
          style: TextStyle(fontFamily: 'Outfit',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to buy these tokens?',
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
                  _buildDialogRow('Property', listing.propertyName),
                  const SizedBox(height: 8),
                  _buildDialogRow('Tokens', '${listing.tokenCount}'),
                  const SizedBox(height: 8),
                  _buildDialogRow('Price/Token',
                      'KES ${listing.pricePerToken.toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey[800]),
                  const SizedBox(height: 8),
                  _buildDialogRow('Total Amount',
                      'KES ${listing.totalValue.toStringAsFixed(2)}',
                      isTotal: true),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Outfit',
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _processPurchase(listing);
            },
            child: Text(
              'Buy Now',
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

  Future<void> _processPurchase(MarketplaceListing listing) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: buttonGreen),
      ),
    );

    try {
      final result = await RealEstateService.buyMarketplaceTokens(
        listingId: listing.id,
        totalAmount: listing.totalValue,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSuccessDialog(result);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        content: Text(
          result['message'] ?? 'Successfully purchased tokens from marketplace',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Outfit',
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadListings(); // Refresh listings
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
                      'Marketplace',
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
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Buy tokens from other investors',
                style: TextStyle(fontFamily: 'Outfit',
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: buttonGreen),
                    )
                  : _listings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.storefront_outlined,
                                  size: 64, color: Colors.grey[600]),
                              const SizedBox(height: 16),
                              Text(
                                'No listings available',
                                style: TextStyle(fontFamily: 'Outfit',
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadListings,
                          color: buttonGreen,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            itemCount: _listings.length,
                            itemBuilder: (context, index) {
                              return _buildListingCard(_listings[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingCard(MarketplaceListing listing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          // Property image and info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    listing.propertyImage,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[800],
                        child: const Icon(Icons.home_work, color: Colors.grey),
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
                        listing.propertyName,
                        style: TextStyle(fontFamily: 'Outfit',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing.location,
                        style: TextStyle(fontFamily: 'Outfit',
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            listing.sellerName,
                            style: TextStyle(fontFamily: 'Outfit',
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: cardBorder, height: 1),

          // Listing details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildListingStat(
                      'Tokens Available',
                      '${listing.tokenCount}',
                    ),
                    _buildListingStat(
                      'Price/Token',
                      'KES ${listing.pricePerToken.toStringAsFixed(0)}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'vs. Original Price',
                          style: TextStyle(fontFamily: 'Outfit',
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              listing.isPriceIncreased
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: listing.isPriceIncreased
                                  ? Colors.red
                                  : buttonGreen,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${listing.priceChangePercentage.abs().toStringAsFixed(1)}%',
                              style: TextStyle(fontFamily: 'Outfit',
                                color: listing.isPriceIncreased
                                    ? Colors.red
                                    : buttonGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Value',
                          style: TextStyle(fontFamily: 'Outfit',
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'KES ${listing.totalValue.toStringAsFixed(0)}',
                          style: TextStyle(fontFamily: 'Outfit',
                            color: const Color(0xFF6366F1),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showBuyDialog(listing),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                  child: Text(
                    'Buy Now',
                    style: TextStyle(fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Outfit',
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
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

  Widget _buildDialogRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Outfit',
            color: Colors.grey[400],
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(fontFamily: 'Outfit',
            color: isTotal ? buttonGreen : Colors.white,
            fontSize: isTotal ? 16 : 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
