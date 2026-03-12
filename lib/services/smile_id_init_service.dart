import 'package:flutter/foundation.dart';
import 'package:smile_id/smile_id.dart';
import 'package:smile_id/generated/smileid_messages.g.dart';
import '../constants/smile_id_config.dart';

/// Service responsible for proper initialization and verification of Smile ID SDK.
/// This ensures the native fileSavePath is properly initialized before any operations.
class SmileIDInitService {
  static final SmileIDInitService _instance = SmileIDInitService._internal();

  factory SmileIDInitService() {
    return _instance;
  }

  SmileIDInitService._internal();

  static bool _isInitialized = false;
  static bool _initializationInProgress = false;

  /// Check if SmileID is properly initialized
  static bool get isInitialized => _isInitialized;

  /// Initialize SmileID with proper error handling and verification.
  /// This should be called in main() before the app starts.
  static Future<bool> initializeSmileID() async {
    // Prevent multiple concurrent initialization attempts
    if (_initializationInProgress) {
      debugPrint("SmileID initialization already in progress, waiting...");
      // Wait for initialization to complete
      int retries = 0;
      while (_initializationInProgress && retries < 100) {
        await Future.delayed(const Duration(milliseconds: 100));
        retries++;
      }
      return _isInitialized;
    }

    if (_isInitialized) {
      debugPrint("SmileID already initialized");
      return true;
    }

    _initializationInProgress = true;

    try {
      // Give native channel time to fully initialize
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint("Starting SmileID Dart initialization");

      SmileID.initializeWithConfig(
        useSandbox: SmileIDConfig.useSandbox,
        config: FlutterConfig(
          partnerId: SmileIDConfig.partnerId,
          authToken: SmileIDConfig.authToken,
          prodBaseUrl: SmileIDConfig.prodBaseUrl,
          sandboxBaseUrl: SmileIDConfig.sandboxBaseUrl,
        ),
        enableCrashReporting: true,
      );

      // Set callback URL globally after initialization
      SmileID.setCallbackUrl(
        callbackUrl: Uri.parse(SmileIDConfig.callbackUrl),
      );

      // CRITICAL: Wait for native initialization to complete
      // initializeWithConfig does not return a Future, so we use getServices
      // to block until the native engine has completed its queue AND
      // the fileSavePath has been properly initialized.
      await SmileID.api.getServices();

      // Additional verification: ensure native state is ready
      await Future.delayed(const Duration(milliseconds: 200));

      _isInitialized = true;
      debugPrint("SmileID Dart initialization completed successfully");
      return true;
    } catch (e) {
      _isInitialized = false;
      debugPrint("SmileID initialization failed: $e");
      return false;
    } finally {
      _initializationInProgress = false;
    }
  }

  /// Ensures SmileID is ready before attempting any operation.
  /// Call this before using any Smile ID SDK features.
  static Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      final success = await initializeSmileID();
      if (!success) {
        throw Exception("Failed to initialize SmileID SDK");
      }
    }

    // Additional safety: wait a bit to ensure native state is fully ready
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Force re-initialization. Use carefully, mainly for debugging.
  static Future<bool> forceReinitialize() async {
    _isInitialized = false;
    _initializationInProgress = false;
    return initializeSmileID();
  }
}
