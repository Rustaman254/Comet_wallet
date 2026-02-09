import 'package:equatable/equatable.dart';
import '../models/transaction.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class FetchWalletData extends WalletEvent {
  const FetchWalletData();
}

class TopUpWallet extends WalletEvent {
  final double amount;
  final String currency;

  const TopUpWallet({
    required this.amount,
    required this.currency,
  });

  @override
  List<Object?> get props => [amount, currency];
}

class SendMoney extends WalletEvent {
  final double amount;
  final String recipientPhone;
  final String transactionType;

  const SendMoney({
    required this.amount,
    required this.recipientPhone,
    required this.transactionType,
  });

  @override
  List<Object?> get props => [amount, recipientPhone, transactionType];
}

class UpdateBalance extends WalletEvent {
  final double amount;
  final String currency;

  const UpdateBalance({
    required this.amount,
    required this.currency,
  });

  @override
  List<Object?> get props => [amount, currency];
}

class AddTransaction extends WalletEvent {
  final Transaction transaction;

  const AddTransaction({
    required this.transaction,
  });

  @override
  List<Object?> get props => [transaction];
}

class RefreshWallet extends WalletEvent {
  const RefreshWallet();
}

class FetchWalletDataFromServer extends WalletEvent {
  const FetchWalletDataFromServer();
}

class StartAutoRefresh extends WalletEvent {
  const StartAutoRefresh();
}

class StopAutoRefresh extends WalletEvent {
  const StopAutoRefresh();
}

class SwapCurrencies extends WalletEvent {
  final String fromCurrency;
  final String toCurrency;
  final double amount;

  const SwapCurrencies({
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
  });

  @override
  List<Object?> get props => [fromCurrency, toCurrency, amount];
}

class TransferUSDA extends WalletEvent {
  final String recipientAddress;
  final double amount;

  const TransferUSDA({
    required this.recipientAddress,
    required this.amount,
  });

  @override
  List<Object?> get props => [recipientAddress, amount];
}
