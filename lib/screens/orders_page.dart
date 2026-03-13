import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

const String fusionFiToken = '<MY_TOKEN>';

class Order {
  final int id;
  final DateTime createdAt;
  final String externalRef;
  final String commentRef;
  final String payerEmail;
  final int userId;
  final double amount;
  final String currency;
  final String status;
  final String description;

  Order({
    required this.id,
    required this.createdAt,
    required this.externalRef,
    required this.commentRef,
    required this.payerEmail,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.description,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['ID'] ?? 0,
      createdAt: DateTime.parse(json['CreatedAt'] ?? DateTime.now().toIso8601String()),
      externalRef: json['external_ref'] ?? '',
      commentRef: json['comment_ref'] ?? '',
      payerEmail: json['payer_email'] ?? '',
      userId: json['user_id'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? '',
      status: json['status'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = fetchOrders();
  }

  Future<List<Order>> fetchOrders() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.fusionfi.io/api/v1/bill-orders/'),
        headers: {
          'Authorization': 'Bearer $fusionFiToken',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch orders. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      final ordersJson = jsonData['orders'] as List<dynamic>?;

      if (ordersJson == null) {
        return [];
      }

      final orders = (ordersJson)
          .map((order) => Order.fromJson(order as Map<String, dynamic>))
          .toList();

      // Sort by CreatedAt descending (newest first)
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return orders;
    } catch (e) {
      rethrow;
    }
  }

  void _retry() {
    setState(() {
      _ordersFuture = fetchOrders();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    return '${dateFormat.format(dateTime)}\n${timeFormat.format(dateTime)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _retry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Text('No orders found'),
            );
          }

          return ListView.builder(
            itemCount: orders.length,
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              final order = orders[index];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text(order.externalRef.isNotEmpty ? order.externalRef : order.description),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Amount: ${order.amount} ${order.currency} • Status: ',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              order.status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: _getStatusColor(order.status),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Payer: ${order.payerEmail}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (order.description.isNotEmpty && order.externalRef != order.description)
                        Text(
                          'Description: ${order.description}',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: Text(
                    _formatDateTime(order.createdAt),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Navigation example:
// Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersPage()));
