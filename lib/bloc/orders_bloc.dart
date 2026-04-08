import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/order.dart';
import '../services/orders_service.dart';
import 'orders_event.dart';
import 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  Timer? _pollingTimer;

  OrdersBloc() : super(OrdersInitial()) {
    on<FetchOrders>(_onFetchOrders);
    on<ApproveOrder>(_onApproveOrder);
    on<DeclineOrder>(_onDeclineOrder);
    on<StartPollingOrders>(_onStartPolling);
    on<StopPollingOrders>(_onStopPolling);
  }

  Future<void> _onFetchOrders(FetchOrders event, Emitter<OrdersState> emit) async {
    // Only emit loading if we don't already have data, otherwise do a silent refresh for polling
    if (state is! OrdersLoaded) {
      emit(OrdersLoading());
    }

    try {
      final data = await OrdersService.fetchOrders();
      
      if (data['orders'] != null) {
        final List<dynamic> ordersJson = data['orders'];
        final orders = ordersJson
            .map((json) => Order.fromJson(json as Map<String, dynamic>))
            .toList();

        // Sort newest first
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Preserve the isProcessingAction state if currently loaded
        final isProcessing = state is OrdersLoaded 
            ? (state as OrdersLoaded).isProcessingAction 
            : false;

        emit(OrdersLoaded(orders: orders, isProcessingAction: isProcessing));
      } else {
        emit(const OrdersError('Invalid response format'));
      }
    } catch (e) {
      // Don't override existing data with an error on a silent poll fail
      if (state is! OrdersLoaded) {
        emit(OrdersError(e.toString()));
      }
    }
  }

  Future<void> _onApproveOrder(ApproveOrder event, Emitter<OrdersState> emit) async {
    await _processAction(event.order, 'approve', emit, pin: event.pin);
  }

  Future<void> _onDeclineOrder(DeclineOrder event, Emitter<OrdersState> emit) async {
    await _processAction(event.order, 'decline', emit, pin: event.pin);
  }

  Future<void> _processAction(Order order, String action, Emitter<OrdersState> emit, {String? pin}) async {
    List<Order> currentOrders = [];
    if (state is OrdersLoaded) {
      currentOrders = (state as OrdersLoaded).orders;
      emit((state as OrdersLoaded).copyWith(isProcessingAction: true));
    }

    try {
      if (pin == null) {
        throw Exception('PIN is required');
      }

      final jsonData = action == 'approve' 
          ? await OrdersService.approveOrder(order.id, pin)
          : await OrdersService.declineOrder(order.id, pin);

      if (jsonData['status'] == 'success' && jsonData['order'] != null) {
        final updatedOrder = Order.fromJson(jsonData['order'] as Map<String, dynamic>);
        
        // Update the order locally
        final index = currentOrders.indexWhere((o) => o.id == order.id);
        if (index != -1) {
          currentOrders[index] = updatedOrder;
        }
        
        // Emit a success transient state
        emit(OrderActionSuccess('Order ${action == 'approve' ? 'approved' : 'declined'} successfully', List.from(currentOrders)));
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      // Emit failure transient state
      emit(OrderActionFailure('Failed to $action order: $e', currentOrders));
    } finally {
      // Restore OrdersLoaded state without processing flag
      emit(OrdersLoaded(orders: currentOrders, isProcessingAction: false));
    }
  }

  void _onStartPolling(StartPollingOrders event, Emitter<OrdersState> emit) {
    // Initial fetch
    add(const FetchOrders());
    
    // Poll every 10 seconds
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      add(const FetchOrders());
    });
  }

  void _onStopPolling(StopPollingOrders event, Emitter<OrdersState> emit) {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}
