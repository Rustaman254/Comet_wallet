import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import 'token_service.dart';
import 'logger_service.dart';

class WalletService {
  /// Top up wallet with authentication token
  static Future<Map<String, dynamic>> topupWallet({
    required String phoneNumber,
    required double amount,
    required String currency,
  }) async {
    final startTime = DateTime.now();

    try {
      // Get authentication token
      final token = await TokenService.getToken();
      
      AppLogger.debug(
        LogTags.payment,
        'Token retrieval for wallet top-up',
        data: {
          'token_exists': token != null,
          'token_empty': token?.isEmpty ?? true,
          'token_length': token?.length ?? 0,
          'token_first_50_chars': token != null 
              ? token.substring(0, (token.length > 50 ? 50 : token.length)) 
              : 'N/A',
        },
      );
      
      if (token == null || token.isEmpty) {
        AppLogger.error(
          LogTags.payment,
          'No authentication token available - User not logged in',
          data: {
            'token_null': token == null,
            'token_empty': token?.isEmpty ?? true,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        throw Exception('User not authenticated. Please login first.');
      }

      final requestBody = {
        'phone_number': phoneNumber,
        'amount': amount,
        'currency': currency,
      };

      AppLogger.debug(
        LogTags.payment,
        'Wallet top-up initiated',
        data: {
          'phone_number': phoneNumber,
          'amount': amount,
          'currency': currency,
        },
      );

      AppLogger.logAPIRequest(
        endpoint: ApiConstants.walletTopupEndpoint,
        method: 'POST',
        body: requestBody,
      );

      // Prepare authorization header
      // Try with Bearer prefix first (standard JWT format)
      final authorizationHeader = 'Bearer $token';
      AppLogger.debug(
        LogTags.payment,
        'Preparing authorization header for Top Up',
        data: {
          'token_prefix': 'Bearer',
          'token_present': token.isNotEmpty,
          'token_length': token.length,
        },
      );

      final response = await http.post(
        Uri.parse(ApiConstants.walletTopupEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': authorizationHeader, // Consuming the Bearer token here
        },
        body: jsonEncode(requestBody),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);

        AppLogger.success(
          LogTags.payment,
          'Wallet top-up completed successfully',
          data: {
            'phone_number': phoneNumber,
            'amount': amount,
            'currency': currency,
            'transaction_id': jsonResponse['transaction_id'],
            'status': jsonResponse['status'],
            'message': jsonResponse['message'],
            'duration_ms': duration.inMilliseconds,
          },
        );

        return jsonResponse;
      } else {
        // Try to parse error response, handle both JSON and plain text
        Map<String, dynamic> errorResponse;
        try {
          errorResponse = jsonDecode(response.body);
        } catch (_) {
          errorResponse = {'error': response.body, 'raw_body': true};
        }

        // Log specific error based on status code
        if (response.statusCode == 401) {
          AppLogger.error(
            LogTags.payment,
            'Authentication failed - Token invalid or expired',
            data: {
              'status_code': response.statusCode,
              'error_response': errorResponse,
              'token_length': token.length,
              'duration_ms': duration.inMilliseconds,
            },
          );
        } else if (response.statusCode == 403) {
          AppLogger.error(
            LogTags.payment,
            'Authorization failed - User not permitted',
            data: {
              'status_code': response.statusCode,
              'error_response': errorResponse,
              'duration_ms': duration.inMilliseconds,
            },
          );
        } else {
          AppLogger.logAPIResponse(
            endpoint: ApiConstants.walletTopupEndpoint,
            method: 'POST',
            statusCode: response.statusCode,
            duration: duration,
            response: errorResponse,
          );
        }

        throw Exception(
          errorResponse['message'] ?? 
          errorResponse['error'] ??
          'Top-up failed with status code: ${response.statusCode}'
        );
      }
    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      AppLogger.error(
        LogTags.payment,
        'Wallet top-up error',
        data: {
          'phone_number': phoneNumber,
          'amount': amount,
          'currency': currency,
          'error': e.toString(),
          'duration_ms': duration.inMilliseconds,
        },
      );

      throw Exception('Top-up error: $e');
    }
  }

  /// Check wallet balance
  static Future<Map<String, dynamic>> getWalletBalance() async {
    try {
      final token = await TokenService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      AppLogger.debug(
        LogTags.payment,
        'Fetching wallet balance',
      );

      final response = await http.get(
        Uri.parse(ApiConstants.walletBalanceEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        AppLogger.success(
          LogTags.payment,
          'Wallet balance retrieved',
          data: {
            'balance': jsonResponse['balance'],
            'currency': jsonResponse['currency'],
          },
        );

        return jsonResponse;
      } else {
        throw Exception('Failed to fetch wallet balance');
      }
    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'Failed to fetch wallet balance',
        data: {'error': e.toString()},
      );
      throw Exception('Balance fetch error: $e');
    }
  }

  /// Get transaction history
  static Future<List<Map<String, dynamic>>> getTransactionHistory() async {
    try {
      final token = await TokenService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      AppLogger.debug(
        LogTags.payment,
        'Fetching transaction history',
      );

      final response = await http.get(
        Uri.parse(ApiConstants.walletTransactionsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final transactions = List<Map<String, dynamic>>.from(
          (jsonResponse['transactions'] as List?)?.map((t) => Map<String, dynamic>.from(t)) ?? [],
        );

        AppLogger.success(
          LogTags.payment,
          'Transaction history retrieved',
          data: {'count': transactions.length},
        );

        return transactions;
      } else {
        throw Exception('Failed to fetch transaction history');
      }
    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'Failed to fetch transaction history',
        data: {'error': e.toString()},
      );
      throw Exception('Transaction history fetch error: $e');
    }
  }
  /// Transfer funds to another wallet
  static Future<Map<String, dynamic>> transferWallet({
    required String toEmail,
    required double amount,
    required String currency,
  }) async {
    final startTime = DateTime.now();

    try {
      final token = await TokenService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final requestBody = {
        'to_email': toEmail,
        'amount': amount,
        'currency': currency,
      };

      AppLogger.logAPIRequest(
        endpoint: ApiConstants.walletTransferEndpoint,
        method: 'POST',
        body: requestBody,
      );

      final response = await http.post(
        Uri.parse(ApiConstants.walletTransferEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);

        AppLogger.success(
          LogTags.payment,
          'Wallet transfer completed successfully',
          data: {
            'to_email': toEmail,
            'amount': amount,
            'currency': currency,
            'status': jsonResponse['status'],
          },
        );

        return jsonResponse;
      } else {
        Map<String, dynamic> errorResponse;
        try {
          errorResponse = jsonDecode(response.body);
        } catch (_) {
          errorResponse = {'error': response.body};
        }

        AppLogger.logAPIResponse(
          endpoint: ApiConstants.walletTransferEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: errorResponse,
        );

        throw Exception(
          errorResponse['message'] ?? 
          errorResponse['error'] ??
          'Transfer failed with status code: ${response.statusCode}'
        );
      }
    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'Wallet transfer error',
        data: {
          'to_email': toEmail,
          'amount': amount,
          'error': e.toString(),
        },
      );
      throw Exception('Transfer error: $e');
    }
  }
}
