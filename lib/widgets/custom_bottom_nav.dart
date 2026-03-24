import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../constants/colors.dart';
import '../services/vibration_service.dart';
import '../utils/responsive_utils.dart';

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
        padding: EdgeInsets.only(bottom: 20.h, left: 24.w, right: 24.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(40.r), // Pill shape
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10.r,
                  offset: Offset(0, 5.h),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Fit content
              children: [
                _buildNavItem(context, 0, HeroIcons.home),
                SizedBox(width: 8.w),
                // Card removed
                _buildNavItem(context, 1, HeroIcons.listBullet),
                SizedBox(width: 8.w),
                _buildNavItem(context, 2, HeroIcons.checkBadge),
                SizedBox(width: 8.w),
                _buildNavItem(context, 3, HeroIcons.ellipsisHorizontal),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, HeroIcons icon) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (currentIndex != index) {
          VibrationService.lightImpact();
          onTap(index);
        }
      },
      child: Container(
        padding: EdgeInsets.all(16.r), // Comfortable click space
        decoration: BoxDecoration(
          color: isSelected 
              ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[800]) 
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: HeroIcon(
          icon,
          color: isSelected 
              ? Theme.of(context).cardColor
              : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          size: 24.r,
        ),
      ),
    );
  }
}
