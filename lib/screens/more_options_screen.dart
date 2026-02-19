import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'ecitizen_services_screen.dart';
import 'withdraw_money_screen.dart';
import 'receive_money_screen.dart';
import '../services/toast_service.dart';

class MoreOptionsScreen extends StatelessWidget {
  const MoreOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define options
    final List<Map<String, dynamic>> options = [
      {
        'icon': Icons.monetization_on_outlined,
        'label': 'Receive',
        'onTap': () {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ReceiveMoneyScreen(),
            ),
          );
        },
        'isComingSoon': false,
      },
      {
        'icon': Icons.public,
        'label': 'E-Citizen',
        'onTap': () {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ECitizenServicesScreen(),
            ),
          );
        },
        'isComingSoon': false,
      },
      {
        'icon': Icons.phone_outlined,
        'label': 'Buy Airtime',
        'onTap': () {
          Navigator.pop(context);
          ToastService().showSuccess(context, 'Airtime coming soon!');
        },
        'isComingSoon': true,
      },
      {
        'icon': Icons.receipt_long_outlined,
        'label': 'Pay Bills',
        'onTap': () {
          Navigator.pop(context);
          ToastService().showSuccess(context, 'Bill payment coming soon!');
        },
        'isComingSoon': true,
      },
      {
        'icon': Icons.request_page_outlined,
        'label': 'Request Money',
        'onTap': () {
          Navigator.pop(context);
          ToastService().showSuccess(context, 'Request money coming soon!');
        },
        'isComingSoon': true,
      },
      {
        'icon': Icons.savings_outlined,
        'label': 'Savings',
        'onTap': () {
          Navigator.pop(context);
          ToastService().showSuccess(context, 'Savings coming soon!');
        },
        'isComingSoon': true,
      },
    ];

    // Sort: Active first, then Coming Soon
    options.sort((a, b) {
      if (a['isComingSoon'] == b['isComingSoon']) {
        return 0;
      }
      return a['isComingSoon'] ? 1 : -1;
    });

    return Container(
      width: double.infinity, // Ensure full width for centering/alignment
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center, // Align title center
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.3) : Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'More Options',
            style: TextStyle(fontFamily: 'Satoshi',
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          
          // Wrap for responsiveness
          Container(
            width: double.infinity,
            alignment: Alignment.topCenter,
            child: Wrap(
              spacing: 24, // Horizontal space between items
              runSpacing: 32, // Vertical space between lines
              alignment: WrapAlignment.start, // Align items to the start of the line
              crossAxisAlignment: WrapCrossAlignment.start,
              children: options.map((option) {
                return _buildCircularOption(
                  context,
                  option['icon'] as IconData,
                  option['label'] as String,
                  option['onTap'] as VoidCallback,
                  showComingSoon: option['isComingSoon'] as bool,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 40), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildCircularOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool showComingSoon = false,
  }) {
    // Fixed width for consistent alignment in Wrap
    const double itemWidth = 80;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: itemWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 28),
                ),
                if (showComingSoon)
                  Positioned(
                    top: -4,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark ? darkBackground : lightBackground,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'Coming Soon',
                        style: TextStyle(fontFamily: 'Satoshi',
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontFamily: 'Satoshi',
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
