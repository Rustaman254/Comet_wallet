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
  final List<Map<String, String>>? supportedCurrencies;
  final double totalIncome;
  final double totalExpense;
  final int pendingCount;
  final int completedCount;

  const WalletLoaded({
    required this.balances,
    required this.transactions,
    this.supportedCurrencies = const [],
    required this.totalIncome,
    required this.totalExpense,
    required this.pendingCount,
    required this.completedCount,
  });

  @override
  List<Object?> get props => [
    balances,
    transactions,
    supportedCurrencies ?? const [],
    totalIncome,
    totalExpense,
    pendingCount,
    completedCount,
  ];

  WalletLoaded copyWith({
    List<Map<String, dynamic>>? balances,
    List<Transaction>? transactions,
    List<Map<String, String>>? supportedCurrencies,
    double? totalIncome,
    double? totalExpense,
    int? pendingCount,
    int? completedCount,
  }) {
    return WalletLoaded(
      balances: balances ?? this.balances,
      transactions: transactions ?? this.transactions,
      supportedCurrencies: supportedCurrencies ?? this.supportedCurrencies,
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
  final List<Map<String, String>>? supportedCurrencies;
  final double totalIncome;
  final double totalExpense;
  final int pendingCount;
  final int completedCount;

  const WalletBalanceUpdated({
    required this.balances,
    required this.transactions,
    this.supportedCurrencies = const [],
    required this.totalIncome,
    required this.totalExpense,
    required this.pendingCount,
    required this.completedCount,
  });

  @override
  List<Object?> get props => [
    balances,
    transactions,
    supportedCurrencies ?? const [],
    totalIncome,
    totalExpense,
    pendingCount,
    completedCount,
  ];
}

class WalletSwapLoading extends WalletState {
  final List<Map<String, dynamic>> balances;
  const WalletSwapLoading({required this.balances});

  @override
  List<Object?> get props => [balances];
}

class WalletSwapSuccess extends WalletState {
  final String message;
  final double amountCredited;
  final String fromCurrency;
  final String toCurrency;
  final double balanceUsda;
  final Map<String, double> balances;
  final String? txId;
  final String? explorerLink;

  const WalletSwapSuccess({
    required this.message,
    required this.amountCredited,
    required this.fromCurrency,
    required this.toCurrency,
    required this.balanceUsda,
    required this.balances,
    this.txId,
    this.explorerLink,
  });

  @override
  List<Object?> get props => [message, amountCredited, fromCurrency, toCurrency, balanceUsda, balances, txId, explorerLink];
}
