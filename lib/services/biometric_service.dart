import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'logger_service.dart';

/// Service to handle biometric authentication (Face ID, Fingerprint, etc.)
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  
  /// Check if the device supports biometric authentication
  static Future<bool> isAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      
      AppLogger.debug(
        LogTags.auth,
        'Biometric availability check',
        data: {
          'can_check_biometrics': canAuthenticateWithBiometrics,
          'device_supported': await _auth.isDeviceSupported(),
          'can_authenticate': canAuthenticate,
        },
      );
      
      return canAuthenticate;
    } catch (e) {
      AppLogger.error(
        LogTags.auth,
        'Error checking biometric availability',
        data: {'error': e.toString()},
      );
      return false;
    }
  }
  
  /// Get list of available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
      
      AppLogger.debug(
        LogTags.auth,
        'Available biometric types',
        data: {
          'types': availableBiometrics.map((e) => e.toString()).toList(),
          'count': availableBiometrics.length,
        },
      );
      
      return availableBiometrics;
    } catch (e) {
      AppLogger.error(
        LogTags.auth,
        'Error getting available biometrics',
        data: {'error': e.toString()},
      );
      return [];
    }
  }
  
  /// Authenticate user with biometrics
  /// Returns true if authentication was successful
  static Future<bool> authenticate({
    String localizedReason = 'Please authenticate to continue',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    final startTime = DateTime.now();
    
    try {
      // Check if biometrics are available
      final isAvailable = await BiometricService.isAvailable();
      if (!isAvailable) {
        AppLogger.warning(
          LogTags.auth,
          'Biometric authentication not available on this device',
        );
        return false;
      }
      
      AppLogger.info(
        LogTags.auth,
        'Starting biometric authentication',
        data: {'localized_reason': localizedReason},
      );
      
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );
      
      final duration = DateTime.now().difference(startTime);
      
      if (didAuthenticate) {
        AppLogger.success(
          LogTags.auth,
          'Biometric authentication successful',
          data: {'duration_ms': duration.inMilliseconds},
        );
      } else {
        AppLogger.warning(
          LogTags.auth,
          'Biometric authentication failed',
          data: {'duration_ms': duration.inMilliseconds},
        );
      }
      
      return didAuthenticate;
    } on PlatformException catch (e) {
      final duration = DateTime.now().difference(startTime);
      
      String errorMessage = 'Unknown biometric error';
      if (e.code == auth_error.notAvailable) {
        errorMessage = 'Biometric authentication not available';
      } else if (e.code == auth_error.notEnrolled) {
        errorMessage = 'No biometrics enrolled on device';
      } else if (e.code == auth_error.lockedOut) {
        errorMessage = 'Too many failed attempts - biometrics locked';
      } else if (e.code == auth_error.permanentlyLockedOut) {
        errorMessage = 'Biometrics permanently locked - device restart required';
      } else if (e.code == auth_error.passcodeNotSet) {
        errorMessage = 'No passcode/PIN set on device';
      }
      
      AppLogger.error(
        LogTags.auth,
        'Biometric authentication error',
        data: {
          'error_code': e.code,
          'error_message': errorMessage,
          'platform_message': e.message,
          'duration_ms': duration.inMilliseconds,
        },
      );
      
      return false;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      
      AppLogger.error(
        LogTags.auth,
        'Unexpected biometric authentication error',
        data: {
          'error': e.toString(),
          'duration_ms': duration.inMilliseconds,
        },
      );
      
      return false;
    }
  }
  
  /// Get a user-friendly name for the biometric type
  static String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris Scan';
      case BiometricType.strong:
        return 'Biometric';
      case BiometricType.weak:
        return 'Biometric';
      default:
        return 'Biometric';
    }
  }
  
  /// Check if device has Face ID specifically
  static Future<bool> hasFaceID() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }
  
  /// Check if device has Fingerprint specifically
  static Future<bool> hasFingerprint() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint);
  }
  
  /// Stop authentication (cancel ongoing authentication)
  static Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
      AppLogger.debug(LogTags.auth, 'Biometric authentication cancelled');
    } catch (e) {
      AppLogger.error(
        LogTags.auth,
        'Error stopping biometric authentication',
        data: {'error': e.toString()},
      );
    }
  }
}
