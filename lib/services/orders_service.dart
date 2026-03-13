import 'dart:convert';
import 'authenticated_http_client.dart';

class OrdersService {
  static Future<Map<String, dynamic>> approveOrder(int orderId, String pin) async {
    return _processAction(orderId, 'approve', pin);
  }

  static Future<Map<String, dynamic>> declineOrder(int orderId, String pin) async {
    return _processAction(orderId, 'decline', pin);
  }

  static Future<Map<String, dynamic>> _processAction(int orderId, String action, String pin) async {
    final response = await AuthenticatedHttpClient.post(
      Uri.parse('https://api.fusionfi.io/api/v1/bill-orders/$orderId/$action'),
      body: jsonEncode({'pin': pin}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to $action order (${response.statusCode})');
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> fetchOrders() async {
    final response = await AuthenticatedHttpClient.get(
      Uri.parse('https://api.fusionfi.io/api/v1/bill-orders/'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch orders (${response.statusCode})');
    }

    return jsonDecode(response.body);
  }
}
