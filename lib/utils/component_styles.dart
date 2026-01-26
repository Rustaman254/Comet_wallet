import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Modern component styling utilities for consistent design across the app

class ModernButton {
  /// Primary action button style
  static ButtonStyle primary({bool isEnabled = true}) {
    return ElevatedButton.styleFrom(
      backgroundColor: isEnabled ? buttonGreen : lightTertiaryText,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  /// Secondary action button style
  static ButtonStyle secondary({bool isEnabled = true}) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: buttonGreen,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      side: BorderSide(
        color: isEnabled ? buttonGreen : lightBorder,
        width: 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  /// Rounded pill button (for onboarding/splash)
  static ButtonStyle rounded({bool isEnabled = true}) {
    return ElevatedButton.styleFrom(
      backgroundColor: isEnabled ? buttonGreen : lightTertiaryText,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
    );
  }

  /// Icon button style
  static ButtonStyle icon({Color? color, double size = 24}) {
    return IconButton.styleFrom(
      foregroundColor: color ?? buttonGreen,
    );
  }
}

class ModernCard {
  /// Standard card with shadow and border
  static BoxDecoration standard({
    Color backgroundColor = lightCardBackground,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: isDark ? darkSurface : backgroundColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark ? darkBorder : lightBorder,
        width: 1,
      ),
      boxShadow: isDark
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
    );
  }

  /// Elevated card with more shadow
  static BoxDecoration elevated({bool isDark = false}) {
    return BoxDecoration(
      color: isDark ? darkSurface : lightCardBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark ? darkBorder : lightBorder,
        width: 1,
      ),
      boxShadow: isDark
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
    );
  }

  /// Minimal card without shadow
  static BoxDecoration minimal({bool isDark = false}) {
    return BoxDecoration(
      color: isDark ? darkSurface : lightCardBackground,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? darkBorder : lightBorder,
        width: 1,
      ),
    );
  }
}

class ModernInput {
  /// Modern input decoration
  static InputDecoration textField({
    required String label,
    String? hint,
    bool isDark = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: isDark ? darkSurface : lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? darkBorder : lightBorder,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? darkBorder : lightBorder,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: buttonGreen,
          width: 2,
        ),
      ),
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : lightSecondaryText,
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: isDark ? Colors.white30 : lightTertiaryText,
        fontFamily: 'Outfit',
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  /// Minimal input decoration
  static InputDecoration minimal({
    required String label,
    String? hint,
    bool isDark = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: UnderlineInputBorder(
        borderSide: BorderSide(
          color: isDark ? darkBorder : lightBorder,
        ),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: isDark ? darkBorder : lightBorder,
        ),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(
          color: buttonGreen,
          width: 2,
        ),
      ),
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : lightSecondaryText,
        fontFamily: 'Outfit',
      ),
      hintStyle: TextStyle(
        color: isDark ? Colors.white30 : lightTertiaryText,
        fontFamily: 'Outfit',
      ),
    );
  }
}

class ModernTheme {
  /// Get button theme data for light theme
  static OutlinedButtonThemeData lightOutlinedButton() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: buttonGreen,
        side: const BorderSide(color: buttonGreen, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  /// Get button theme data for dark theme
  static OutlinedButtonThemeData darkOutlinedButton() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: buttonGreen,
        side: const BorderSide(color: buttonGreen, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}
