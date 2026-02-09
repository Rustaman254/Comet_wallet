import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'token_service.dart';
import 'logger_service.dart';

/// HTTP client wrapper that handles token expiration
class AuthenticatedHttpClient {
  static VoidCallback? _onTokenExpired;
  
  /// Initialize with token expiration callback
  static void initialize({required VoidCallback onTokenExpired}) {
    _onTokenExpired = onTokenExpired;
  }
  
  /// Make an authenticated GET request
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final token = await TokenService.getToken();
    
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?headers,
    };
    
    final response = await http.get(url, headers: requestHeaders);
    
    _checkTokenExpiration(response);
    
    return response;
  }
  
  /// Make an authenticated POST request
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final token = await TokenService.getToken();
    
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?headers,
    };
    
    final response = await http.post(
      url,
      headers: requestHeaders,
      body: body,
    );
    
    _checkTokenExpiration(response);
    
    return response;
  }
  
  /// Make an authenticated PUT request
  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final token = await TokenService.getToken();
    
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?headers,
    };
    
    final response = await http.put(
      url,
      headers: requestHeaders,
      body: body,
    );
    
    _checkTokenExpiration(response);
    
    return response;
  }
  
  /// Make an authenticated DELETE request
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final token = await TokenService.getToken();
    
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?headers,
    };
    
    final response = await http.delete(url, headers: requestHeaders);
    
    _checkTokenExpiration(response);
    
    return response;
  }
  
  /// Check if the response indicates token expiration
  static void _checkTokenExpiration(http.Response response) {
    if (response.statusCode == 401) {
      AppLogger.warning(
        LogTags.auth,
        'Token expired - received 401 Unauthorized',
        data: {
          'status_code': response.statusCode,
          'endpoint': response.request?.url.toString(),
        },
      );
      
      // Clear the expired token
      TokenService.logout();
      
      // Trigger the callback to redirect to login
      _onTokenExpired?.call();
    }
  }
  
  /// Dispose of resources
  static void dispose() {
    _onTokenExpired = null;
  }
}
