import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

class TokenService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _phoneNumberKey = 'phone_number';
  static const String _userNameKey = 'user_name';

  /// Save authentication token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Get authentication token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    log('token: ${prefs.getString(_tokenKey)}');
    return prefs.getString(_tokenKey);
  }

  /// Save user ID
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  /// Get user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Save user email
  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }

  /// Get user email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// Save phone number
  static Future<void> savePhoneNumber(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneNumberKey, phoneNumber);
  }

  /// Get phone number
  static Future<String?> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneNumberKey);
  }

  /// Save user name
  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  /// Get user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout - clear all auth data
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_userNameKey);
  }

  /// Save all user data at once
  static Future<void> saveUserData({
    required String token,
    required String userId,
    required String email,
    required String phoneNumber,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    List<Future<bool>> futures = [
      prefs.setString(_tokenKey, token),
      prefs.setString(_userIdKey, userId),
      prefs.setString(_userEmailKey, email),
      prefs.setString(_phoneNumberKey, phoneNumber),
    ];
    if (name != null) {
      futures.add(prefs.setString(_userNameKey, name));
    }
    await Future.wait(futures);
  }

  /// Get all user data
  static Future<Map<String, String?>> getUserData() async {
    final token = await getToken();
    final userId = await getUserId();
    final email = await getUserEmail();
    final phoneNumber = await getPhoneNumber();

    return {
      'token': token,
      'user_id': userId,
      'email': email,
      'phone_number': phoneNumber,
    };
  }

  /// Debug method to verify stored data
  static Future<Map<String, dynamic>> debugTokenData() async {
    final token = await getToken();
    return {
      'token_exists': token != null,
      'token_not_empty': token?.isNotEmpty ?? false,
      'token_length': token?.length ?? 0,
      'token_preview': token != null ? '${token.substring(0, 20)}...' : 'null',
      'is_authenticated': await isAuthenticated(),
    };
  }
}
