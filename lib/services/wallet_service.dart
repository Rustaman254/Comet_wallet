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
      if (token == null || token.isEmpty) {
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

      final response = await http.post(
        Uri.parse(ApiConstants.walletTopupEndpoint),
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

        AppLogger.logAPIResponse(
          endpoint: ApiConstants.walletTopupEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: jsonResponse,
        );

        AppLogger.success(
          LogTags.payment,
          'Wallet top-up completed successfully',
          data: {
            'phone_number': phoneNumber,
            'amount': amount,
            'currency': currency,
            'duration_ms': duration.inMilliseconds,
          },
        );

        return jsonResponse;
      } else {
        final errorResponse = jsonDecode(response.body);

        AppLogger.logAPIResponse(
          endpoint: ApiConstants.walletTopupEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: errorResponse,
        );

        throw Exception(
          errorResponse['message'] ?? 
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
        Uri.parse('${ApiConstants.baseUrl}/wallet/balance'),
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
        Uri.parse('${ApiConstants.baseUrl}/wallet/transactions'),
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
}
