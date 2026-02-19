import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import 'token_service.dart';
import 'logger_service.dart';
import 'authenticated_http_client.dart';
import '../models/transaction.dart';

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

      final response = await AuthenticatedHttpClient.post(
        Uri.parse(ApiConstants.walletTopupEndpoint),
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

      final response = await AuthenticatedHttpClient.get(
        Uri.parse(ApiConstants.walletBalanceEndpoint),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // Parse wallets list
        final walletsList = (jsonResponse['wallets'] as List?)
            ?.map((w) => {
                  'id': w['ID'],
                  'user_id': w['user_id'],
                  'currency': w['currency'],
                  'balance': (w['balance'] ?? 0).toDouble(),
                  'created_at': w['CreatedAt'],
                  'updated_at': w['UpdatedAt'],
                })
            .toList() ?? [];
        
        // Parse balances map
        final balancesMap = jsonResponse['balances'] as Map<String, dynamic>? ?? {};
        
        // Get primary balance (first wallet or first balance)
        double primaryBalance = 0.0;
        String primaryCurrency = 'USD';
        
        if (walletsList.isNotEmpty) {
          primaryBalance = walletsList[0]['balance'] as double;
          primaryCurrency = walletsList[0]['currency'] as String;
        } else if (balancesMap.isNotEmpty) {
          primaryCurrency = balancesMap.keys.first;
          primaryBalance = (balancesMap[primaryCurrency] ?? 0).toDouble();
        }

        AppLogger.success(
          LogTags.payment,
          'Wallet balance retrieved',
          data: {
            'wallets_count': walletsList.length,
            'currencies_count': balancesMap.length,
            'primary_balance': primaryBalance,
            'primary_currency': primaryCurrency,
          },
        );

        return {
          'balance': primaryBalance,
          'currency': primaryCurrency,
          'wallets': walletsList,
          'balances': balancesMap,
          'user_id': jsonResponse['user_id'],
          'status': jsonResponse['status'],
        };
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

      final response = await AuthenticatedHttpClient.get(
        Uri.parse(ApiConstants.walletTransactionsEndpoint),
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

  /// Get simplified transaction list from the new endpoint
  static Future<List<Transaction>> fetchTransactionsList() async {
    try {
      final token = await TokenService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      AppLogger.debug(
        LogTags.payment,
        'Fetching transactions list from new endpoint',
      );

      final response = await AuthenticatedHttpClient.get(
        Uri.parse(ApiConstants.transactionsListEndpoint),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final transactionResponse = TransactionResponse.fromJson(jsonResponse);

        AppLogger.success(
          LogTags.payment,
          'Transactions list fetched successfully',
          data: {'count': transactionResponse.transactions.length},
        );

        return transactionResponse.transactions;
      } else {
        AppLogger.error(
          LogTags.payment,
          'Failed to fetch transactions list',
          data: {
            'status_code': response.statusCode,
            'body': response.body,
          },
        );
        throw Exception('Failed to fetch transactions list: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'Failed to fetch transactions list',
        data: {'error': e.toString()},
      );
      throw Exception('Transactions list fetch error: $e');
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

      final response = await AuthenticatedHttpClient.post(
        Uri.parse(ApiConstants.walletTransferEndpoint),
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
            'recipient': jsonResponse['user']?['name'] ?? 'Unknown',
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

  /// Create a payment link for receiving money
  static Future<Map<String, dynamic>> createPaymentLink({
    required double amount,
    required String currency,
    required String description,
  }) async {
    final startTime = DateTime.now();

    try {
      final token = await TokenService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final requestBody = {
        'amount': amount,
        'currency': currency,
        'description': description,
      };

      AppLogger.logAPIRequest(
        endpoint: ApiConstants.paymentLinksEndpoint,
        method: 'POST',
        body: requestBody,
      );

      final response = await AuthenticatedHttpClient.post(
        Uri.parse(ApiConstants.paymentLinksEndpoint),
        body: jsonEncode(requestBody),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);

        AppLogger.success(
          LogTags.payment,
          'Payment link created successfully',
          data: {
            'amount': amount,
            'currency': currency,
            'token': jsonResponse['token'],
            'payment_url': jsonResponse['payment_url'],
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
          endpoint: ApiConstants.paymentLinksEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: errorResponse,
        );

        throw Exception(
          errorResponse['message'] ?? 
          errorResponse['error'] ??
          'Failed to create payment link: ${response.statusCode}'
        );
      }
    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'Payment link creation error',
        data: {'error': e.toString()},
      );
      throw Exception('Payment link error: $e');
    }
  }

  /// Send money to a mobile number (M-Pesa withdrawal)
  static Future<Map<String, dynamic>> sendMoney({
    required String recipientPhone,
    required double amount,
    required String currency,
    required String description,
  }) async {
    final startTime = DateTime.now();

    try {
      final token = await TokenService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final formattedPhone = recipientPhone.startsWith('+') 
          ? recipientPhone.substring(1) 
          : recipientPhone;

      final requestBody = {
        'recipient_phone': formattedPhone,
        'amount': amount,
        'currency': currency,
        'description': description,
      };

      AppLogger.logAPIRequest(
        endpoint: ApiConstants.walletSendMoneyEndpoint,
        method: 'POST',
        body: requestBody,
      );

      final response = await AuthenticatedHttpClient.post(
        Uri.parse(ApiConstants.walletSendMoneyEndpoint),
        body: jsonEncode(requestBody),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);

        AppLogger.success(
          LogTags.payment,
          'Money transfer initiated successfully',
          data: {
            'recipient_phone': recipientPhone,
            'amount': amount,
            'transaction_id': jsonResponse['transaction_id'],
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
          endpoint: ApiConstants.walletSendMoneyEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: errorResponse,
        );

        // Provide user-friendly error messages
        String errorMessage;
        if (errorResponse['error'] == 'Insufficient balance') {
          final currentBalance = errorResponse['current_balance'] ?? 0;
          final requiredAmount = errorResponse['required_amount'] ?? amount;
          final currency = errorResponse['currency'] ?? 'KES';
          errorMessage = 'Insufficient balance. You have $currentBalance $currency but need $requiredAmount $currency.';
        } else {
          errorMessage = errorResponse['details'] ?? 
                        errorResponse['message'] ?? 
                        errorResponse['error'] ??
                        'Money transfer failed: ${response.statusCode}';
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'Send money error',
        data: {'error': e.toString()},
      );
      throw Exception('Send money error: $e');
    }
  }

  /// Get payment link details from a token
  static Future<Map<String, dynamic>> getPaymentLinkDetails(String token) async {
    final startTime = DateTime.now();

    try {
      final authToken = await TokenService.getToken();
      if (authToken == null || authToken.isEmpty) {
        throw Exception('User not authenticated');
      }

      AppLogger.debug(
        LogTags.payment,
        'Fetching payment link details',
        data: {'token': token},
      );

      final response = await AuthenticatedHttpClient.get(
        Uri.parse('${ApiConstants.paymentLinksEndpoint}/$token'),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        AppLogger.success(
          LogTags.payment,
          'Payment link details fetched successfully',
          data: {
            'token': token,
            'amount': jsonResponse['data']?['amount'],
            'recipient': jsonResponse['data']?['user']?['email'],
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
          endpoint: '${ApiConstants.paymentLinksEndpoint}/$token',
          method: 'GET',
          statusCode: response.statusCode,
          duration: duration,
          response: errorResponse,
        );

        throw Exception(
          errorResponse['message'] ?? 
          errorResponse['error'] ??
          'Failed to fetch payment link details: ${response.statusCode}'
        );
      }
    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'Payment link details fetch error',
        data: {'error': e.toString()},
      );
      throw Exception('Payment link details error: $e');
    }
  }

  /// Swap currencies
  static Future<Map<String, dynamic>> swapCurrencies({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
  }) async {
    final startTime = DateTime.now();

    try {
      final token = await TokenService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final requestBody = {
        'from_currency': fromCurrency,
        'to_currency': toCurrency,
        'amount': amount,
      };

      AppLogger.logAPIRequest(
        endpoint: ApiConstants.walletSwapEndpoint,
        method: 'POST',
        body: requestBody,
      );

      final response = await AuthenticatedHttpClient.post(
        Uri.parse(ApiConstants.walletSwapEndpoint),
        body: jsonEncode(requestBody),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);

        AppLogger.success(
          LogTags.payment,
          'Currency swap completed successfully',
          data: {
            'from_currency': fromCurrency,
            'to_currency': toCurrency,
            'amount': amount,
            'amount_credited': jsonResponse['amount_credited'],
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
          endpoint: ApiConstants.walletSwapEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: errorResponse,
        );

        throw Exception(
          errorResponse['message'] ?? 
          errorResponse['error'] ??
          'Swap failed with status code: ${response.statusCode}'
        );
      }
    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'Currency swap error',
        data: {
          'from_currency': fromCurrency,
          'to_currency': toCurrency,
          'amount': amount,
          'error': e.toString(),
        },
      );
      throw Exception('Swap error: $e');
    }
  }


  /// Transfer USDA specific endpoint
  static Future<Map<String, dynamic>> transferUSDA({
    required String recipientAddress,
    required double amount,
  }) async {
    final startTime = DateTime.now();

    try {
      final token = await TokenService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final requestBody = {
        'recipient_address': recipientAddress,
        'amount_usda_raw': amount,
      };

      AppLogger.logAPIRequest(
        endpoint: ApiConstants.walletTransferUsdaEndpoint,
        method: 'POST',
        body: requestBody,
      );

      final response = await AuthenticatedHttpClient.post(
        Uri.parse(ApiConstants.walletTransferUsdaEndpoint),
        body: jsonEncode(requestBody),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);

        AppLogger.success(
          LogTags.payment,
          'USDA transfer completed successfully',
          data: {
            'recipient_address': recipientAddress,
            'amount': amount,
            'response': jsonResponse,
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
          endpoint: ApiConstants.walletTransferUsdaEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: errorResponse,
        );

        throw Exception(
          errorResponse['message'] ?? 
          errorResponse['error'] ??
          'USDA Transfer failed: ${response.statusCode}'
        );
      }
    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'USDA transfer error',
        data: {'error': e.toString()},
      );
      throw Exception('USDA Transfer error: $e');
    }
  }
}
