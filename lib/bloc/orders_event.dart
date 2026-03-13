import 'package:equatable/equatable.dart';
import '../models/order.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

class FetchOrders extends OrdersEvent {
  const FetchOrders();
}

class ApproveOrder extends OrdersEvent {
  final Order order;
  final String? pin;
  const ApproveOrder(this.order, {this.pin});

  @override
  List<Object?> get props => [order, pin];
}

class DeclineOrder extends OrdersEvent {
  final Order order;
  final String? pin;
  const DeclineOrder(this.order, {this.pin});

  @override
  List<Object?> get props => [order, pin];
}

class StartPollingOrders extends OrdersEvent {
  const StartPollingOrders();
}

class StopPollingOrders extends OrdersEvent {
  const StopPollingOrders();
}
