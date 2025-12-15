import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

InputDecoration buildUnderlineInputDecoration({
  required BuildContext context,
  required String label,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? hintText,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primaryColor = Theme.of(context).primaryColor;
  final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
  final hintColor = textColor.withOpacity(0.5);
  final borderColor = textColor.withOpacity(0.3);

  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.poppins(
      color: textColor.withOpacity(0.7),
      fontSize: 14,
    ),
    hintText: hintText,
    hintStyle: GoogleFonts.poppins(
      color: hintColor,
      fontSize: 16,
    ),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        color: borderColor,
        width: 1,
      ),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        color: buttonGreen, // Keep accent color
        width: 2,
      ),
    ),
    border: UnderlineInputBorder(
      borderSide: BorderSide(
        color: borderColor,
        width: 1,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12),
  );
}

