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
  /// Extract a human-readable error message from an HTTP response.
  /// Checks for `error`, `message`, and `description` fields in the JSON body.
  /// Falls back to a generic message if nothing usable is found.
  /// Robustly extracts a human-readable error message from a backend response.
  static String _extractErrorMessage(http.Response response) {
    try {
      final dynamic body = jsonDecode(response.body);
      return _findErrorInObject(body) ?? 'Something went wrong, please try again.';
    } catch (_) {
      // Body is not valid JSON
      if (response.body.isNotEmpty && response.body.length < 200) {
        return response.body;
      }
    }
    return 'Something went wrong, please try again.';
  }

  /// Recursively searches for error strings in a JSON-like object.
  static String? _findErrorInObject(dynamic obj) {
    if (obj == null) return null;

    if (obj is String) {
      // If the string itself is stringified JSON, try to parse and hunt inside
      final trimmed = obj.trim();
      if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
        try {
          return _findErrorInObject(jsonDecode(trimmed));
        } catch (_) {}
      }
      // Otherwise, return as is if non-empty
      return trimmed.isNotEmpty ? trimmed : null;
    }

    if (obj is Map) {
      // High-priority keys often used for specific error messages
      final priorityKeys = ['error', 'errors', 'message', 'msg', 'description', 'detail'];
      for (final key in priorityKeys) {
        if (obj.containsKey(key)) {
          final res = _findErrorInObject(obj[key]);
          if (res != null && res.isNotEmpty) return res;
        }
      }

      // If no priority key found a string, look at all values
      for (final value in obj.values) {
        final res = _findErrorInObject(value);
        if (res != null && res.isNotEmpty) return res;
      }
    }

    if (obj is List && obj.isNotEmpty) {
      // If it's a list, check the first item
      return _findErrorInObject(obj.first);
    }

    return null;
  }

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
          'name': name,
          'email': email,
          'phone': phoneNumber,
          'password': password,
          'role': 2,
          'pin': pin,
          'status': 'active',
          'location': location,
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

        // Handle response structure where User might be capitalized or lowercase
        // Check for "User" first as per requirement
        final userObj = jsonResponse['User'] ?? jsonResponse['user'];
        
        // Try to find token at root or inside userObj
        // In the example response, there is no root token, and internal token is empty string
        // But we should check anyway
        String token = jsonResponse['token'] ?? jsonResponse['access_token'] ?? '';
        if (token.isEmpty && userObj != null) {
          token = userObj['token'] ?? userObj['access_token'] ?? '';
        }

        if (userObj != null) {
          final userId = userObj['id']?.toString() ?? jsonResponse['id']?.toString() ?? '';
          final userEmail = userObj['email'] ?? email;
          final phone = userObj['phone'] ?? phoneNumber;
          final userName = userObj['name'] ?? name;
          
          final cardanoAddress = userObj['cardano_address'];
          final balanceAda = (userObj['balance_ada'] ?? 0.0).toDouble();
          final balanceUsda = (userObj['balance_usda'] ?? 0.0).toDouble();
          final balanceUsdaRaw = userObj['balance_usda_raw'];

          // Save what we have, even if token is empty (waiting for login)
          if (token.isNotEmpty) {
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

        throw Exception(_extractErrorMessage(response));
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

      // Re-throw as-is if it's already our parsed Exception; otherwise wrap it
      if (e is Exception) rethrow;
      throw Exception('Something went wrong, please try again.');
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
        
        // Handle various ID fields if present
        final userId = userObj?['id']?.toString() ?? jsonResponse['id']?.toString() ?? '';
        final userEmail = userObj?['email'] ?? email;
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
          final kycVerified = userObj?['kyc_verified'] ?? false;

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
            kycVerified: kycVerified is bool ? kycVerified : false,
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

        throw Exception(_extractErrorMessage(response));
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
  /// Uses direct http.post instead of AuthenticatedHttpClient to avoid
  /// auto-logout on 401 responses (which may be "wrong PIN" not "token expired").
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

      // Use direct http.post — NOT AuthenticatedHttpClient — so we can
      // distinguish "wrong PIN" 401 from "token expired" 401 without the
      // client auto-logging the user out.
      final response = await http.post(
        Uri.parse(ApiConstants.verifyPinEndpoint),
        headers: headers,
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
      } else if (response.statusCode == 401) {
        // Parse the response body to distinguish wrong PIN from token expiry
        Map<String, dynamic>? body;
        try {
          body = jsonDecode(response.body);
        } catch (_) {}

        final errorMsg = (body?['message'] ?? body?['error'] ?? '').toString().toLowerCase();
        
        // If the body mentions PIN/incorrect/wrong, treat as wrong PIN (not token expiry)
        final isWrongPin = errorMsg.contains('pin') ||
            errorMsg.contains('incorrect') ||
            errorMsg.contains('wrong') ||
            errorMsg.contains('invalid pin');

        AppLogger.logAPIResponse(
          endpoint: ApiConstants.verifyPinEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: body ?? {'error': response.body},
        );

        if (isWrongPin) {
          // Wrong PIN — don't logout, just return false
          return false;
        }

        // Genuine token expiry — logout and throw
        await TokenService.logout();
        throw TokenExpiredException('Your session has expired. Please login again.');
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
      if (e is TokenExpiredException) {
        rethrow;
      }
      AppLogger.error(LogTags.auth, 'PIN verification failed', data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Reset user PIN
  static Future<Map<String, dynamic>> resetPin({
    required String password,
    required String newPin,
  }) async {
    final startTime = DateTime.now();

    try {
      final requestBody = {
        'password': password,
        'new_pin': newPin,
      };

      AppLogger.logAPIRequest(
        endpoint: ApiConstants.resetPinEndpoint,
        method: 'POST',
        body: {'password': '***', 'new_pin': '****'},
      );

      final response = await AuthenticatedHttpClient.post(
        Uri.parse(ApiConstants.resetPinEndpoint),
        body: jsonEncode(requestBody),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);

        AppLogger.logAPIResponse(
          endpoint: ApiConstants.resetPinEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: jsonResponse,
        );

        return {
          'success': true,
          'message': jsonResponse['message'] ?? 'PIN reset successfully',
        };
      } else if (response.statusCode == 401) {
        AppLogger.logAPIResponse(
          endpoint: ApiConstants.resetPinEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: {'error': 'Token expired'},
        );
        throw TokenExpiredException('Your session has expired. Please login again.');
      } else {
        final errorBody = jsonDecode(response.body);
        AppLogger.logAPIResponse(
          endpoint: ApiConstants.resetPinEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: {'error': response.body},
        );

        return {
          'success': false,
          'message': errorBody['message'] ?? errorBody['error'] ?? 'Failed to reset PIN',
        };
      }
    } catch (e) {
      if (e is TokenExpiredException) rethrow;

      final duration = DateTime.now().difference(startTime);
      AppLogger.error(
        LogTags.auth,
        'PIN reset failed',
        data: {
          'error': e.toString(),
          'duration_ms': duration.inMilliseconds,
        },
      );
      rethrow;
    }
  }
}

/// Exception thrown when token has expired
class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);
  
  @override
  String toString() => message;
}
