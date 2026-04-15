import 'package:flutter/material.dart';
import '../constants/colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : lightPrimaryText,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: isDark ? Colors.white : lightPrimaryText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Introduction', isDark),
              _buildSectionContent(
                'FusionFi ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how your personal information is collected, used, and disclosed by FusionFi.',
                isDark,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Information Collection', isDark),
              _buildSectionContent(
                'We collect information from you when you visit our app, register on our site, place an order, subscribe to our newsletter, respond to a survey or fill out a form.',
                isDark,
              ),
              _buildBulletPoint('Name / Username', isDark),
              _buildBulletPoint('Phone Numbers', isDark),
              _buildBulletPoint('Email Addresses', isDark),
              _buildBulletPoint('Mailing Addresses', isDark),
              _buildBulletPoint('Billing Addresses', isDark),
              const SizedBox(height: 24),
              _buildSectionTitle('Use of Information', isDark),
              _buildSectionContent(
                'Any of the information we collect from you may be used in one of the following ways:',
                isDark,
              ),
              _buildBulletPoint('To personalize your experience', isDark),
              _buildBulletPoint('To improve our app', isDark),
              _buildBulletPoint('To improve customer service', isDark),
              _buildBulletPoint('To process transactions', isDark),
              const SizedBox(height: 24),
              _buildSectionTitle('Security', isDark),
              _buildSectionContent(
                'We implement a variety of security measures to maintain the safety of your personal information when you place an order or enter, submit, or access your personal information.',
                isDark,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Contact Us', isDark),
              _buildSectionContent(
                'If there are any questions regarding this privacy policy, you may contact us using the information below:',
                isDark,
              ),
              _buildSectionContent('Email: support@fusionfi.io', isDark),
              const SizedBox(height: 48),
              Center(
                child: Text(
                  'Last updated: April 15, 2026',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: isDark ? Colors.white30 : lightTertiaryText,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : lightPrimaryText,
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        content,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 15,
          color: isDark ? Colors.white70 : lightSecondaryText,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: primaryBrandColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                color: isDark ? Colors.white70 : lightSecondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
