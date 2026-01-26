import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../services/logger_service.dart';

/// Example Integration of Logging System
/// This file shows how to integrate AppLogger into your screens and services

class LoggingExampleScreen extends StatefulWidget {
  const LoggingExampleScreen({super.key});

  @override
  State<LoggingExampleScreen> createState() => _LoggingExampleScreenState();
}

class _LoggingExampleScreenState extends State<LoggingExampleScreen> {
  @override
  void initState() {
    super.initState();
    
    // Log screen initialization
    AppLogger.logNavigation(
      from: 'PreviousScreen',
      to: 'LoggingExampleScreen',
    );
    
    // Log app lifecycle
    AppLogger.logAppLifecycle('Logging Example Screen opened');
  }

  void _exampleInfoLog() {
    AppLogger.info(
      LogTags.auth,
      'User action performed',
      data: {
        'action': 'button_tap',
        'button_name': 'Info Log Example',
        'user_id': 123,
      },
    );
  }

  void _exampleDebugLog() {
    AppLogger.debug(
      LogTags.api,
      'API request prepared',
      data: {
        'endpoint': '/api/v1/users/profile',
        'method': 'GET',
        'params': {
          'user_id': 123,
        },
      },
    );
  }

  void _exampleSuccessLog() {
    AppLogger.success(
      LogTags.kyc,
      'Operation completed successfully',
      data: {
        'operation': 'KYC_SUBMISSION',
        'duration_ms': 5000,
        'images_uploaded': 5,
      },
    );
  }

  void _exampleWarningLog() {
    AppLogger.warning(
      LogTags.storage,
      'Warning: Low disk space',
      data: {
        'available_mb': 50,
        'required_mb': 100,
      },
    );
  }

  void _exampleErrorLog() {
    try {
      throw Exception('This is a simulated error');
    } catch (e, stackTrace) {
      AppLogger.error(
        LogTags.api,
        'API request failed',
        data: {
          'endpoint': '/api/v1/users',
          'status_code': 500,
          'retry_count': 3,
        },
        stackTrace: stackTrace,
      );
    }
  }

