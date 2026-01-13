import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/vibration_service.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        child: Center(
          heightFactor: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(40), // Pill shape
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Fit content
              children: [
                _buildNavItem(context, 0, Icons.home),
                const SizedBox(width: 8),
                _buildNavItem(context, 1, Icons.credit_card),
                const SizedBox(width: 8),
                _buildNavItem(context, 2, Icons.pie_chart_outline),
                const SizedBox(width: 8),
                _buildNavItem(context, 3, Icons.settings_outlined),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (currentIndex != index) {
          VibrationService.lightImpact();
          onTap(index);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16), // Comfortable click space
        decoration: BoxDecoration(
          color: isSelected ? buttonGreen.withValues(alpha: 0.1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? buttonGreen 
                  : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              size: 24,
            ),
            if (isSelected && index == 0) // Optional indicator for Home
               Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: buttonGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
