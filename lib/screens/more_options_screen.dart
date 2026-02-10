import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'ecitizen_services_screen.dart';
import 'withdraw_money_screen.dart';
import '../services/toast_service.dart';

class MoreOptionsScreen extends StatelessWidget {
  const MoreOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.3) : Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
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
          // Grid of circular options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCircularOption(
                context,
                Icons.phone_outlined,
                'Buy Airtime',
                () {
                  Navigator.pop(context);
                  ToastService().showSuccess(context, 'Airtime coming soon!');
                },
                showComingSoon: true,
              ),
              _buildCircularOption(
                context,
                Icons.receipt_long_outlined,
                'Pay Bills',
                () {
                  Navigator.pop(context);
                  ToastService().showSuccess(context, 'Bill payment coming soon!');
                },
                showComingSoon: true,
              ),
              _buildCircularOption(
                context,
                Icons.request_page_outlined,
                'Request Money',
                () {
                  Navigator.pop(context);
                  ToastService().showSuccess(context, 'Request money coming soon!');
                },
                showComingSoon: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Second row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCircularOption(
                context,
                Icons.savings_outlined,
                'Savings',
                () {
                  Navigator.pop(context);
                  ToastService().showSuccess(context, 'Savings coming soon!');
                },
                showComingSoon: true,
              ),
              _buildCircularOption(
                context,
                Icons.public,
                'E-Citizen',
                () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ECitizenServicesScreen(),
                    ),
                  );
                },
              ),
              _buildCircularOption(
                context,
                Icons.monetization_on_outlined,
                'Withdraw',
                () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WithdrawMoneyScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
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
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontFamily: 'Satoshi',
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
