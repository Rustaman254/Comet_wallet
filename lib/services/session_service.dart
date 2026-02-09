import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';

/// Service to manage user session, including inactivity timeout and token expiration
class SessionService {
  static const String _lastActivityKey = 'last_activity_timestamp';
  static const Duration _inactivityTimeout = Duration(minutes: 1);
  
  static Timer? _inactivityTimer;
  static DateTime? _lastActivityTime;
  static VoidCallback? _onSessionExpired;
  
  /// Initialize session tracking
  static Future<void> initialize({required VoidCallback onSessionExpired}) async {
    _onSessionExpired = onSessionExpired;
    await _loadLastActivity();
    _startInactivityTimer();
    
    AppLogger.debug(
      LogTags.auth,
      'Session service initialized',
      data: {
        'timeout_minutes': _inactivityTimeout.inMinutes,
        'last_activity': _lastActivityTime?.toIso8601String() ?? 'none',
      },
    );
  }
  
  /// Load last activity timestamp from storage
  static Future<void> _loadLastActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastActivityKey);
      if (timestamp != null) {
        _lastActivityTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      AppLogger.error(
        LogTags.auth,
        'Failed to load last activity',
        data: {'error': e.toString()},
      );
    }
  }
  
  /// Save current activity timestamp
  static Future<void> _saveLastActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setInt(_lastActivityKey, now.millisecondsSinceEpoch);
      _lastActivityTime = now;
    } catch (e) {
      AppLogger.error(
        LogTags.auth,
        'Failed to save last activity',
        data: {'error': e.toString()},
      );
    }
  }
  
  /// Record user activity (call this on any user interaction)
  static Future<void> recordActivity() async {
    await _saveLastActivity();
    _resetInactivityTimer();
  }
  
  /// Start or restart the inactivity timer
  static void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityTimeout, _handleInactivityTimeout);
  }
  
  /// Reset the inactivity timer
  static void _resetInactivityTimer() {
    _startInactivityTimer();
  }
  
  /// Handle inactivity timeout
  static void _handleInactivityTimeout() {
    AppLogger.warning(
      LogTags.auth,
      'Session expired due to inactivity',
      data: {
        'timeout_minutes': _inactivityTimeout.inMinutes,
        'last_activity': _lastActivityTime?.toIso8601String() ?? 'unknown',
      },
    );
    
    _onSessionExpired?.call();
  }
  
  /// Check if session has expired based on last activity
  static Future<bool> isSessionExpired() async {
    await _loadLastActivity();
    
    if (_lastActivityTime == null) {
      return false; // No previous activity recorded
    }
    
    final now = DateTime.now();
    final difference = now.difference(_lastActivityTime!);
    final isExpired = difference > _inactivityTimeout;
    
    if (isExpired) {
      AppLogger.warning(
        LogTags.auth,
        'Session check: Session expired',
        data: {
          'inactive_for_minutes': difference.inMinutes,
          'timeout_minutes': _inactivityTimeout.inMinutes,
        },
      );
    }
    
    return isExpired;
  }
  
  /// Clear session data
  static Future<void> clearSession() async {
    _inactivityTimer?.cancel();
    _lastActivityTime = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastActivityKey);
    } catch (e) {
      AppLogger.error(
        LogTags.auth,
        'Failed to clear session',
        data: {'error': e.toString()},
      );
    }
    
    AppLogger.debug(LogTags.auth, 'Session cleared');
  }
  
  /// Pause session tracking (e.g., when app goes to background)
  static void pause() {
    _inactivityTimer?.cancel();
    _saveLastActivity();
    
    AppLogger.debug(
      LogTags.auth,
      'Session tracking paused',
      data: {'last_activity': _lastActivityTime?.toIso8601String()},
    );
  }
  
  /// Resume session tracking (e.g., when app comes to foreground)
  static Future<void> resume() async {
    await _loadLastActivity();
    
    final isExpired = await isSessionExpired();
    if (isExpired) {
      AppLogger.warning(LogTags.auth, 'Session expired while app was in background');
      _onSessionExpired?.call();
    } else {
      _startInactivityTimer();
      AppLogger.debug(LogTags.auth, 'Session tracking resumed');
    }
  }
  
  /// Dispose of resources
  static void dispose() {
    _inactivityTimer?.cancel();
    _onSessionExpired = null;
  }
}
