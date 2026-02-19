import 'package:flutter/material.dart';

// Primary color - Vibrant green for actions
const Color buttonGreen = Color(0xFF2ECD42); // Modern teal green
const Color equityMaroon = Color(0xFFA32A29);
const Color equityGold = Color(0xFFE8B931);

// Gradient & Accent colors
const Color primaryBlue = Color(0xFF3B82F6); // Modern blue
const Color accentPurple = Color(0xFF8B5CF6); // Vibrant purple
const Color successGreen = Color(0xFF34D399); // Success/positive
const Color warningOrange = Color(0xFFFA9D3A); // Warning/caution
const Color errorRed = Color(0xFFEF4444); // Error/negative

// Dark Theme Colors
const Color darkBackground = Color(0xFF122023); // Deep dark background
const Color darkSurface = Color(0xFF1A1F26); // Card/surface background
const Color darkBorder = Color(0xFF2A3441); // Subtle border

// Light Theme Colors - Modern & Colorful with Better Contrast
const Color lightBackground = Color(0xFFF0F4F8); // Soft blue-gray background
const Color lightCardBackground = Color(0xFFFFFFFF); // Pure white cards
const Color lightSurface = Color(0xFFE8EEF5); // Light blue surface
const Color lightPrimaryText = Color(0xFF0A1929); // Deep blue-black text for maximum contrast
const Color lightSecondaryText = Color(0xFF3E5060); // Darker gray for better readability
const Color lightTertiaryText = Color(0xFF6B7A90); // Medium gray text
const Color lightBorder = Color(0xFFD0D9E3); // Subtle blue-gray borders
const Color lightDivider = Color(0xFFB8C5D6); // Visible dividers

// Light mode accent colors - More vibrant
const Color lightAccentBlue = Color(0xFF2563EB); // Bright blue
const Color lightAccentPurple = Color(0xFF7C3AED); // Vivid purple
const Color lightAccentGreen = Color(0xFF059669); // Rich green
const Color lightAccentOrange = Color(0xFFEA580C); // Vibrant orange

// Legacy colors for compatibility
const Color darkTeal = Color(0xFF1A4D4D);
const Color darkGreen = Color(0xFF0F3D3D);
const Color brightGreen = Color(0xFF2ECD42);
const Color lightGreen = Color(0xFF66BB6A);
const Color gold = Color(0xFFFFD700);
const Color cardBackground = darkSurface;
const Color cardBorder = darkBorder;

// Text color references for light theme
const Color lightTextPrimary = lightPrimaryText;
const Color lightTextSecondary = lightSecondaryText;

// Colorful transaction type colors
const Color transactionSendColor = Color(0xFFEF4444); // Red
const Color transactionReceiveColor = Color(0xFF10B981); // Green  
const Color transactionSwapColor = Color(0xFF8B5CF6); // Purple
const Color transactionTopupColor = Color(0xFF3B82F6); // Blue
const Color transactionWithdrawColor = Color(0xFFF59E0B); // Amber
const Color transactionDefaultColor = Color(0xFF6B7280); // Gray

// Theme-aware color helpers
Color getTextColor(BuildContext context, {bool isPrimary = true}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (isDark) {
    return isPrimary ? Colors.white : Colors.white70;
  } else {
    return isPrimary ? lightPrimaryText : lightSecondaryText;
  }
}

Color getSecondaryTextColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? Colors.white70 : lightSecondaryText;
}

Color getTertiaryTextColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? Colors.white60 : lightTertiaryText;
}

Color getCardColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark 
    ? cardBackground 
    : lightCardBackground;
}

Color getSurfaceColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark 
    ? darkSurface 
    : lightSurface;
}

Color getBorderColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark 
    ? cardBorder 
    : lightBorder;
}

Color getTransactionColor(String transactionType) {
  final type = transactionType.toLowerCase();
  if (type.contains('send') || type.contains('transfer')) {
    return transactionSendColor;
  } else if (type.contains('receive') || type.contains('deposit')) {
    return transactionReceiveColor;
  } else if (type.contains('swap') || type.contains('exchange')) {
    return transactionSwapColor;
  } else if (type.contains('topup') || type.contains('top-up')) {
    return transactionTopupColor;
  } else if (type.contains('withdraw')) {
    return transactionWithdrawColor;
  }
  return transactionDefaultColor;
}

