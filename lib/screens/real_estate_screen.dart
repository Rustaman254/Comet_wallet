import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'property_list_screen.dart';
import 'my_properties_screen.dart';
import 'property_marketplace_screen.dart';

class RealEstateScreen extends StatefulWidget {
  const RealEstateScreen({super.key});

  @override
  State<RealEstateScreen> createState() => _RealEstateScreenState();
}

class _RealEstateScreenState extends State<RealEstateScreen> {
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
                        'Real Estate Tokenization',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Satoshi',
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
              const SizedBox(height: 32),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Invest in fractional real estate ownership through blockchain tokenization',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Satoshi',
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Service Categories
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    _buildServiceCard(
                      context,
                      icon: Icons.home_work_outlined,
                      title: 'Browse Properties',
                      description: 'View available tokenized real estate',
                      color: const Color(0xFF6366F1),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PropertyListScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildServiceCard(
                      context,
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'My Portfolio',
                      description: 'Manage your property investments',
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MyPropertiesScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildServiceCard(
                      context,
                      icon: Icons.storefront_outlined,
                      title: 'Marketplace',
                      description: 'Trade property tokens',
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PropertyMarketplaceScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildServiceCard(
                      context,
                      icon: Icons.analytics_outlined,
                      title: 'Property Analytics',
                      description: 'View performance metrics',
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        _showComingSoonDialog(context, 'Property Analytics');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildServiceCard(
                      context,
                      icon: Icons.calculate_outlined,
                      title: 'Investment Calculator',
                      description: 'Calculate potential returns',
                      color: const Color(0xFFEC4899),
                      onTap: () {
                        _showComingSoonDialog(context, 'Investment Calculator');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildServiceCard(
                      context,
                      icon: Icons.history_outlined,
                      title: 'Transaction History',
                      description: 'View past property transactions',
                      color: const Color(0xFF06B6D4),
                      onTap: () {
                        _showComingSoonDialog(context, 'Transaction History');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontFamily: 'Satoshi',
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontFamily: 'Satoshi',
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: buttonGreen,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Coming Soon',
              style: TextStyle(fontFamily: 'Satoshi',
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          '$feature functionality will be available soon. Stay tuned!',
          style: TextStyle(fontFamily: 'Satoshi',
            color: Colors.white.withOpacity(0.8),
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(fontFamily: 'Satoshi',
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
}
