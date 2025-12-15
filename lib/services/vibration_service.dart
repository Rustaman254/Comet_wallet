import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VibrationService {
  static const String _prefKey = 'vibration_enabled';
  
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? true; // Default to enabled
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }

  static Future<void> vibrate() async {
    if (await isEnabled()) {
      await HapticFeedback.mediumImpact();
    }
  }

  static Future<void> errorVibrate() async {
    if (await isEnabled()) {
       await HapticFeedback.heavyImpact();
       await Future.delayed(const Duration(milliseconds: 100));
       await HapticFeedback.heavyImpact();
    }
  }

  static Future<void> lightImpact() async {
    if (await isEnabled()) {
      await HapticFeedback.lightImpact();
    }
  }

  static Future<void> selectionClick() async {
    if (await isEnabled()) {
      await HapticFeedback.selectionClick();
    }
  }
}
