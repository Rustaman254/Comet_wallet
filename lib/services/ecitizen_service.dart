import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ecitizen_bill.dart';
import 'logger_service.dart';

class ECitizenService {
  static const String _validateEndpoint = 'https://ecitizen.mam-laka.com/api.php/validate';

  /// Validate eCitizen bill details
  static Future<ECitizenBill?> validateBill({
    required String refNo,
    String currency = 'KES',
    double amount = 0,
  }) async {
    final startTime = DateTime.now();
    
    try {
      final requestBody = {
        "ref_no": refNo,
        "currency": currency,
        "amount": amount,
      };

      AppLogger.debug(
        LogTags.payment,
        'Validating eCitizen bill',
        data: requestBody,
      );

      final response = await http.post(
        Uri.parse(_validateEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // Check if status is "200" string as per example response
        if (jsonResponse['status'] == "200" && jsonResponse['data'] != null) {
          AppLogger.success(
            LogTags.payment,
            'eCitizen bill validated',
            data: jsonResponse['data'],
          );
          
          return ECitizenBill.fromJson(jsonResponse['data'], refNo);
        } else {
           AppLogger.error(
            LogTags.payment,
            'eCitizen validation failed logic',
            data: jsonResponse,
          );
          throw Exception(jsonResponse['desc'] ?? 'Bill validation failed');
        }
      } else {
        AppLogger.error(
          LogTags.payment,
          'eCitizen validation HTTP error',
          data: {'status_code': response.statusCode, 'body': response.body},
        );
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'eCitizen validation exception',
        data: {'error': e.toString()},
      );
      throw Exception('Connection failed: $e');
    }
  }

  /// Confirm eCitizen payment
  static Future<Map<String, dynamic>> confirmPayment({
    required String refNo,
    required double amount,
    required String currency,
    required String transactionId,
  }) async {
    final startTime = DateTime.now();
    const String confirmEndpoint = 'https://ecitizen.mam-laka.com/api.php/confirm';

    try {
      final requestBody = {
        "ref_no": refNo,
        "amount": amount,
        "currency": currency,
        "gateway_transaction_id": transactionId,
      };

      AppLogger.debug(
        LogTags.payment,
        'Confirming eCitizen payment',
        data: requestBody,
      );

      final response = await http.post(
        Uri.parse(confirmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        AppLogger.success(
          LogTags.payment,
          'eCitizen payment confirmed',
          data: jsonResponse,
        );
        return jsonResponse;
      } else {
        AppLogger.error(
          LogTags.payment,
          'eCitizen confirmation HTTP error',
          data: {'status_code': response.statusCode, 'body': response.body},
        );
        throw Exception('Confirmation failed: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'eCitizen confirmation exception',
        data: {'error': e.toString()},
      );
      throw Exception('Confirmation error: $e');
    }
  }
}
