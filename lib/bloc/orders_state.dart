import 'package:equatable/equatable.dart';
import '../models/order.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<Order> orders;
  final bool isProcessingAction;

  const OrdersLoaded({
    required this.orders,
    this.isProcessingAction = false,
  });

  OrdersLoaded copyWith({
    List<Order>? orders,
    bool? isProcessingAction,
  }) {
    return OrdersLoaded(
      orders: orders ?? this.orders,
      isProcessingAction: isProcessingAction ?? this.isProcessingAction,
    );
  }

  @override
  List<Object?> get props => [orders, isProcessingAction];
}

class OrdersError extends OrdersState {
  final String message;
  const OrdersError(this.message);

  @override
  List<Object?> get props => [message];
}

// Action States
class OrderActionSuccess extends OrdersState {
  final String message;
  final List<Order> currentOrders;
  const OrderActionSuccess(this.message, this.currentOrders);

  @override
  List<Object?> get props => [message, currentOrders];
}

class OrderActionFailure extends OrdersState {
  final String message;
  final List<Order> currentOrders;
  const OrderActionFailure(this.message, this.currentOrders);

  @override
  List<Object?> get props => [message, currentOrders];
}
