import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/ticket.dart';
import 'authenticated_http_client.dart';
import 'logger_service.dart';

class TicketingService {
  /// Create a ticket for an authenticated user
  static Future<Ticket> createTicket({
    String? issueCategory,
    String? issueDescription,
  }) async {
    final startTime = DateTime.now();
    try {
      final requestBody = {
        if (issueCategory != null) 'issue_category': issueCategory,
        if (issueDescription != null) 'issue_description': issueDescription,
      };

      AppLogger.logAPIRequest(
        endpoint: ApiConstants.createTicketEndpoint,
        method: 'POST',
        body: requestBody,
      );

      final response = await AuthenticatedHttpClient.post(
        Uri.parse(ApiConstants.createTicketEndpoint),
        body: jsonEncode(requestBody),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        AppLogger.logAPIResponse(
          endpoint: ApiConstants.createTicketEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: jsonData,
        );
        return Ticket.fromJson(jsonData['ticket']);
      } else {
        throw Exception('Failed to create ticket: ${response.body}');
      }
    } catch (e) {
      AppLogger.error(LogTags.api, 'Error creating ticket', data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Create a ticket for a guest user
  static Future<Ticket> createGuestTicket({
    required String userEmail,
    required String issueDescription,
    String? issueCategory,
  }) async {
    final startTime = DateTime.now();
    try {
      final requestBody = {
        'user_email': userEmail,
        'issue_description': issueDescription,
        if (issueCategory != null) 'issue_category': issueCategory,
      };

      AppLogger.logAPIRequest(
        endpoint: ApiConstants.createGuestTicketEndpoint,
        method: 'POST',
        body: requestBody,
      );

      // Use basic http client for guest endpoint as it's public
      final response = await http.post(
        Uri.parse(ApiConstants.createGuestTicketEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        AppLogger.logAPIResponse(
          endpoint: ApiConstants.createGuestTicketEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: jsonData,
        );
        return Ticket.fromJson(jsonData['ticket']);
      } else {
        throw Exception('Failed to create guest ticket: ${response.body}');
      }
    } catch (e) {
      AppLogger.error(LogTags.api, 'Error creating guest ticket', data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Get all tickets for the authenticated user
  static Future<List<Ticket>> getMyTickets() async {
    final startTime = DateTime.now();
    try {
      AppLogger.logAPIRequest(
        endpoint: ApiConstants.myTicketsEndpoint,
        method: 'GET',
      );

      final response = await AuthenticatedHttpClient.get(
        Uri.parse(ApiConstants.myTicketsEndpoint),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        AppLogger.logAPIResponse(
          endpoint: ApiConstants.myTicketsEndpoint,
          method: 'GET',
          statusCode: response.statusCode,
          duration: duration,
          response: jsonData,
        );
        
        final List<dynamic> ticketsJson = jsonData['tickets'] ?? [];
        return ticketsJson.map((json) => Ticket.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch tickets: ${response.body}');
      }
    } catch (e) {
      AppLogger.error(LogTags.api, 'Error fetching user tickets', data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Get single ticket details by ID
  static Future<Ticket> getTicketById(String ticketId) async {
    final startTime = DateTime.now();
    try {
      final endpoint = ApiConstants.getTicketDetailsEndpoint(ticketId);
      AppLogger.logAPIRequest(
        endpoint: endpoint,
        method: 'GET',
      );

      final response = await AuthenticatedHttpClient.get(
        Uri.parse(endpoint),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        AppLogger.logAPIResponse(
          endpoint: endpoint,
          method: 'GET',
          statusCode: response.statusCode,
          duration: duration,
          response: jsonData,
        );
        return Ticket.fromJson(jsonData['ticket']);
      } else {
        throw Exception('Failed to fetch ticket details: ${response.body}');
      }
    } catch (e) {
      AppLogger.error(LogTags.api, 'Error fetching ticket details', data: {'error': e.toString()});
      rethrow;
    }
  }
}
