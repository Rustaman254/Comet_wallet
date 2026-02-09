import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../constants/api_constants.dart';
import 'logger_service.dart';
import 'token_service.dart';
import '../utils/debug_utils.dart';
import '../models/user_profile.dart';
import 'authenticated_http_client.dart';

class AuthService {
  /// User registration
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String location,
    required String pin,
  }) async {
    final startTime = DateTime.now();

    // DEBUG: Test connectivity
    try {
      final lookup = await InternetAddress.lookup('google.com');
      if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
        AppLogger.info(LogTags.auth, 'Connection verification: Connected to google.com');
      }
    } catch (e) {
      AppLogger.error(LogTags.auth, 'Connection verification failed', data: {'error': e.toString()});
    }

    try {
      final requestBody = {
        'user': {
          'email': email,
          'password': password,
          'name': name,
          'phone': phoneNumber,
          'role': 8,
          'status': 'active',
          'location': location,
          'pin': pin,
        }
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


        // Handle response structure where User might be capitalized
        final userObj = jsonResponse['user'] ?? jsonResponse['User'];
        
        // Try to find token at root or inside userObj
        String token = jsonResponse['token'] ?? jsonResponse['access_token'] ?? '';
        if (token.isEmpty && userObj != null) {
          token = userObj['token'] ?? userObj['access_token'] ?? '';
        }

        if (userObj != null) {
          final userId = userObj?['id']?.toString() ?? jsonResponse['id']?.toString() ?? '';
          final userEmail = userObj?['email'] ?? email ?? '';
          final phone = userObj?['phone'] ?? jsonResponse['phone'] ?? '';
          final userName = userObj?['name'] ?? name ?? '';
          
          // Save what we have, even if token is empty
          final cardanoAddress = userObj?['cardano_address'];
          final balanceAda = (userObj?['balance_ada'] ?? 0.0).toDouble();
          final balanceUsda = (userObj?['balance_usda'] ?? 0.0).toDouble();
          final balanceUsdaRaw = userObj?['balance_usda_raw'];

          // Save what we have, even if token is empty
          await TokenService.saveExtendedUserData(
            token: token,
            userId: userId,
            email: userEmail,
            phoneNumber: phone,
            name: userName,
            cardanoAddress: cardanoAddress,
            balanceAda: balanceAda,
            balanceUsda: balanceUsda,
            balanceUsdaRaw: balanceUsdaRaw,
          );
        }

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
        'user': {
          'email': email,
          'password': password,
        }
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
        // Token is at root level in response: response['token']
        // User data is in response['user']
        final token = jsonResponse['token'] ?? jsonResponse['access_token'] ?? '';
        final userObj = jsonResponse['user'];
        final userId = userObj?['id']?.toString() ?? jsonResponse['id']?.toString() ?? '';
        final userEmail = userObj?['email'] ?? email ?? '';
        final phone = userObj?['phone'] ?? jsonResponse['phone'] ?? '';
        final name = userObj?['name'] ?? '';
        
        AppLogger.debug(
          LogTags.auth,
          'Token extraction from response',
          data: {
            'token_exists': token.isNotEmpty,
            'token_length': token.length,
            'user_id': userId,
            'email': userEmail,
            'phone': phone,
          },
        );
        
        if (token.isNotEmpty) {
          final cardanoAddress = userObj?['cardano_address'];
          final balanceAda = (userObj?['balance_ada'] ?? 0.0).toDouble();
          final balanceUsda = (userObj?['balance_usda'] ?? 0.0).toDouble();
          final balanceUsdaRaw = userObj?['balance_usda_raw'];

          await TokenService.saveExtendedUserData(
            token: token,
            userId: userId,
            email: userEmail,
            phoneNumber: phone,
            name: name,
            cardanoAddress: cardanoAddress,
            balanceAda: balanceAda,
            balanceUsda: balanceUsda,
            balanceUsdaRaw: balanceUsdaRaw,
          );

          AppLogger.debug(
            LogTags.auth,
            'Authentication token saved to TokenService',
            data: {'user_id': userId, 'phone': phone},
          );
          
          // Verify token was saved
          final savedToken = await TokenService.getToken();
          AppLogger.debug(
            LogTags.auth,
            'Token verification after save',
            data: {
              'token_saved': savedToken != null && savedToken.isNotEmpty,
              'token_match': savedToken == token,
            },
          );
        } else {
          AppLogger.error(
            LogTags.auth,
            'Token not found in login response',
            data: {'response_keys': jsonResponse.keys.toList()},
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

        // Run diagnostics after successful login
        await DebugUtils.runFullDiagnostics();

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

  /// Get user profile
  static Future<UserProfile?> getUserProfile() async {
    final startTime = DateTime.now();
    final token = await TokenService.getToken();

    if (token == null || token.isEmpty) {
      AppLogger.warning(LogTags.auth, 'No token found when fetching profile');
      return null;
    }

    try {
      AppLogger.logAPIRequest(
        endpoint: ApiConstants.userProfileEndpoint,
        method: 'GET',
      );

      final response = await AuthenticatedHttpClient.get(
        Uri.parse(ApiConstants.userProfileEndpoint),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        AppLogger.logAPIResponse(
          endpoint: ApiConstants.userProfileEndpoint,
          method: 'GET',
          statusCode: response.statusCode,
          duration: duration,
          response: jsonResponse,
        );

        if (jsonResponse['user'] != null) {
          return UserProfile.fromJson(jsonResponse['user']);
        }
        return null;
      } else {
        AppLogger.logAPIResponse(
          endpoint: ApiConstants.userProfileEndpoint,
          method: 'GET',
          statusCode: response.statusCode,
          duration: duration,
          response: {'error': response.body},
        );
        return null;
      }
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      AppLogger.error(
        LogTags.auth,
        'Get user profile error',
        data: {
          'error': e.toString(),
          'duration_ms': duration.inMilliseconds,
        },
      );
      // Return null instead of throwing to allow fallback to hardcoded data
      return null;
    }
  }

  /// Verify user PIN
  static Future<bool> verifyPin(String pin) async {
    final startTime = DateTime.now();

    try {
      final token = await TokenService.getToken();
      
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final requestBody = {'pin': pin};

      AppLogger.logAPIRequest(
        endpoint: ApiConstants.verifyPinEndpoint,
        method: 'POST',
        body: requestBody,
      );

      final response = await AuthenticatedHttpClient.post(
        Uri.parse(ApiConstants.verifyPinEndpoint),
        body: jsonEncode(requestBody),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        AppLogger.logAPIResponse(
          endpoint: ApiConstants.verifyPinEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: jsonResponse,
        );

        return jsonResponse['verified'] == true;
      } else {
        AppLogger.logAPIResponse(
          endpoint: ApiConstants.verifyPinEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: {'error': response.body},
        );
        return false;
      }
    } catch (e) {
      AppLogger.error(LogTags.auth, 'PIN verification failed', data: {'error': e.toString()});
      rethrow;
    }
  }
}
