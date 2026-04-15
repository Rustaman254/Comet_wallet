import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/transaction.dart';
import '../services/wallet_service.dart';
import '../services/logger_service.dart';
import '../services/token_service.dart';
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
    on<FetchSupportedCurrencies>(_onFetchSupportedCurrencies);
    on<TillPayment>(_onTillPayment);
    on<BankTransfer>(_onBankTransfer);
    
    // Initial fetch
    add(const FetchSupportedCurrencies());
  }

  Future<void> _onFetchSupportedCurrencies(
    FetchSupportedCurrencies event,
    Emitter<WalletState> emit,
  ) async {
    try {
      final currencies = await WalletService.fetchSupportedCurrencies();
      
      if (state is WalletLoaded) {
        emit((state as WalletLoaded).copyWith(supportedCurrencies: currencies));
      } else if (state is WalletBalanceUpdated) {
        final s = state as WalletBalanceUpdated;
        emit(WalletLoaded(
          balances: s.balances,
          transactions: s.transactions,
          supportedCurrencies: currencies,
          totalIncome: s.totalIncome,
          totalExpense: s.totalExpense,
          pendingCount: s.pendingCount,
          completedCount: s.completedCount,
        ));
      }
    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'Failed to fetch currencies in BLoC',
        data: {'error': e.toString()},
      );
      // We don't emit error state here as we want to keep the main wallet state 
      // and maybe fall back to hardcoded currencies if needed in the UI.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Immediately fetch fresh data on resume (don't wait for timer)
      // We check for token inside the handlers or before adding events if possible
      TokenService.isAuthenticated().then((hasToken) {
        if (hasToken) {
          add(const FetchWalletDataFromServer());
          add(const StartAutoRefresh());
        }
      });
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
    // Keep track of current balances and transactions in case of error
    List<Map<String, dynamic>> currentBalances = [];
    List<Transaction> currentTransactions = [];
    double currentIncome = 0.0;
    double currentExpense = 0.0;
    int currentPending = 0;
    int currentCompleted = 0;
    List<Map<String, String>> currentSupportedCurrencies = [];
    
    if (state is WalletLoaded) {
      final s = state as WalletLoaded;
      currentBalances = s.balances;
      currentTransactions = s.transactions;
      currentIncome = s.totalIncome;
      currentExpense = s.totalExpense;
      currentPending = s.pendingCount;
      currentCompleted = s.completedCount;
      currentSupportedCurrencies = s.supportedCurrencies ?? [];
    } else if (state is WalletBalanceUpdated) {
      final s = state as WalletBalanceUpdated;
      currentBalances = s.balances;
      currentTransactions = s.transactions;
      currentIncome = s.totalIncome;
      currentExpense = s.totalExpense;
      currentPending = s.pendingCount;
      currentCompleted = s.completedCount;
      currentSupportedCurrencies = s.supportedCurrencies ?? [];
    }

    // Don't show loading if we already have data (for auto-refresh)
    final shouldShowLoading = currentBalances.isEmpty;
    
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
      
      // Use a Set to keep track of added currencies to avoid duplicates
      final addedCurrencies = <String>{};
      final balances = <Map<String, dynamic>>[];

      // 1. First, process the balances map (this is our primary source of truth as per requirements)
      if (balancesMap.isNotEmpty) {
        balancesMap.forEach((currency, balance) {
          if (!addedCurrencies.contains(currency)) {
            balances.add({
              'currency': currency,
              'symbol': _getCurrencySymbol(currency),
              'amount': balance?.toString() ?? '0.00',
              'date': 'Today',
              'change': '+0.00',
            });
            addedCurrencies.add(currency);
          }
        });
      }

      // 2. Then, add any additional info from wallets list if not already present
      // (Though balances map should cover all, wallets list might have more metadata if needed later)
      if (walletsList.isNotEmpty) {
        for (var wallet in walletsList) {
          final currency = wallet['currency'] as String? ?? 'USD';
          final balance = wallet['balance']?.toString() ?? '0.00';
          
          if (!addedCurrencies.contains(currency)) {
            balances.add({
              'currency': currency,
              'symbol': _getCurrencySymbol(currency),
              'amount': balance,
              'date': 'Today',
              'change': '+0.00',
            });
            addedCurrencies.add(currency);
          } else {
            // If already present, we trust the balances map more, 
            // but we could update if wallets list is more specific.
            // For now, as per user request, we stick to the balances map.
          }
        }
      }

      // Fallback if absolutely nothing
      if (balances.isEmpty) {
        balances.add({
          'currency': 'USD',
          'symbol': 'USD',
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
        supportedCurrencies: currentSupportedCurrencies,
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
      
      // Emit error but KEEP old data if available
      if (currentBalances.isNotEmpty) {
        emit(WalletLoaded(
          balances: currentBalances,
          transactions: currentTransactions,
          supportedCurrencies: currentSupportedCurrencies,
          totalIncome: currentIncome,
          totalExpense: currentExpense,
          pendingCount: currentPending,
          completedCount: currentCompleted,
        ));
        // Don't emit WalletError after re-emitting valid data —
        // this would wipe the balance from the UI state.
      } else {
        emit(WalletError(message: 'Failed to fetch wallet data: $e'));
      }
    }
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return 'USD';
      case 'EUR':
        return 'EUR';
      case 'GBP':
        return 'GBP';
      case 'KES':
        return 'KSH';
      case 'UGX':
        return 'USh';
      case 'TZS':
        return 'TSH ';
      case 'RWF':
        return 'FRW';
      case 'ZAR':
        return 'ZAR';
      case 'USDA':
        return 'USDA';
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
        createdAt: timestamp,
        currency: event.currency,
        transactionId: 'TOPUP-${timestamp.millisecondsSinceEpoch}',
      );

      final updatedTransactions = [newTransaction, ...currentState.transactions];
      final summaries = _calculateSummaries(updatedTransactions);

      emit(WalletBalanceUpdated(
        balances: updatedBalances,
        transactions: updatedTransactions,
        supportedCurrencies: currentState.supportedCurrencies,
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
        createdAt: timestamp,
        currency: event.currency,
        transactionId: 'SEND-${timestamp.millisecondsSinceEpoch}',
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
        supportedCurrencies: currentState.supportedCurrencies,
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
      final updatedBalances = List<Map<String, dynamic>>.from(currentState.balances);
      bool found = false;
      
      for (int i = 0; i < updatedBalances.length; i++) {
        if (updatedBalances[i]['currency'] == event.currency) {
          updatedBalances[i] = {
            ...updatedBalances[i],
            'amount': event.amount.toString(),
          };
          found = true;
          break;
        }
      }

      if (!found) {
        updatedBalances.add({
          'currency': event.currency,
          'symbol': _getCurrencySymbol(event.currency),
          'amount': event.amount.toString(),
          'date': 'Today',
          'change': '+0.00',
        });
      }

      final summaries = _calculateSummaries(currentState.transactions);

      emit(WalletBalanceUpdated(
        balances: updatedBalances,
        transactions: currentState.transactions,
        supportedCurrencies: currentState.supportedCurrencies,
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
        supportedCurrencies: currentState.supportedCurrencies,
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
      (_) async {
        final hasToken = await TokenService.isAuthenticated();
        if (hasToken) {
          AppLogger.debug(
            LogTags.payment,
            'Auto-refresh triggered',
          );
          add(const FetchWalletDataFromServer());
        } else {
          add(const StopAutoRefresh());
        }
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
          tx.transactionType.contains('buy') ||
          tx.transactionType.contains('till_payment')) {
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
    final balances = state is WalletLoaded ? (state as WalletLoaded).balances : <Map<String, dynamic>>[];
    emit(WalletSwapLoading(balances: balances));

    try {
      final result = await WalletService.swapCurrencies(
        fromCurrency: event.fromCurrency,
        toCurrency: event.toCurrency,
        amount: event.amount,
      );

      if (result['status'] == 'success') {
        // Extract actual balances from the API response exactly as returned
        final double balanceUsda = double.tryParse(result['balance_usda']?.toString() ?? '0') ?? 0.0;
        final Map<String, double> balancesMap = {};
        
        if (result['balances'] is Map) {
          (result['balances'] as Map).forEach((key, value) {
            balancesMap[key.toString()] = double.tryParse(value.toString()) ?? 0.0;
          });
        }
        
        // Also include USDA in the balances map if it's not there
        if (!balancesMap.containsKey('USDA')) {
          balancesMap['USDA'] = balanceUsda;
        }

        emit(WalletSwapSuccess(
          message: result['message'] ?? 'Swap successful',
          amountCredited: double.tryParse((result['amount_usda'] ?? result['amount_credited'] ?? result['amount_debited'] ?? 0).toString()) ?? 0.0,
          fromCurrency: result['from_currency'] ?? event.fromCurrency,
          toCurrency: result['to_currency'] ?? event.toCurrency,
          balanceUsda: balanceUsda,
          balances: balancesMap,
          txId: result['tx_id'],
          explorerLink: result['explorer_link'],
        ));
        
        // Fetch fresh data from server to sync all other states
        add(const FetchWalletDataFromServer());
      } else {
        emit(WalletError(message: result['message'] ?? 'Swap failed'));
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      if (errorMessage.startsWith('Swap error: ')) {
        errorMessage = errorMessage.replaceFirst('Swap error: ', '');
      }
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      
      AppLogger.error(
        LogTags.payment,
        'Swap failed in BLoC',
        data: {'error': errorMessage},
      );

      // Re-emit previous loaded state to preserve balances before emitting error.
      // Without this, WalletError state has no balance data and
      // the swap screen shows 0 balance / "Insufficient balance" on retry.
      if (balances.isNotEmpty) {
        emit(WalletLoaded(
          balances: balances,
          transactions: state is WalletLoaded ? (state as WalletLoaded).transactions : <Transaction>[],
          supportedCurrencies: state is WalletLoaded ? (state as WalletLoaded).supportedCurrencies : <Map<String, String>>[],
          totalIncome: state is WalletLoaded ? (state as WalletLoaded).totalIncome : 0.0,
          totalExpense: state is WalletLoaded ? (state as WalletLoaded).totalExpense : 0.0,
          pendingCount: state is WalletLoaded ? (state as WalletLoaded).pendingCount : 0,
          completedCount: state is WalletLoaded ? (state as WalletLoaded).completedCount : 0,
        ));
      }

      emit(WalletError(message: errorMessage));
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
        createdAt: timestamp,
        currency: 'USDA',
        transactionId: result['transactionId'] ?? 'USDA-TRANSFER-${timestamp.millisecondsSinceEpoch}',
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
          supportedCurrencies: currentState.supportedCurrencies,
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

  Future<void> _onTillPayment(
    TillPayment event,
    Emitter<WalletState> emit,
  ) async {
    if (state is! WalletLoaded) return;

    final currentState = state as WalletLoaded;

    try {
      AppLogger.debug(
        LogTags.payment,
        'Processing till payment in BLoC',
        data: {
          'till_number': event.tillNumber,
          'amount': event.amount,
        },
      );

      // Optimistic update
      final updatedBalances = currentState.balances.map((balance) {
        if (balance['currency'] == 'KES') {
          final currentAmount = double.tryParse(balance['amount'].toString()) ?? 0.0;
          return {
            ...balance,
            'amount': (currentAmount - event.amount).toString(),
          };
        }
        return balance;
      }).toList();

      // Create transaction record
      final timestamp = DateTime.now();
      final newTransaction = Transaction(
        id: timestamp.millisecondsSinceEpoch,
        userID: 0,
        amount: event.amount,
        transactionType: 'till_payment',
        status: 'pending',
        phoneNumber: event.tillNumber,
        createdAt: timestamp,
        currency: 'KES',
        transactionId: 'TILL-${timestamp.millisecondsSinceEpoch}',
      );

      final updatedTransactions = [newTransaction, ...currentState.transactions];
      final summaries = _calculateSummaries(updatedTransactions);

      emit(WalletBalanceUpdated(
        balances: updatedBalances,
        transactions: updatedTransactions,
        supportedCurrencies: currentState.supportedCurrencies,
        totalIncome: summaries['income'] as double,
        totalExpense: summaries['expense'] as double,
        pendingCount: summaries['pending'] as int,
        completedCount: summaries['completed'] as int,
      ));

      // Call service
      await WalletService.tillPayment(
        tillNumber: event.tillNumber,
        amount: event.amount,
        narration: event.narration,
        pin: event.pin,
      );

      // Fetch fresh data from server to sync
      add(const FetchWalletDataFromServer());
    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'Till payment failed in BLoC',
        data: {'error': e.toString()},
      );
      emit(WalletError(message: 'Till payment failed: $e'));
      
      // Re-fetch data to restore balance if optimistic update failed
      add(const FetchWalletDataFromServer());
    }
  }

  Future<void> _onBankTransfer(
    BankTransfer event,
    Emitter<WalletState> emit,
  ) async {
    if (state is! WalletLoaded) return;

    final currentState = state as WalletLoaded;

    try {
      AppLogger.debug(
        LogTags.payment,
        'Processing bank transfer in BLoC',
        data: {
          'bank_code': event.bankCode,
          'amount': event.amount,
        },
      );

      // Emit loading state for the UI to show overlay
      emit(const BankTransferLoading());

      // Optimistic update for the balances list (internal state tracking)
      final updatedBalances = currentState.balances.map((balance) {
        if (balance['currency'] == 'KES') {
          final currentAmount = double.tryParse(balance['amount'].toString()) ?? 0.0;
          return {
            ...balance,
            'amount': (currentAmount - event.amount).toString(),
          };
        }
        return balance;
      }).toList();

      // Create transaction record
      final timestamp = DateTime.now();
      final newTransaction = Transaction(
        id: timestamp.millisecondsSinceEpoch,
        userID: 0,
        amount: event.amount,
        transactionType: 'bank_transfer',
        status: 'pending',
        phoneNumber: event.creditAccount,
        createdAt: timestamp,
        currency: 'KES',
        transactionId: 'BANK-${timestamp.millisecondsSinceEpoch}',
      );

      final updatedTransactions = [newTransaction, ...currentState.transactions];
      final summaries = _calculateSummaries(updatedTransactions);

      // We don't emit WalletBalanceUpdated here because we want to stay in 
      // BankTransferLoading until the API call finishes.
      // But we prepare the data for the next state.

      // Call service
      final response = await WalletService.bankTransfer(
        amount: event.amount,
        bankCode: event.bankCode,
        creditAccount: event.creditAccount,
        narration: event.narration,
        pin: event.pin,
      );

      // Emit success state with message from API
      emit(BankTransferSuccess(
        message: response['message'] ?? 'Bank transfer initiated successfully',
        transactionId: response['transaction_id']?.toString(),
      ));

      // Refresh wallet data in background AFTER emitting success
      add(const FetchWalletDataFromServer());

      // After a short delay, return to regular loaded state with updated data
      // This is handled by FetchWalletDataFromServer above, which will emit WalletLoaded.
      
    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'Bank transfer failed in BLoC',
        data: {'error': e.toString()},
      );
      
      // Clean up "Exception: " prefix if present
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      emit(WalletError(message: errorMessage));
      
      // Re-fetch data to restore balance if optimistic update failed
      add(const FetchWalletDataFromServer());
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    return super.close();
  }
}
