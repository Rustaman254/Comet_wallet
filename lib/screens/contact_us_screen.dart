import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../constants/colors.dart';
import '../services/vibration_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _launchUrl(String url) async {
    VibrationService.selectionClick();
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

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
          'Contact Us',
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
              Text(
                'Get in Touch',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : lightPrimaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Our team is here to help you with any questions or issues you may have.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  color: isDark ? Colors.white70 : lightSecondaryText,
                ),
              ),
              const SizedBox(height: 32),
              _buildContactCard(
                context,
                'Email Support',
                'support@fusionfi.io',
                HeroIcons.envelope,
                primaryBrandColor,
                () => _launchUrl('mailto:support@fusionfi.io'),
                isDark,
              ),
              const SizedBox(height: 16),
              _buildContactCard(
                context,
                'WhatsApp',
                '+254 710 865 696',
                HeroIcons.chatBubbleLeftEllipsis,
                successGreen,
                () => _launchUrl('https://wa.me/254710865696'),
                isDark,
              ),
              const SizedBox(height: 16),
              _buildContactCard(
                context,
                'Website',
                'www.fusionfi.io',
                HeroIcons.globeAlt,
                secondaryBrandColor,
                () => _launchUrl('https://www.fusionfi.io'),
                isDark,
              ),
              const SizedBox(height: 32),
              Text(
                'Follow Us',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : lightPrimaryText,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSocialIcon(
                    context,
                    HeroIcons.codeBracketSquare, // Using as placeholder
                    () => _launchUrl('https://twitter.com/fusionfi'),
                    isDark,
                  ),
                  _buildSocialIcon(
                    context,
                    HeroIcons.bookmarkSquare, // Using as placeholder
                    () => _launchUrl('https://facebook.com/fusionfi'),
                    isDark,
                  ),
                  _buildSocialIcon(
                    context,
                    HeroIcons.videoCamera, // Using as placeholder
                    () => _launchUrl('https://instagram.com/fusionfi'),
                    isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    String title,
    String value,
    HeroIcons icon,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? darkSurface : lightCardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? darkBorder : lightBorder,
            width: 1,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: HeroIcon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: isDark ? Colors.white54 : lightTertiaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      color: isDark ? Colors.white : lightPrimaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white24 : lightBorder,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(
    BuildContext context,
    HeroIcons icon,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? darkSurface : lightCardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? darkBorder : lightBorder,
            width: 1,
          ),
        ),
        child: HeroIcon(
          icon,
          color: isDark ? Colors.white70 : lightSecondaryText,
          size: 24,
        ),
      ),
    );
  }
}
