import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'authenticated_http_client.dart';
import 'logger_service.dart';

class ForexService {
  /// Fetches the exchange rate for a specific currency pair.
  /// Uses AuthenticatedHttpClient for the primary endpoint and falls back to http for the fallback endpoint.
  static Future<double> getExchangeRate(String from, String to) async {
    if (from == to) return 1.0;

    final String apiFrom = from == 'USDA' ? 'USD' : from;
    final String apiTo = to == 'USDA' ? 'USD' : to;

    if (apiFrom == apiTo) return 1.0;

    try {
      AppLogger.debug(LogTags.payment, 'Fetching exchange rate', data: {'from': apiFrom, 'to': apiTo});
      
      final url = '${ApiConstants.forexRatesEndpoint}/$apiFrom/$apiTo';
      var response = await AuthenticatedHttpClient.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        AppLogger.warning(LogTags.payment, 'Primary rate fetch failed, trying fallback', data: {'status': response.statusCode});
        final fallbackUrl = '${ApiConstants.fallbackForexRatesEndpoint}/$apiFrom/$apiTo';
        response = await http.get(
          Uri.parse(fallbackUrl),
        ).timeout(const Duration(seconds: 10));
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['status'] == 'success') {
          final rate = double.tryParse(data['rate']?.toString() ?? '');
          if (rate != null && rate > 0) {
            return rate;
          }
        }
      }
      throw Exception('Failed to fetch rate: ${response.statusCode}');
    } catch (e) {
      AppLogger.error(LogTags.payment, 'Error fetching exchange rate', data: {'error': e.toString()});
      
      // Attempt fallback one last time if primary failed with exception
      try {
        final fallbackUrl = '${ApiConstants.fallbackForexRatesEndpoint}/$apiFrom/$apiTo';
        final response = await http.get(
          Uri.parse(fallbackUrl),
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map && data['status'] == 'success') {
            final rate = double.tryParse(data['rate']?.toString() ?? '');
            if (rate != null && rate > 0) {
              return rate;
            }
          }
        }
      } catch (_) {}
      
      rethrow;
    }
  }
}
