import 'package:flutter/material.dart';

/// A colorful USDA crypto logo widget that works in both light and dark modes
class USDALogo extends StatelessWidget {
  final double size;
  final bool showText;
  
  const USDALogo({
    super.key,
    this.size = 32,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    if (size == 0) return const SizedBox.shrink();
    
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.asset(
          'assets/images/usda_logo_new.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to original design if asset missing
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4A90E2), Color(0xFF50C9C3)],
                ),
              ),
              child: Center(
                child: Text(
                  'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Helper to get flag emoji for a currency or country code
  static String getFlag(String code) {
    final Map<String, String> flags = {
      'KES': '🇰🇪',
      'USD': '🇺🇸',
      'TZS': '🇹🇿',
      'UGX': '🇺🇬',
      'EUR': '🇪🇺',
      'GBP': '🇬🇧',
      'ZAR': '🇿🇦',
      'RWF': '🇷🇼',
      'NGN': '🇳🇬',
      'GHS': '🇬🇭',
      'ETB': '🇪🇹',
      'EGP': '🇪🇬',
      'SSP': '🇸🇸',
      'CNY': '🇨🇳',
      'INR': '🇮🇳',
      'AED': '🇦🇪',
      '+254': '🇰🇪',
      '+256': '🇺🇬',
      '+255': '🇹🇿',
      '+250': '🇷🇼',
      '+234': '🇳🇬',
      '+233': '🇬🇭',
      '+251': '🇪🇹',
      '+20': '🇪🇬',
      '+211': '🇸🇸',
      '+86': '🇨🇳',
      '+91': '🇮🇳',
      '+971': '🇦🇪',
      'Kenya': '🇰🇪',
      'Uganda': '🇺🇬',
      'Tanzania': '🇹🇿',
      'Rwanda': '🇷🇼',
    };
    return flags[code] ?? '🏳️';
  }
}

/// A horizontal USDA badge with logo and text
class USDABadge extends StatelessWidget {
  final double height;
  
  const USDABadge({
    super.key,
    this.height = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: height * 0.4, vertical: height * 0.15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A90E2), // Vibrant blue
            Color(0xFF50C9C3), // Bright teal
          ],
        ),
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90E2).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.anchor,
            color: Colors.white,
            size: height * 0.6,
          ),
          SizedBox(width: height * 0.2),
          Text(
            'USDA',
            style: TextStyle(
              fontFamily: 'Satoshi',
              color: Colors.white,
              fontSize: height * 0.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
