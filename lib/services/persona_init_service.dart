import 'package:flutter/foundation.dart';
import 'package:persona/persona.dart';
import '../constants/persona_config.dart';

/// Service responsible for proper initialization and verification of Persona SDK.
/// This ensures the native context is properly initialized before any operations.
class PersonaInitService {
  static final PersonaInitService _instance = PersonaInitService._internal();

  factory PersonaInitService() {
    return _instance;
  }

  PersonaInitService._internal();

  static bool _isInitialized = false;
  static bool _initializationInProgress = false;

  /// Check if Persona is properly initialized
  static bool get isInitialized => _isInitialized;

  /// Initialize Persona with proper error handling and verification.
  /// This should be called in main() before the app starts.
  static Future<bool> initializePersona() async {
    // Prevent multiple concurrent initialization attempts
    if (_initializationInProgress) {
      debugPrint("Persona initialization already in progress, waiting...");
      // Wait for initialization to complete
      int retries = 0;
      while (_initializationInProgress && retries < 100) {
        await Future.delayed(const Duration(milliseconds: 100));
        retries++;
      }
      return _isInitialized;
    }

    if (_isInitialized) {
      debugPrint("Persona already initialized");
      return true;
    }

    _initializationInProgress = true;

    try {
      // Give native channel time to fully initialize
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint("Starting Persona Dart initialization");

      Persona.initialize(
        templateId: PersonaConfig.templateId,
        apiKey: PersonaConfig.apiKey,
        environment: PersonaConfig.useSandbox 
            ? PersonaEnvironment.sandbox 
            : PersonaEnvironment.production,
      );

      // Additional verification: ensure native state is ready
      await Future.delayed(const Duration(milliseconds: 200));

      _isInitialized = true;
      debugPrint("Persona Dart initialization completed successfully");
      return true;
    } catch (e) {
      _isInitialized = false;
      debugPrint("Persona initialization failed: $e");
      return false;
    } finally {
      _initializationInProgress = false;
    }
  }

  /// Ensures Persona is ready before attempting any operation.
  /// Call this before using any Persona SDK features.
  static Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      final success = await initializePersona();
      if (!success) {
        throw Exception("Failed to initialize Persona SDK");
      }
    }

    // Additional safety: wait a bit to ensure native state is fully ready
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
