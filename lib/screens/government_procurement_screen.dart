import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'view_tenders_screen.dart';
import 'track_application_screen.dart';

class GovernmentProcurementScreen extends StatefulWidget {
  const GovernmentProcurementScreen({super.key});

  @override
  State<GovernmentProcurementScreen> createState() => _GovernmentProcurementScreenState();
}

class _GovernmentProcurementScreenState extends State<GovernmentProcurementScreen> {
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
                        'Government Procurement',
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
                  'Access government tenders, submit bids, and manage your procurement activities',
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
                      icon: Icons.description_outlined,
                      title: 'View Tenders',
                      description: 'Browse available government tenders',
                      color: const Color(0xFF4CAF50),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ViewTendersScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildServiceCard(
                      context,
                      icon: Icons.gavel_outlined,
                      title: 'Submit Bid',
                      description: 'Submit your bid for tenders',
                      color: const Color(0xFF2196F3),
                      onTap: () {
                        _showComingSoonDialog(context, 'Submit Bid');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildServiceCard(
                      context,
                      icon: Icons.track_changes_outlined,
                      title: 'Track Application',
                      description: 'Check status of submitted bids',
                      color: const Color(0xFFFF9800),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TrackApplicationScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildServiceCard(
                      context,
                      icon: Icons.business_center_outlined,
                      title: 'Supplier Registration',
                      description: 'Register as a government supplier',
                      color: const Color(0xFF9C27B0),
                      onTap: () {
                        _showComingSoonDialog(context, 'Supplier Registration');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildServiceCard(
                      context,
                      icon: Icons.payment_outlined,
                      title: 'Pay Procurement Fees',
                      description: 'Pay for tender documents and registration',
                      color: const Color(0xFFE91E63),
                      onTap: () {
                        _showComingSoonDialog(context, 'Pay Procurement Fees');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildServiceCard(
                      context,
                      icon: Icons.folder_outlined,
                      title: 'Documents & Guidelines',
                      description: 'Access procurement documents and guidelines',
                      color: const Color(0xFF00BCD4),
                      onTap: () {
                        _showComingSoonDialog(context, 'Documents & Guidelines');
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
