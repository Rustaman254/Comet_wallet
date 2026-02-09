import 'package:equatable/equatable.dart';
import '../models/transaction.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {
  const WalletInitial();
}

class WalletLoading extends WalletState {
  const WalletLoading();
}

class WalletLoaded extends WalletState {
  final List<Map<String, dynamic>> balances;
  final List<Transaction> transactions;
  final double totalIncome;
  final double totalExpense;
  final int pendingCount;
  final int completedCount;

  const WalletLoaded({
    required this.balances,
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
    required this.pendingCount,
    required this.completedCount,
  });

  @override
  List<Object?> get props => [
    balances,
    transactions,
    totalIncome,
    totalExpense,
    pendingCount,
    completedCount,
  ];

  WalletLoaded copyWith({
    List<Map<String, dynamic>>? balances,
    List<Transaction>? transactions,
    double? totalIncome,
    double? totalExpense,
    int? pendingCount,
    int? completedCount,
  }) {
    return WalletLoaded(
      balances: balances ?? this.balances,
      transactions: transactions ?? this.transactions,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      pendingCount: pendingCount ?? this.pendingCount,
      completedCount: completedCount ?? this.completedCount,
    );
  }
}

class WalletError extends WalletState {
  final String message;

  const WalletError({required this.message});

  @override
  List<Object?> get props => [message];
}

class WalletBalanceUpdated extends WalletState {
  final List<Map<String, dynamic>> balances;
  final List<Transaction> transactions;
  final double totalIncome;
  final double totalExpense;
  final int pendingCount;
  final int completedCount;

  const WalletBalanceUpdated({
    required this.balances,
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
    required this.pendingCount,
    required this.completedCount,
  });

  @override
  List<Object?> get props => [
    balances,
    transactions,
    totalIncome,
    totalExpense,
    pendingCount,
    completedCount,
  ];
}

class WalletSwapLoading extends WalletState {
  const WalletSwapLoading();
}

class WalletSwapSuccess extends WalletState {
  final String message;
  final double amountCredited;
  final String fromCurrency;
  final String toCurrency;

  const WalletSwapSuccess({
    required this.message,
    required this.amountCredited,
    required this.fromCurrency,
    required this.toCurrency,
  });

  @override
  List<Object?> get props => [message, amountCredited, fromCurrency, toCurrency];
}