  void _exampleUserRegistrationLog() {
    // Simulate user registration logging
    AppLogger.logUserRegistration({
      'email': 'john.doe@example.com',
      'first_name': 'John',
      'last_name': 'Doe',
      'phone_number': '+254712345678',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _exampleKYCSubmissionLog() {
    // Simulate KYC submission logging
    AppLogger.logKYCSubmission({
      'KYC': {
        'userID': 123,
        'ID_document': 'https://images.cradlevoices.com/uploads/id_front.webp',
        'ID_document_back': 'https://images.cradlevoices.com/uploads/id_back.webp',
        'KRA_document': 'https://images.cradlevoices.com/uploads/kra.webp',
        'profile_photo': 'https://images.cradlevoices.com/uploads/profile.webp',
        'proof_of_address': 'https://images.cradlevoices.com/uploads/address.webp',
      }
    });
  }

  void _exampleUserProfileLog() {
    // Simulate user profile logging
    AppLogger.logUserProfile({
      'id': 123,
      'email': 'john.doe@example.com',
      'first_name': 'John',
      'last_name': 'Doe',
      'phone_number': '+254712345678',
      'kyc_status': 'verified',
      'account_balance': 5000.00,
      'created_at': '2024-01-01T00:00:00Z',
    });
  }

  void _exampleAPIRequestLog() {
    AppLogger.logAPIRequest(
      endpoint: 'https://api.yeshara.network/api/v1/users/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: {
        'email': 'user@example.com',
        'password': 'secret_password_123', // Will be redacted
      },
    );
  }

  void _exampleAPIResponseLog() {
    AppLogger.logAPIResponse(
      endpoint: 'https://api.yeshara.network/api/v1/users/login',
      method: 'POST',
      statusCode: 200,
      duration: const Duration(milliseconds: 1500),
      response: {
        'success': true,
        'user': {
          'id': 123,
          'email': 'user@example.com',
          'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        },
      },
    );
  }

  void _exampleKYCImageUploadLog() {
    AppLogger.logKYCImageUpload(
      imageType: 'ID_Front',
      imageUrl: 'https://images.cradlevoices.com/uploads/1738562610_id_front.webp',
      fileSizeBytes: 1024000,
      uploadDuration: const Duration(seconds: 5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Logging Examples',
          style: TextStyle(fontFamily: 'Satoshi',),
        ),
        backgroundColor: buttonGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildExampleButton(
              label: 'INFO Log',
              description: 'Logs general info messages',
              onPressed: _exampleInfoLog,
            ),
            _buildExampleButton(
              label: 'DEBUG Log',
              description: 'Logs debug information',
              onPressed: _exampleDebugLog,
            ),
            _buildExampleButton(
              label: 'SUCCESS Log',
              description: 'Logs successful operations',
              onPressed: _exampleSuccessLog,
            ),
            _buildExampleButton(
              label: 'WARNING Log',
              description: 'Logs warning messages',
              onPressed: _exampleWarningLog,
            ),
            _buildExampleButton(
              label: 'ERROR Log',
              description: 'Logs error messages with stack trace',
              onPressed: _exampleErrorLog,
            ),
            const SizedBox(height: 24),
            Text(
              'User & Profile Logging',
              style: TextStyle(fontFamily: 'Satoshi',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildExampleButton(
              label: 'User Registration Log',
              description: 'Logs user registration info',
              onPressed: _exampleUserRegistrationLog,
            ),
            _buildExampleButton(
              label: 'User Profile Log',
              description: 'Logs user profile information',
              onPressed: _exampleUserProfileLog,
            ),
            const SizedBox(height: 24),
            Text(
              'KYC Logging',
              style: TextStyle(fontFamily: 'Satoshi',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildExampleButton(
              label: 'KYC Submission Log',
              description: 'Logs complete KYC submission',
              onPressed: _exampleKYCSubmissionLog,
            ),
            _buildExampleButton(
              label: 'KYC Image Upload Log',
              description: 'Logs individual image uploads',
              onPressed: _exampleKYCImageUploadLog,
            ),
            const SizedBox(height: 24),
            Text(
              'API Logging',
              style: TextStyle(fontFamily: 'Satoshi',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildExampleButton(
              label: 'API Request Log',
              description: 'Logs API requests (passwords redacted)',
              onPressed: _exampleAPIRequestLog,
            ),
            _buildExampleButton(
              label: 'API Response Log',
              description: 'Logs API responses with status codes',
              onPressed: _exampleAPIResponseLog,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ℹ️ Check the Terminal/Console',
                    style: TextStyle(fontFamily: 'Satoshi',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All logs appear in the terminal/console when running the app with "flutter run"',
                    style: TextStyle(fontFamily: 'Satoshi',fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleButton({
    required String label,
    required String description,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        child: ListTile(
          title: Text(
            label,
            style: TextStyle(fontFamily: 'Satoshi',fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            description,
            style: TextStyle(fontFamily: 'Satoshi',fontSize: 12),
          ),
          trailing: const Icon(Icons.arrow_forward),
          onTap: onPressed,
        ),
      ),
    );
  }
}

// ============================================================
// INTEGRATION EXAMPLES IN YOUR EXISTING SCREENS
// ============================================================

/// Example: Integrating logging in Sign Up Screen
class SignUpScreenWithLogging {
  void handleSignUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    try {
      AppLogger.info(
        LogTags.auth,
        'Sign up process started',
        data: {'email': email},
      );

      // Make API call
      // final response = await AuthService.register(...);

      // Log successful registration
      AppLogger.logUserRegistration({
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'timestamp': DateTime.now().toIso8601String(),
      });

      AppLogger.success(
        LogTags.auth,
        'User registered successfully',
        data: {'email': email},
      );
    } catch (e) {
      AppLogger.error(
        LogTags.auth,
        'Sign up failed',
        data: {'email': email, 'error': e.toString()},
      );
    }
  }
}

/// Example: Integrating logging in KYC Process
class KYCScreenWithLogging {
  void handleKYCComplete({
    required int userId,
    required String idFrontUrl,
    required String idBackUrl,
    required String kraUrl,
    required String profilePhotoUrl,
    required String addressProofUrl,
  }) async {
    try {
      AppLogger.info(
        LogTags.kyc,
        'KYC submission started',
        data: {'user_id': userId},
      );

      // Log each image upload
      AppLogger.logKYCImageUpload(
        imageType: 'ID_Front',
        imageUrl: idFrontUrl,
        fileSizeBytes: 1024000,
        uploadDuration: const Duration(seconds: 3),
      );

      // Log complete submission
      AppLogger.logKYCSubmission({
        'KYC': {
          'userID': userId,
          'ID_document': idFrontUrl,
          'ID_document_back': idBackUrl,
          'KRA_document': kraUrl,
          'profile_photo': profilePhotoUrl,
          'proof_of_address': addressProofUrl,
        }
      });

      AppLogger.success(
        LogTags.kyc,
        'KYC submitted successfully',
        data: {'user_id': userId},
      );
    } catch (e) {
      AppLogger.error(
        LogTags.kyc,
        'KYC submission failed',
        data: {'user_id': userId, 'error': e.toString()},
      );
    }
  }
}
