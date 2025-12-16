import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

enum ToastType { success, error, info }

class CustomToast extends StatelessWidget {
  final String message;
  final ToastType type;
  final VoidCallback? onDismiss;

  const CustomToast({
    super.key,
    required this.message,
    required this.type,
    this.onDismiss,
  });

  Color get _borderColor {
    switch (type) {
      case ToastType.success:
        return buttonGreen;
      case ToastType.error:
        return Colors.redAccent;
      case ToastType.info:
        return Colors.blueAccent;
    }
  }

  IconData get _icon {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.error:
        return Icons.error_outline;
      case ToastType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2025) : Colors.white, // Slightly lighter than background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, color: _borderColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(
                  Icons.close,
                  color: isDark ? Colors.white54 : Colors.black45,
                  size: 18,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
