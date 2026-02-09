import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/transaction.dart';
import '../services/wallet_service.dart';
import '../services/logger_service.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> with WidgetsBindingObserver {
  Timer? _refreshTimer;

  WalletBloc() : super(const WalletInitial()) {
    // Register as observer
    WidgetsBinding.instance.addObserver(this);
    
    on<FetchWalletData>(_onFetchWalletData);
    on<FetchWalletDataFromServer>(_onFetchWalletDataFromServer);
    on<TopUpWallet>(_onTopUpWallet);
    on<SendMoney>(_onSendMoney);
    on<UpdateBalance>(_onUpdateBalance);
    on<AddTransaction>(_onAddTransaction);
    on<RefreshWallet>(_onRefreshWallet);
    on<StartAutoRefresh>(_onStartAutoRefresh);
    on<StopAutoRefresh>(_onStopAutoRefresh);
    on<SwapCurrencies>(_onSwapCurrencies);
    on<TransferUSDA>(_onTransferUSDA);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      add(const StartAutoRefresh());
    } else if (state == AppLifecycleState.paused) {
      add(const StopAutoRefresh());
    }
  }

  Future<void> _onFetchWalletData(
    FetchWalletData event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    try {
      // Initialize with empty data
      emit(const WalletLoaded(
        balances: [],
        transactions: [],
        totalIncome: 0.0,
        totalExpense: 0.0,
        pendingCount: 0,
        completedCount: 0,
      ));
    } catch (e) {
      emit(WalletError(message: 'Failed to fetch wallet data: $e'));
    }
  }

  Future<void> _onFetchWalletDataFromServer(
    FetchWalletDataFromServer event,
    Emitter<WalletState> emit,
  ) async {
    // Don't show loading if we already have data (for auto-refresh)
    final shouldShowLoading = state is! WalletLoaded;
    
    if (shouldShowLoading) {
      emit(const WalletLoading());
    }

    try {
      AppLogger.debug(
        LogTags.payment,
        'Fetching wallet data from server',
      );

      // Fetch balance and transactions in parallel
      final results = await Future.wait([
        WalletService.getWalletBalance(),
        WalletService.fetchTransactionsList(),
      ]);

      final balanceData = results[0] as Map<String, dynamic>;
      final transactionsList = results[1] as List<Transaction>;

      // Parse wallets from the response
      final walletsList = balanceData['wallets'] as List<dynamic>? ?? [];
      final balancesMap = balanceData['balances'] as Map<String, dynamic>? ?? {};
      
      // Create balance cards for each wallet
      final balances = <Map<String, dynamic>>[];
      
      if (walletsList.isNotEmpty) {
        // Use wallets array if available
        for (var wallet in walletsList) {
          final currency = wallet['currency'] as String? ?? 'USD';
          final balance = wallet['balance']?.toString() ?? '0.00';
          
          balances.add({
            'currency': currency,
            'symbol': _getCurrencySymbol(currency),
            'amount': balance,
            'date': 'Today',
            'change': '+0.00',
          });
        }
      } else if (balancesMap.isNotEmpty) {
        // Fallback to balances map if wallets array is empty
        balancesMap.forEach((currency, balance) {
          if (balance != null && balance != 0) {
            balances.add({
              'currency': currency,
              'symbol': _getCurrencySymbol(currency),
              'amount': balance.toString(),
              'date': 'Today',
              'change': '+0.00',
            });
          }
        });
      } else {
        // Default empty balance
        balances.add({
          'currency': 'USD',
          'symbol': '\$',
          'amount': '0.00',
          'date': 'Today',
          'change': '+0.00',
        });
      }

      final summaries = _calculateSummaries(transactionsList);

      AppLogger.success(
        LogTags.payment,
        'Wallet data fetched successfully',
        data: {
          'balance_cards': balances.length,
          'transactions': transactionsList.length,
        },
      );

      emit(WalletLoaded(
        balances: balances,
        transactions: transactionsList,
        totalIncome: summaries['income']!,
        totalExpense: summaries['expense']!,
        pendingCount: summaries['pending']!.toInt(),
        completedCount: summaries['completed']!.toInt(),
      ));
    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'Error fetching wallet data',
        data: {'error': e.toString()},
      );
      emit(WalletError(message: 'Failed to fetch wallet data: $e'));
    }
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'KES':
        return 'KSH';
      case 'UGX':
        return 'USh';
      case 'TZS':
        return 'TSh';
      case 'RWF':
        return 'FRw';
      case 'ZAR':
        return 'R';
      case 'USDA':
        return '\u20B3'; // Cardano-ish symbol or just USDA
      default:
        return currency;
    }
  }


  Future<void> _onTopUpWallet(
    TopUpWallet event,
    Emitter<WalletState> emit,
  ) async {
    if (state is! WalletLoaded) return;

    final currentState = state as WalletLoaded;

    try {
      AppLogger.debug(
        LogTags.payment,
        'Processing top-up in BLoC',
        data: {
          'amount': event.amount,
          'currency': event.currency,
        },
      );

      // Optimistically update the UI
      final updatedBalances = currentState.balances.map((balance) {
        if (balance['currency'] == event.currency) {
          final currentAmount = double.tryParse(balance['amount'].toString()) ?? 0.0;
          return {
            ...balance,
            'amount': (currentAmount + event.amount).toString(),
          };
        }
        return balance;
      }).toList();

      // If no matching currency found, add new one
      if (!updatedBalances.any((b) => b['currency'] == event.currency)) {
        updatedBalances.add({
          'currency': event.currency,
          'amount': event.amount.toString(),
          'date': 'Today',
          'change': '+${event.amount}',
        });
      }

      // Create transaction record
      final timestamp = DateTime.now();
      final newTransaction = Transaction(
        id: timestamp.millisecondsSinceEpoch,
        userID: 0,
        amount: event.amount,
        transactionType: 'wallet_topup',
        status: 'complete',
        phoneNumber: '',
      );

      final updatedTransactions = [newTransaction, ...currentState.transactions];
      final summaries = _calculateSummaries(updatedTransactions);

      emit(WalletBalanceUpdated(
        balances: updatedBalances,
        transactions: updatedTransactions,
        totalIncome: summaries['income'] as double,
        totalExpense: summaries['expense'] as double,
        pendingCount: summaries['pending'] as int,
        completedCount: summaries['completed'] as int,
      ));

      // Fetch fresh data from server to sync
      add(const FetchWalletDataFromServer());
    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'Top-up failed in BLoC',
        data: {'error': e.toString()},
      );
      emit(WalletError(message: 'Top-up failed: $e'));
    }
  }

  Future<void> _onSendMoney(
    SendMoney event,
    Emitter<WalletState> emit,
  ) async {
    if (state is! WalletLoaded) return;

    final currentState = state as WalletLoaded;

    try {
      AppLogger.debug(
        LogTags.payment,
        'Processing send money in BLoC',
        data: {
          'amount': event.amount,
          'recipient': event.recipientPhone,
        },
      );

      // Create transaction record
      final timestamp = DateTime.now();
      final newTransaction = Transaction(
        id: timestamp.millisecondsSinceEpoch,
        userID: 0,
        amount: event.amount,
        transactionType: event.transactionType,
        status: 'complete',
        phoneNumber: event.recipientPhone,
      );

      // Update balances (deduct from first available balance)
      final updatedBalances = <Map<String, dynamic>>[];
      bool deducted = false;

      for (var balance in currentState.balances) {
        final currentAmount = double.tryParse(balance['amount'].toString()) ?? 0.0;
        if (!deducted && currentAmount >= event.amount) {
          updatedBalances.add({
            ...balance,
            'amount': (currentAmount - event.amount).toString(),
          });
          deducted = true;
        } else {
          updatedBalances.add(balance);
        }
      }

      final updatedTransactions = [newTransaction, ...currentState.transactions];
      final summaries = _calculateSummaries(updatedTransactions);

      emit(WalletBalanceUpdated(
        balances: updatedBalances,
        transactions: updatedTransactions,
        totalIncome: summaries['income'] as double,
        totalExpense: summaries['expense'] as double,
        pendingCount: summaries['pending'] as int,
        completedCount: summaries['completed'] as int,
      ));

      // Fetch fresh data from server to sync
      add(const FetchWalletDataFromServer());
    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'Send money failed in BLoC',
        data: {'error': e.toString()},
      );
      emit(WalletError(message: 'Send money failed: $e'));
    }
  }

  Future<void> _onUpdateBalance(
    UpdateBalance event,
    Emitter<WalletState> emit,
  ) async {
    if (state is! WalletLoaded) return;

    final currentState = state as WalletLoaded;

    try {
      final updatedBalances = currentState.balances.map((balance) {
        if (balance['currency'] == event.currency) {
          return {
            ...balance,
            'amount': event.amount.toString(),
          };
        }
        return balance;
      }).toList();

      final summaries = _calculateSummaries(currentState.transactions);

      emit(WalletBalanceUpdated(
        balances: updatedBalances,
        transactions: currentState.transactions,
        totalIncome: summaries['income'] as double,
        totalExpense: summaries['expense'] as double,
        pendingCount: summaries['pending'] as int,
        completedCount: summaries['completed'] as int,
      ));
    } catch (e) {
      emit(WalletError(message: 'Failed to update balance: $e'));
    }
  }

  Future<void> _onAddTransaction(
    AddTransaction event,
    Emitter<WalletState> emit,
  ) async {
    if (state is! WalletLoaded) return;

    final currentState = state as WalletLoaded;

    try {
      final updatedTransactions = [event.transaction, ...currentState.transactions];
      final summaries = _calculateSummaries(updatedTransactions);

      emit(WalletBalanceUpdated(
        balances: currentState.balances,
        transactions: updatedTransactions,
        totalIncome: summaries['income'] as double,
        totalExpense: summaries['expense'] as double,
        pendingCount: summaries['pending'] as int,
        completedCount: summaries['completed'] as int,
      ));
    } catch (e) {
      emit(WalletError(message: 'Failed to add transaction: $e'));
    }
  }

  Future<void> _onRefreshWallet(
    RefreshWallet event,
    Emitter<WalletState> emit,
  ) async {
    // Delegate to fetch from server
    add(const FetchWalletDataFromServer());
  }

  void _onStartAutoRefresh(
    StartAutoRefresh event,
    Emitter<WalletState> emit,
  ) {
    AppLogger.debug(
      LogTags.payment,
      'Starting auto-refresh timer',
    );

    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        AppLogger.debug(
          LogTags.payment,
          'Auto-refresh triggered',
        );
        add(const FetchWalletDataFromServer());
      },
    );
  }

  void _onStopAutoRefresh(
    StopAutoRefresh event,
    Emitter<WalletState> emit,
  ) {
    AppLogger.debug(
      LogTags.payment,
      'Stopping auto-refresh timer',
    );

    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Map<String, dynamic> _calculateSummaries(List<Transaction> transactions) {
    double income = 0.0;
    double expense = 0.0;
    int pending = 0;
    int completed = 0;

    for (var tx in transactions) {
      if (tx.transactionType.contains('topup') ||
          tx.transactionType.contains('receive') ||
          tx.transactionType.contains('deposit')) {
        income += tx.amount;
      } else if (tx.transactionType.contains('send') ||
          tx.transactionType.contains('transfer') ||
          tx.transactionType.contains('withdraw') ||
          tx.transactionType.contains('buy')) {
        expense += tx.amount;
      }

      if (tx.status.toLowerCase() == 'pending') {
        pending++;
      } else if (tx.status.toLowerCase() == 'completed' ||
          tx.status.toLowerCase() == 'success' ||
          tx.status.toLowerCase() == 'complete') {
        completed++;
      }
    }

    return {
      'income': income,
      'expense': expense,
      'pending': pending,
      'completed': completed,
    };
  }

  Future<void> _onSwapCurrencies(
    SwapCurrencies event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletSwapLoading());

    try {
      final result = await WalletService.swapCurrencies(
        fromCurrency: event.fromCurrency,
        toCurrency: event.toCurrency,
        amount: event.amount,
      );

      if (result['status'] == 'success') {
        emit(WalletSwapSuccess(
          message: result['message'] ?? 'Swap successful',
          amountCredited: (result['amount_credited'] ?? 0).toDouble(),
          fromCurrency: event.fromCurrency,
          toCurrency: event.toCurrency,
        ));
        
        // Refresh wallet data to update balances and transactions
        add(const FetchWalletDataFromServer());
      } else {
        emit(WalletError(message: result['message'] ?? 'Swap failed'));
      }
    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'Swap failed in BLoC',
        data: {'error': e.toString()},
      );
      emit(WalletError(message: 'Swap failed: $e'));
    }
  }

  Future<void> _onTransferUSDA(
    TransferUSDA event,
    Emitter<WalletState> emit,
  ) async {
    // Optimistic update not easy here as we don't know the fee or exact balance impact immediately 
    // without more complex logic, so we'll rely on server response.
    // However, we can show loading state if needed, or just let the UI handle loading.
    // For consistency with other operations, let's emit loading or handle it in UI.
    // Since UI handles loading state based on async call usually, but here we are in BLoC.
    // We can emit a specific loading state or just proceed.
    // Given the UI design likely waits for completion, we'll just process it.

    try {
      AppLogger.debug(
        LogTags.payment,
        'Processing USDA transfer in BLoC',
        data: {
          'amount': event.amount,
          'recipient': event.recipientAddress,
        },
      );

      final result = await WalletService.transferUSDA(
        recipientAddress: event.recipientAddress,
        amount: event.amount,
      );

      // Create transaction record for UI update
      final timestamp = DateTime.now();
      final newTransaction = Transaction(
        id: timestamp.millisecondsSinceEpoch,
        userID: 0,
        amount: event.amount,
        transactionType: 'transfer_usda',
        status: 'complete',
        phoneNumber: event.recipientAddress, // Using address as phone placeholder
        explorerLink: result['explorerLink'], // Assuming API returns this or we construct it
      );

      // We need to fetch fresh data to get accurate balances (fees etc)
      // But we can add the transaction to the list immediately
      if (state is WalletLoaded) {
        final currentState = state as WalletLoaded;
        final updatedTransactions = [newTransaction, ...currentState.transactions];
        final summaries = _calculateSummaries(updatedTransactions);
        
        // We might want to deduct balance optimistically if we know it's USDA
        // But let's trigger a refresh
        
        emit(WalletBalanceUpdated(
          balances: currentState.balances,
          transactions: updatedTransactions,
          totalIncome: summaries['income'] as double,
          totalExpense: summaries['expense'] as double,
          pendingCount: summaries['pending'] as int,
          completedCount: summaries['completed'] as int,
        ));
      }

      // Sync with server
      add(const FetchWalletDataFromServer());

    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'USDA Transfer failed in BLoC',
        data: {'error': e.toString()},
      );
      emit(WalletError(message: 'USDA Transfer failed: $e'));
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    return super.close();
  }
}
