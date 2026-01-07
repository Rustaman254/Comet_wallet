import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';

class LogLevel {
  static const String info = 'INFO';
  static const String debug = 'DEBUG';
  static const String warning = 'WARNING';
  static const String error = 'ERROR';
  static const String success = 'SUCCESS';
}

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();

  factory AppLogger() {
    return _instance;
  }

  AppLogger._internal();

  /// Log info level messages
  static void info(String tag, String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.info, tag, message, data);
  }

  /// Log debug level messages
  static void debug(String tag, String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.debug, tag, message, data);
  }

  /// Log warning level messages
  static void warning(String tag, String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.warning, tag, message, data);
  }

  /// Log error level messages
  static void error(String tag, String message, {Map<String, dynamic>? data, StackTrace? stackTrace}) {
    _log(LogLevel.error, tag, message, data, stackTrace);
  }

  /// Log success level messages
  static void success(String tag, String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.success, tag, message, data);
  }

  /// Internal logging method
  static void _log(
    String level,
    String tag,
    String message,
    Map<String, dynamic>? data, [
    StackTrace? stackTrace,
  ]) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
    final logMessage = _formatLog(timestamp, level, tag, message, data);

    // Print to console
    if (kDebugMode) {
      print(logMessage);
      if (stackTrace != null) {
        print('Stack Trace: $stackTrace');
      }
    }

    // Log to dart developer console
    developer.log(
      logMessage,
      time: DateTime.now(),
      sequenceNumber: 0,
      level: _getLogLevel(level),
      name: tag,
    );
  }

  /// Format log message
  static String _formatLog(
    String timestamp,
    String level,
    String tag,
    String message,
    Map<String, dynamic>? data,
  ) {
    final buffer = StringBuffer();
    buffer.write('[$timestamp] ');
    buffer.write('[$level] ');
    buffer.write('[$tag] ');
    buffer.write(message);

    if (data != null && data.isNotEmpty) {
      buffer.write('\n  Data: ');
      data.forEach((key, value) {
        if (value is String && value.length > 100) {
          buffer.write('\n    $key: ${value.substring(0, 100)}...');
        } else {
          buffer.write('\n    $key: $value');
        }
      });
    }

    return buffer.toString();
  }

  /// Convert log level to dart log level
  static int _getLogLevel(String level) {
    switch (level) {
      case LogLevel.debug:
        return 0;
      case LogLevel.info:
        return 500;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.success:
        return 500;
      default:
        return 500;
    }
  }

  /// Log user profile information
  static void logUserProfile(Map<String, dynamic> profileData) {
    final sanitizedData = _sanitizeData(profileData);
    info(
      'USER_PROFILE',
      'User profile loaded',
      data: sanitizedData,
    );
  }

  /// Log user registration
  static void logUserRegistration(Map<String, dynamic> registrationData) {
    final sanitizedData = _sanitizeData(registrationData);
    success(
      'USER_REGISTRATION',
      'User registration completed',
      data: sanitizedData,
    );
  }

  /// Log KYC submission
  static void logKYCSubmission(Map<String, dynamic> kycData) {
    final sanitizedData = _sanitizeData(kycData);
    success(
      'KYC_SUBMISSION',
      'KYC submission completed',
      data: sanitizedData,
    );
  }

  /// Log KYC image uploads
  static void logKYCImageUpload({
    required String imageType,
    required String imageUrl,
    required int fileSizeBytes,
    required Duration uploadDuration,
  }) {
    info(
      'KYC_IMAGE_UPLOAD',
      'KYC image uploaded: $imageType',
      data: {
        'type': imageType,
        'url': imageUrl,
        'file_size_kb': (fileSizeBytes / 1024).toStringAsFixed(2),
        'upload_duration_ms': uploadDuration.inMilliseconds,
      },
    );
  }

  /// Log API request
  static void logAPIRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? body,
  }) {
    final sanitizedBody = body != null ? _sanitizeData(body) : null;
    debug(
      'API_REQUEST',
      '$method $endpoint',
      data: {
        'endpoint': endpoint,
        'method': method,
        'headers': headers,
        'body': sanitizedBody,
      },
    );
  }

  /// Log API response
  static void logAPIResponse({
    required String endpoint,
    required String method,
    required int statusCode,
    required Duration duration,
    Map<String, dynamic>? response,
  }) {
    final sanitizedResponse = response != null ? _sanitizeData(response) : null;
    final level = statusCode >= 200 && statusCode < 300 ? LogLevel.success : LogLevel.error;

    _log(
      level,
      'API_RESPONSE',
      '$method $endpoint - Status: $statusCode',
      {
        'endpoint': endpoint,
        'status_code': statusCode,
        'duration_ms': duration.inMilliseconds,
        'response': sanitizedResponse,
      },
    );
  }

  /// Log app lifecycle events
  static void logAppLifecycle(String event) {
    info(
      'APP_LIFECYCLE',
      event,
      data: {'event': event, 'timestamp': DateTime.now().toIso8601String()},
    );
  }

  /// Log navigation
  static void logNavigation({
    required String from,
    required String to,
    Map<String, dynamic>? arguments,
  }) {
    debug(
      'NAVIGATION',
      'Navigate from $from to $to',
      data: {
        'from': from,
        'to': to,
        'arguments': arguments,
      },
    );
  }

  /// Log error with context
  static void logErrorWithContext({
    required String tag,
    required String message,
    required dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final data = {
      'message': message,
      'error': error.toString(),
      ...?context,
    };

    _log(
      LogLevel.error,
      tag,
      'Error occurred',
      data,
      stackTrace,
    );
  }

  /// Sanitize sensitive data
  static Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    data.forEach((key, value) {
      if (_isSensitiveKey(key)) {
        sanitized[key] = '***REDACTED***';
      } else if (value is Map) {
        sanitized[key] = _sanitizeData(Map<String, dynamic>.from(value));
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is Map) {
            return _sanitizeData(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  /// Check if key is sensitive
  static bool _isSensitiveKey(String key) {
    final sensitiveKeys = [
      'password',
      'pin',
      'secret',
      'token',
      'apikey',
      'api_key',
      'privatekey',
      'private_key',
      'authorization',
      'authtoken',
      'auth_token',
      'ssn',
      'socialSecurityNumber',
      'creditCard',
      'credit_card',
      'cvv',
      'cvc',
      'accountNumber',
      'account_number',
      'routingNumber',
      'routing_number',
    ];

    return sensitiveKeys.contains(key.toLowerCase());
  }
}

/// Log tags for different modules
class LogTags {
  static const String auth = 'AUTH';
  static const String kyc = 'KYC';
  static const String payment = 'PAYMENT';
  static const String transaction = 'TRANSACTION';
  static const String navigation = 'NAVIGATION';
  static const String api = 'API';
  static const String database = 'DATABASE';
  static const String camera = 'CAMERA';
  static const String storage = 'STORAGE';
  static const String validation = 'VALIDATION';
}
