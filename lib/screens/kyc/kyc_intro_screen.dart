import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import 'id_upload_screen.dart';
import '../home_screen.dart';

class KYCIntroScreen extends StatelessWidget {
  const KYCIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            child: Text(
              'Skip',
              style: TextStyle(fontFamily: 'Satoshi',
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: buttonGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_user_outlined,
                size: 80,
                color: buttonGreen,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Verify Your Identity',
              style: TextStyle(fontFamily: 'Satoshi',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'To protect your account and unlock all features, we need to verify your identity. This process is quick and secure.',
              style: TextStyle(fontFamily: 'Satoshi',
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildFeatureItem(context, 'Higher transaction limits'),
            const SizedBox(height: 16),
            _buildFeatureItem(context, 'Secure account recovery'),
            const SizedBox(height: 16),
            _buildFeatureItem(context, 'Access to all financial tools'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const IDUploadScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Start Verification',
                  style: TextStyle(fontFamily: 'Satoshi',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text) {
    return Row(
      children: [
        Icon(Icons.check_circle_outline, color: buttonGreen, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(fontFamily: 'Satoshi',
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
