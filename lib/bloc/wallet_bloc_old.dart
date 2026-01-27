import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/transaction.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc() : super(const WalletInitial()) {
    on<FetchWalletData>(_onFetchWalletData);
    on<TopUpWallet>(_onTopUpWallet);
    on<SendMoney>(_onSendMoney);
    on<UpdateBalance>(_onUpdateBalance);
    on<AddTransaction>(_onAddTransaction);
    on<RefreshWallet>(_onRefreshWallet);
  }

  Future<void> _onFetchWalletData(
    FetchWalletData event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    try {
      // Initialize with empty data - real data will come from API calls
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

  Future<void> _onTopUpWallet(
    TopUpWallet event,
    Emitter<WalletState> emit,
  ) async {
    if (state is! WalletLoaded) return;

    final currentState = state as WalletLoaded;

    try {
      // Create transaction record
      final newTransaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: event.amount,
        transactionType: 'wallet_topup',
        status: 'complete',
        phoneNumber: '',
        timestamp: DateTime.now(),
      );

      // Update balances
      final updatedBalances = currentState.balances.map((balance) {
        if (balance['currency'] == event.currency) {
          return {
            ...balance,
            'amount': (balance['amount'] as double) + event.amount,
          };
        }
        return balance;
      }).toList();

      // If no matching currency found, add new one
      if (!updatedBalances.any((b) => b['currency'] == event.currency)) {
        updatedBalances.add({
          'currency': event.currency,
          'amount': event.amount,
          'date': 'Today',
          'change': '+${event.amount}',
        });
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
    } catch (e) {
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
      // Create transaction record
      final newTransaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: event.amount,
        transactionType: event.transactionType,
        status: 'complete',
        phoneNumber: event.recipientPhone,
        timestamp: DateTime.now(),
      );

      // Update balances (deduct from first available balance)
      final updatedBalances = <Map<String, dynamic>>[];
      bool deducted = false;

      for (var balance in currentState.balances) {
        if (!deducted && (balance['amount'] as double) >= event.amount) {
          updatedBalances.add({
            ...balance,
            'amount': (balance['amount'] as double) - event.amount,
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
    } catch (e) {
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
            'amount': event.amount,
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
    emit(const WalletLoading());
    try {
      // Refresh with current data
      if (state is WalletLoaded) {
        final currentState = state as WalletLoaded;
        emit(WalletLoaded(
          balances: currentState.balances,
          transactions: currentState.transactions,
          totalIncome: currentState.totalIncome,
          totalExpense: currentState.totalExpense,
          pendingCount: currentState.pendingCount,
          completedCount: currentState.completedCount,
        ));
      } else {
        emit(const WalletLoaded(
          balances: [],
          transactions: [],
          totalIncome: 0.0,
          totalExpense: 0.0,
          pendingCount: 0,
          completedCount: 0,
        ));
      }
    } catch (e) {
      emit(WalletError(message: 'Failed to refresh wallet: $e'));
    }
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
}
