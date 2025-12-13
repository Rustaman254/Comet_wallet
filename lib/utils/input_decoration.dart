import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

InputDecoration buildUnderlineInputDecoration({
  required String label,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? hintText,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.poppins(
      color: Colors.white70,
      fontSize: 14,
    ),
    hintText: hintText,
    hintStyle: GoogleFonts.poppins(
      color: Colors.white.withValues(alpha: 0.5),
      fontSize: 16,
    ),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.3),
        width: 1,
      ),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        color: buttonGreen,
        width: 2,
      ),
    ),
    border: UnderlineInputBorder(
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.3),
        width: 1,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12),
  );
}

