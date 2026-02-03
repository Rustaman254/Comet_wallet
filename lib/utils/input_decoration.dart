import 'package:flutter/material.dart';
import '../constants/colors.dart';

InputDecoration buildEquityInputDecoration({
  required BuildContext context,
  required String label,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? hintText,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;
  final fillColor = isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100];
  final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300];

  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      color: textColor.withOpacity(0.7),
      fontSize: 14,
    ),
    hintText: hintText,
    hintStyle: TextStyle(
      color: textColor.withOpacity(0.4),
      fontSize: 15,
    ),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: fillColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor!, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: equityMaroon, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
  );
}

InputDecoration buildUnderlineInputDecoration({
  required BuildContext context,
  required String label,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? hintText,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final hintColor = isDark ? Colors.grey[600] : Colors.grey[500];
  final borderColor = isDark ? Colors.grey[700] : Colors.grey[400];

  return InputDecoration(
    labelText: label.isEmpty ? null : label,
    labelStyle: const TextStyle(
      color: Colors.grey,
      fontSize: 14,
    ),
    hintText: hintText,
    hintStyle: TextStyle(
      color: hintColor,
      fontSize: 16,
      // Using system font (no fontFamily specified)
    ),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        color: borderColor ?? Colors.grey,
        width: 1,
      ),
    ),
    focusedBorder: const UnderlineInputBorder(
      borderSide: BorderSide(
        color: buttonGreen,
        width: 2,
      ),
    ),
    border: UnderlineInputBorder(
      borderSide: BorderSide(
        color: borderColor ?? Colors.grey,
        width: 1,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12),
  );
}

