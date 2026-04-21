import 'dart:convert';
import '../constants/api_constants.dart';
import 'authenticated_http_client.dart';
import 'logger_service.dart';
import '../models/esim_model.dart';

class ESimService {
  /// Fetch all eSIM products
  static Future<List<ESimProduct>> getProducts() async {
    try {
      AppLogger.debug(LogTags.payment, 'Fetching eSIM products');

      final response = await AuthenticatedHttpClient.get(
        Uri.parse(ApiConstants.esimProductsEndpoint),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          return (jsonResponse['data'] as List)
              .map((p) => ESimProduct.fromJson(p))
              .toList();
        }
        throw Exception(jsonResponse['message'] ?? 'Failed to fetch eSIM products');
      } else {
        throw Exception('Failed to fetch eSIM products: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error(LogTags.payment, 'eSIM products fetch error', data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Fetch a single eSIM product by ID
  static Future<ESimProduct> getProductDetails(int id) async {
    try {
      AppLogger.debug(LogTags.payment, 'Fetching eSIM product details', data: {'id': id});

      final response = await AuthenticatedHttpClient.get(
        Uri.parse(ApiConstants.getEsimProductDetailsEndpoint(id)),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          return ESimProduct.fromJson(jsonResponse['data']);
        }
        throw Exception(jsonResponse['message'] ?? 'Failed to fetch eSIM product details');
      } else {
        throw Exception('Failed to fetch eSIM product details: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error(LogTags.payment, 'eSIM product details fetch error', data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Request an eSIM order
  static Future<ESimOrderRequest> requestOrder(int planId) async {
    try {
      AppLogger.debug(LogTags.payment, 'Requesting eSIM order', data: {'plan_id': planId});

      final response = await AuthenticatedHttpClient.post(
        Uri.parse(ApiConstants.esimOrderRequestEndpoint),
        body: jsonEncode({'plan_id': planId}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          return ESimOrderRequest.fromJson(jsonResponse['data']);
        }
        throw Exception(jsonResponse['message'] ?? 'Failed to request eSIM order');
      } else {
        throw Exception('Failed to request eSIM order: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error(LogTags.payment, 'eSIM order request error', data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Complete an eSIM order with PIN
  static Future<ESimOrderCompleteResponse> completeOrder({
    required String orderId,
    required String pin,
  }) async {
    try {
      AppLogger.debug(LogTags.payment, 'Completing eSIM order', data: {'order_id': orderId});

      final response = await AuthenticatedHttpClient.post(
        Uri.parse(ApiConstants.esimOrderCompleteEndpoint),
        body: jsonEncode({
          'order_id': orderId,
          'pin': pin,
        }),
      );

      final jsonResponse = jsonDecode(response.body);
      return ESimOrderCompleteResponse.fromJson(jsonResponse);
    } catch (e) {
      AppLogger.error(LogTags.payment, 'eSIM order completion error', data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Delete ownership
  static Future<void> deleteOwnership(int id) async {
    try {
      AppLogger.debug(LogTags.payment, 'Deleting ownership', data: {'id': id});

      final response = await AuthenticatedHttpClient.post(
        Uri.parse(ApiConstants.getOwnershipDeleteEndpoint(id)),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(jsonResponse['message'] ?? 'Failed to delete ownership');
      }
    } catch (e) {
      AppLogger.error(LogTags.payment, 'Ownership deletion error', data: {'error': e.toString()});
      rethrow;
    }
  }
}
