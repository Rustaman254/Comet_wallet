import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants/colors.dart';
import '../utils/responsive_utils.dart';
import '../services/toast_service.dart';
import '../models/order.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_event.dart';
import '../bloc/orders_state.dart';
import '../services/orders_service.dart';
import 'enter_pin_screen.dart';

// ─── OrdersPage ──────────────────────────────────────────────────────────────

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrdersBloc()..add(const StartPollingOrders()),
      child: const OrdersView(),
    );
  }
}

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Approved', 'Declined'];

  // ── Action Handlers ──────────────────────────────────────────────────────

  void _approveOrder(Order order) {
    _navigateToPinScreen(order, 'approve');
  }

  void _declineOrder(Order order) {
    _navigateToPinScreen(order, 'decline');
  }

  void _navigateToPinScreen(Order order, String action) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EnterPinScreen(
          recipientName: order.externalRef,
          amount: order.amount.toStringAsFixed(2),
          currency: order.currency,
          description: '${action == 'approve' ? 'Approving' : 'Declining'} order #${order.id}',
          onVerify: (pin) async {
            final response = action == 'approve'
                ? await OrdersService.approveOrder(order.id, pin)
                : await OrdersService.declineOrder(order.id, pin);
            
            // On success, the EnterPinScreen will show its success dialog.
            // We should also trigger a refresh in the Bloc so the OrdersPage updates.
            if (mounted) {
              context.read<OrdersBloc>().add(const FetchOrders());
            }
            
            return response;
          },
        ),
      ),
    );
  }

  // ── Filtering ────────────────────────────────────────────────────────────

  List<Order> _getFilteredOrders(List<Order> allOrders) {
    if (_selectedFilter == 'All') return allOrders;
    return allOrders
        .where((o) => o.status.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return successGreen;
      case 'pending':
        return warningOrange;
      case 'declined':
        return errorRed;
      default:
        return transactionDefaultColor;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.schedule;
      case 'declined':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  String _dateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'TODAY';
    if (d == yesterday) return 'YESTERDAY';
    return DateFormat('MMMM dd, yyyy').format(date).toUpperCase();
  }

  Map<String, List<Order>> _groupByDate(List<Order> orders) {
    final Map<String, List<Order>> grouped = {};
    for (final order in orders) {
      final key = _dateHeader(order.createdAt);
      grouped.putIfAbsent(key, () => []).add(order);
    }
    return grouped;
  }

  double _getTotalAmount(List<Order> filteredOrders) =>
      filteredOrders.fold(0.0, (sum, o) => sum + o.amount);

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrdersBloc, OrdersState>(
      listener: (context, state) {
        if (state is OrderActionSuccess) {
          ToastService().showSuccess(context, state.message);
        } else if (state is OrderActionFailure) {
          ToastService().showError(context, state.message);
        }
      },
      builder: (context, state) {
        bool isLoading = state is OrdersInitial || state is OrdersLoading;
        bool isProcessingAction = false;
        String? errorMessage;
        List<Order> currentOrders = [];
        
        if (state is OrdersLoaded) {
          currentOrders = state.orders;
          isProcessingAction = state.isProcessingAction;
        } else if (state is OrdersError) {
          errorMessage = state.message;
        } else if (state is OrderActionSuccess) {
          currentOrders = state.currentOrders;
        } else if (state is OrderActionFailure) {
          currentOrders = state.currentOrders;
        }

        final filteredOrders = _getFilteredOrders(currentOrders);
        final totalAmount = _getTotalAmount(filteredOrders);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Theme.of(context).textTheme.bodyMedium?.color),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Orders',
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              // Main content
              Column(
                children: [
                  // ── Summary header ──────────────────────────────────────────
                  _buildSummaryHeader(filteredOrders, totalAmount),

                  // ── Filter chips ────────────────────────────────────────────
                  _buildFilterChips(),
                  SizedBox(height: 8.h),

                  // ── List / states ───────────────────────────────────────────
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        context.read<OrdersBloc>().add(const FetchOrders());
                      },
                      color: primaryBrandColor,
                      child: _buildBody(filteredOrders, isLoading, errorMessage),
                    ),
                  ),
                ],
              ),
              
              // Loading overlay
              if (isProcessingAction)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(color: primaryBrandColor),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Summary header ───────────────────────────────────────────────────────

  Widget _buildSummaryHeader(List<Order> filteredOrders, double totalAmount) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    primaryBrandColor,
                    primaryBrandColor.withValues(alpha: 0.8),
                    secondaryBrandColor.withValues(alpha: 0.8),
                  ]
                : [
                    const Color(0xFF2563EB),
                    const Color(0xFF3B82F6),
                    const Color(0xFF60A5FA),
                  ],
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Orders',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${filteredOrders.length}',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: Colors.white,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 48.h,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${filteredOrders.isNotEmpty ? filteredOrders.first.currency : 'KES'} ${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter chips ─────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryBrandColor
                      : getCardColor(context),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected ? primaryBrandColor : getBorderColor(context),
                    width: 1.w,
                  ),
                ),
                child: Text(
                  filter.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Body (loading / error / empty / list) ────────────────────────────────

  Widget _buildBody(List<Order> orders, bool isLoading, String? errorMessage) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryBrandColor),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.r, color: errorRed),
              SizedBox(height: 16.h),
              Text(
                'Error loading orders',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: getTextColor(context),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                errorMessage,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: getTertiaryTextColor(context),
                  fontSize: 13.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: () => context.read<OrdersBloc>().add(const FetchOrders()),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Retry',
                    style: TextStyle(
                        fontFamily: 'Satoshi', color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBrandColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64.r, color: getTertiaryTextColor(context)),
            SizedBox(height: 16.h),
            Text(
              _selectedFilter == 'All'
                  ? 'No orders yet'
                  : 'No ${_selectedFilter.toLowerCase()} orders',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 16.sp,
                color: getTertiaryTextColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Group by date
    final grouped = _groupByDate(orders);

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      children: [
        for (final date in grouped.keys) ...[
          Padding(
            padding: EdgeInsets.only(top: 16.h, bottom: 10.h),
            child: Text(
              date,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: getTertiaryTextColor(context),
                letterSpacing: 1.1,
              ),
            ),
          ),
          for (final order in grouped[date]!) _buildOrderCard(order),
        ],
      ],
    );
  }

  // ── Order card ───────────────────────────────────────────────────────────

  Widget _buildOrderCard(Order order) {
    final statusCol = _statusColor(order.status);

    return GestureDetector(
      onTap: () => _showOrderDetail(order),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: statusCol.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                _statusIcon(order.status),
                color: statusCol,
                size: 22.r,
              ),
            ),
            SizedBox(width: 14.w),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.externalRef.isNotEmpty
                        ? order.externalRef
                        : order.description,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        order.payerEmail,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: getTertiaryTextColor(context),
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        width: 3.r,
                        height: 3.r,
                        decoration: BoxDecoration(
                          color: getTertiaryTextColor(context),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        order.status.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: statusCol,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Amount + time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${order.currency} ${order.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  DateFormat('HH:mm').format(order.createdAt),
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    color: getTertiaryTextColor(context),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Order detail bottom sheet ────────────────────────────────────────────

  void _showOrderDetail(Order order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: getCardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      isScrollControlled: true,
      builder: (context) {
        final statusCol = _statusColor(order.status);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.all(24.r),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: getTertiaryTextColor(context).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Status icon large
                  Container(
                    width: 64.r,
                    height: 64.r,
                    decoration: BoxDecoration(
                      color: statusCol.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _statusIcon(order.status),
                      color: statusCol,
                      size: 32.r,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: statusCol,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '${order.currency} ${order.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: getTextColor(context),
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Detail rows
                  _detailRow('Order ID', '#${order.id}'),
                  _detailRow('External Ref', order.externalRef),
                  _detailRow('Comment Ref', order.commentRef),
                  _detailRow('Payer Email', order.payerEmail),
                  _detailRow('Description', order.description),
                  _detailRow(
                    'Created',
                    DateFormat('dd MMM yyyy, hh:mm a')
                        .format(order.createdAt),
                  ),
                  _detailRow(
                    'Updated',
                    DateFormat('dd MMM yyyy, hh:mm a')
                        .format(order.updatedAt),
                  ),
                  SizedBox(height: 24.h),
                  
                  // Action buttons if pending
                  if (order.status.toLowerCase() == 'pending') ...[
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _declineOrder(order);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: errorRed, width: 1.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            child: Text(
                              'Decline',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                color: errorRed,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _approveOrder(order);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: successGreen,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            child: Text(
                              'Approve',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: getTertiaryTextColor(context),
                fontSize: 13.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: getTextColor(context),
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
