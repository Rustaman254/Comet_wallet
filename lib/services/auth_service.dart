import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import 'logger_service.dart';
import 'token_service.dart';

class AuthService {
  /// User registration
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    final startTime = DateTime.now();

    try {
      final requestBody = {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
      };

      AppLogger.logAPIRequest(
        endpoint: ApiConstants.registerEndpoint,
        method: 'POST',
        body: requestBody,
      );

      final response = await http.post(
        Uri.parse(ApiConstants.registerEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);

        AppLogger.logAPIResponse(
          endpoint: ApiConstants.registerEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: jsonResponse,
        );

        // Log user registration
        final registrationData = {
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
          'timestamp': DateTime.now().toIso8601String(),
        };

        AppLogger.logUserRegistration(registrationData);

        return jsonResponse;
      } else {
        AppLogger.logAPIResponse(
          endpoint: ApiConstants.registerEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: {'error': response.body},
        );

        throw Exception('Registration failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      AppLogger.error(
        LogTags.auth,
        'User registration error',
        data: {
          'email': email,
          'error': e.toString(),
          'duration_ms': duration.inMilliseconds,
        },
      );

      throw Exception('Registration error: $e');
    }
  }

  /// User login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final startTime = DateTime.now();

    try {
      final requestBody = {
        'email': email,
        'password': password,
      };

      AppLogger.logAPIRequest(
        endpoint: ApiConstants.loginEndpoint,
        method: 'POST',
        body: requestBody,
      );

      final response = await http.post(
        Uri.parse(ApiConstants.loginEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);

        AppLogger.logAPIResponse(
          endpoint: ApiConstants.loginEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: jsonResponse,
        );

        // Save authentication token and user data
        final token = jsonResponse['token'] ?? jsonResponse['access_token'] ?? '';
        final userId = jsonResponse['user']?['id']?.toString() ?? jsonResponse['id']?.toString() ?? '';
        
        if (token.isNotEmpty) {
          await TokenService.saveUserData(
            token: token,
            userId: userId,
            email: email,
            phoneNumber: jsonResponse['user']?['phone'] ?? jsonResponse['phone'] ?? '',
          );

          AppLogger.debug(
            LogTags.auth,
            'Authentication token saved',
            data: {'user_id': userId},
          );
        }

        AppLogger.info(
          LogTags.auth,
          'User login successful',
          data: {
            'email': email,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        return jsonResponse;
      } else {
        AppLogger.logAPIResponse(
          endpoint: ApiConstants.loginEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: {'error': response.body},
        );

        throw Exception('Login failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      AppLogger.error(
        LogTags.auth,
        'User login error',
        data: {
          'email': email,
          'error': e.toString(),
          'duration_ms': duration.inMilliseconds,
        },
      );

      throw Exception('Login error: $e');
    }
  }

  /// Load user profile
  static Future<void> loadUserProfile(Map<String, dynamic> profileData) async {
    try {
      AppLogger.logUserProfile(profileData);

      AppLogger.info(
        LogTags.auth,
        'User profile information loaded',
        data: {
          'user_id': profileData['id'],
          'email': profileData['email'],
          'kyc_status': profileData['kyc_status'],
        },
      );
    } catch (e) {
      AppLogger.error(
        LogTags.auth,
        'Failed to load user profile',
        data: {'error': e.toString()},
      );
    }
  }
}
