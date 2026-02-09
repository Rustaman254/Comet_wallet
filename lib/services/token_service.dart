import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

class TokenService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _phoneNumberKey = 'phone_number';
  static const String _userNameKey = 'user_name';
  static const String _cardanoAddressKey = 'cardano_address';
  static const String _balanceAdaKey = 'balance_ada';
  static const String _balanceUsdaKey = 'balance_usda';
  static const String _balanceUsdaRawKey = 'balance_usda_raw';

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

  /// Save cardano address
  static Future<void> saveCardanoAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cardanoAddressKey, address);
  }

  /// Get cardano address
  static Future<String?> getCardanoAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cardanoAddressKey);
  }

  /// Save balances
  static Future<void> saveBalances({
    required double ada,
    required double usda,
    required int usdaRaw,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceAdaKey, ada);
    await prefs.setDouble(_balanceUsdaKey, usda);
    await prefs.setInt(_balanceUsdaRawKey, usdaRaw);
  }

  /// Get balances
  static Future<Map<String, dynamic>> getBalances() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'ada': prefs.getDouble(_balanceAdaKey) ?? 0.0,
      'usda': prefs.getDouble(_balanceUsdaKey) ?? 0.0,
      'usda_raw': prefs.getInt(_balanceUsdaRawKey) ?? 0,
    };
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
    await prefs.remove(_cardanoAddressKey);
    await prefs.remove(_balanceAdaKey);
    await prefs.remove(_balanceUsdaKey);
    await prefs.remove(_balanceUsdaRawKey);
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
    // Note: cardano address and balances are not saved here by default unless passed
    // But to keep signature compatible, we'll leave this as is and use specific methods or
    // update this signature if needed. The user request implies saving new fields.
    // I will update this method signature to optionally accept them.
    await Future.wait(futures);
  }

  /// Save all user data including extended fields
  static Future<void> saveExtendedUserData({
    required String token,
    required String userId,
    required String email,
    required String phoneNumber,
    String? name,
    String? cardanoAddress,
    double? balanceAda,
    double? balanceUsda,
    int? balanceUsdaRaw,
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
    if (cardanoAddress != null) {
      futures.add(prefs.setString(_cardanoAddressKey, cardanoAddress));
    }
    if (balanceAda != null) {
      futures.add(prefs.setDouble(_balanceAdaKey, balanceAda));
    }
    if (balanceUsda != null) {
      futures.add(prefs.setDouble(_balanceUsdaKey, balanceUsda));
    }
    if (balanceUsdaRaw != null) {
      futures.add(prefs.setInt(_balanceUsdaRawKey, balanceUsdaRaw));
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
