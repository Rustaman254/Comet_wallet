import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'wallet_service.dart';
import 'logger_service.dart';

class WalletProvider extends ChangeNotifier {
  // Singleton instance
  static final WalletProvider _instance = WalletProvider._internal();
  static WalletProvider get instance => _instance;

  WalletProvider._internal();

  // State
  bool _isLoading = false;
  List<Map<String, dynamic>> _balances = [];
  List<Transaction> _transactions = [];
  String _error = '';

  // Getters
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get balances => _balances;
  List<Transaction> get transactions => _transactions;
  String get error => _error;

  // Actions
  Future<void> fetchData() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Run both fetches in parallel
      final results = await Future.wait([
        WalletService.getWalletBalance(),
        WalletService.fetchTransactionsList(),
      ]);

      final balanceData = results[0] as Map<String, dynamic>;
      final transactionsList = results[1] as List<Transaction>;

      // Format balance for UI
      // The API returns a single balance, but our UI supports multiple cards.
      // We will maintain the structure the UI expects.
      final currency = balanceData['currency'] as String? ?? 'KES';
      final amount = balanceData['balance']?.toString() ?? '0.00';
      
      // Check if we already have this currency
      final existingIndex = _balances.indexWhere((b) => b['currency'] == currency);
      
      if (existingIndex != -1) {
        _balances[existingIndex] = {
          'currency': currency,
          'amount': amount,
          'date': _balances[existingIndex]['date'], // Keep existing date or update
          'change': _balances[existingIndex]['change'], // Keep existing change or update
        };
      } else {
        _balances = [
          {
            'currency': currency,
            'amount': amount,
            'date': 'Today',
            'change': '+0.00',
          }
        ];
      }
      
      _transactions = transactionsList;
      
    } catch (e) {
      _error = e.toString();
      AppLogger.error(LogTags.payment, 'Error fetching wallet data', data: {'error': e.toString()});
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateBalance(double newAmount, String currency) {
    final index = _balances.indexWhere((b) => b['currency'] == currency);
    if (index != -1) {
      _balances[index]['amount'] = newAmount.toString();
      notifyListeners();
    }
  }
}
