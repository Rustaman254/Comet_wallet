import 'dart:convert';
import '../constants/api_constants.dart';
import 'authenticated_http_client.dart';
import 'token_service.dart';
import 'logger_service.dart';

/// Service for Sumsub KYC backend interactions.
/// All Sumsub API calls go through our backend — never directly from Flutter.
class SumsubKycService {
  /// Initialize KYC: creates or retrieves the Sumsub applicant and returns
  /// an SDK access token.
  ///
  /// Response shape:
  /// ```json
  /// { "applicantId": "...", "token": "...", "userId": "..." }
  /// ```
  static Future<Map<String, dynamic>> initKyc() async {
    final startTime = DateTime.now();
    final endpoint = ApiConstants.sumsubInitKycEndpoint;

    // Get userId for the request body
    final userId = await TokenService.getUserId() ?? '';

    try {
      final requestBody = {
        "userId": userId,
      };

      AppLogger.logAPIRequest(
        endpoint: endpoint,
        method: 'POST',
        body: requestBody,
      );

      final response = await AuthenticatedHttpClient.post(
        Uri.parse(endpoint),
        body: jsonEncode(requestBody),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

        AppLogger.logAPIResponse(
          endpoint: endpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: jsonResponse,
        );

        return jsonResponse;
      } else {
        AppLogger.error(
          LogTags.kyc,
          'Sumsub init-kyc failed',
          data: {
            'status_code': response.statusCode,
            'response_body': response.body,
            'duration_ms': duration.inMilliseconds,
          },
        );
        throw Exception(
          'Sumsub init-kyc failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      AppLogger.error(
        LogTags.kyc,
        'Sumsub init-kyc error',
        data: {
          'error': e.toString(),
          'duration_ms': DateTime.now().difference(startTime).inMilliseconds,
        },
      );
      rethrow;
    }
  }

  /// Fetch the current KYC review status from the backend.
  ///
  /// Response shape (example):
  /// ```json
  /// { "status": "completed" }
  /// ```
  static Future<Map<String, dynamic>> getKycStatus() async {
    final startTime = DateTime.now();
    
    // Get userId from TokenService
    final userId = await TokenService.getUserId() ?? '';
    if (userId.isEmpty) {
      throw Exception('User ID not found in TokenService');
    }
    
    final endpoint = ApiConstants.sumsubKycStatusEndpoint;

    try {
      AppLogger.logAPIRequest(
        endpoint: endpoint,
        method: 'GET',
        body: null,
      );

      final response = await AuthenticatedHttpClient.get(
        Uri.parse(endpoint),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

        AppLogger.logAPIResponse(
          endpoint: endpoint,
          method: 'GET',
          statusCode: response.statusCode,
          duration: duration,
          response: jsonResponse,
        );

        return jsonResponse;
      } else {
        AppLogger.error(
          LogTags.kyc,
          'Sumsub kyc-status failed',
          data: {
            'status_code': response.statusCode,
            'response_body': response.body,
            'duration_ms': duration.inMilliseconds,
          },
        );
        throw Exception(
          'Sumsub kyc-status failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      AppLogger.error(
        LogTags.kyc,
        'Sumsub kyc-status error',
        data: {
          'error': e.toString(),
          'duration_ms': DateTime.now().difference(startTime).inMilliseconds,
        },
      );
      rethrow;
    }
  }
}
