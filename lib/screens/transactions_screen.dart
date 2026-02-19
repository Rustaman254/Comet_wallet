import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';
import '../utils/responsive_utils.dart';
import '../constants/colors.dart';
import '../services/wallet_service.dart';
import '../models/transaction.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart'; 
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/format_utils.dart';
import 'transaction_details_screen.dart';
import '../widgets/usda_logo.dart';
import '../screens/main_wrapper.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'topup', 'send', 'usda', 'swap'];

  @override
  void initState() {
    super.initState();
    // Data is managed by WalletBloc globally
  }

  Future<void> _fetchTransactions() async {
    // Refresh global state via BLoC
    context.read<WalletBloc>().add(const RefreshWallet());
    if (mounted) {
       _runFilter(_searchController.text);
    }
  }

  void _runFilter(String query) {
    final state = context.read<WalletBloc>().state;
    List<Transaction> sourceList = [];
    if (state is WalletLoaded) {
      sourceList = List.from(state.transactions)..sort((a, b) => b.id.compareTo(a.id));
    } else if (state is WalletBalanceUpdated) {
      sourceList = List.from(state.transactions)..sort((a, b) => b.id.compareTo(a.id));
    }

    List<Transaction> results = [];
    if (query.isEmpty && _selectedFilter == 'All') {
      results = sourceList;
    } else {
      results = sourceList.where((tx) {
        final matchesSearch = tx.phoneNumber.contains(query) || 
                             tx.transactionType.toLowerCase().contains(query.toLowerCase()) ||
                             tx.amount.toString().contains(query);
        
        bool matchesFilter = false;
        if (_selectedFilter == 'All') {
          matchesFilter = true;
        } else if (_selectedFilter == 'topup') {
          matchesFilter = tx.transactionType.toLowerCase().contains('topup') || 
                         tx.transactionType.toLowerCase().contains('receive');
        } else if (_selectedFilter == 'send') {
          matchesFilter = tx.transactionType.toLowerCase().contains('send') || 
                         tx.transactionType.toLowerCase().contains('transfer') && 
                         !tx.transactionType.toLowerCase().contains('usda');
        } else if (_selectedFilter == 'usda') {
          matchesFilter = tx.currency == 'USDA' || 
                         tx.transactionType.toLowerCase().contains('usda');
        } else if (_selectedFilter == 'swap') {
          matchesFilter = tx.transactionType.toLowerCase().contains('swap');
        } else {
          matchesFilter = tx.transactionType.toLowerCase().contains(_selectedFilter.toLowerCase());
        }

        return matchesSearch && matchesFilter;
      }).toList();
    }

    setState(() {
      _filteredTransactions = results;
    });
  }

  void _onFilterChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedFilter = newValue;
        _runFilter(_searchController.text);
      });
    }
  }

  Future<void> _exportTransactions() async {
    if (_filteredTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export')),
      );
      return;
    }

    try {
      List<List<dynamic>> rows = [];
      // Header
      rows.add([
        'ID',
        'Type',
        'Amount',
        'Currency',
        'Status',
        'Phone Number',
        'Explorer Link'
      ]);

      // Data
      for (var tx in _filteredTransactions) {
        rows.add([
          tx.id,
          tx.transactionType,
          tx.amount,
          'KES', // Placeholder
          tx.status,
          tx.phoneNumber,
          tx.explorerLink ?? ''
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(path)], text: 'My Transactions History');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: Navigator.of(context).canPop(),
        onPopInvoked: (didPop) {
          if (didPop) return;
          // If we can't pop, we must be a tab. Go to Home (index 0).
          MainWrapper.of(context)?.onTabChanged(0);
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyMedium?.color),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  MainWrapper.of(context)?.onTabChanged(0);
                }
              },
            ),
        title: Text(
          'Transactions',
          style: TextStyle(fontFamily: 'Satoshi',
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.download, color: Theme.of(context).textTheme.bodyMedium?.color),
            onPressed: _exportTransactions,
            tooltip: 'Export Transactions',
          ),
        ],
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          final transactions = state is WalletLoaded ? (List<Transaction>.from(state.transactions)..sort((a, b) => b.id.compareTo(a.id))) : 
                             (state is WalletBalanceUpdated ? (List<Transaction>.from(state.transactions)..sort((a, b) => b.id.compareTo(a.id))) : <Transaction>[]);
          final query = _searchController.text;
          
          final filtered = transactions.where((tx) {
             final matchesSearch = tx.phoneNumber.contains(query) || 
                                  tx.transactionType.toLowerCase().contains(query.toLowerCase()) ||
                                  tx.amount.toString().contains(query);
             final matchesFilter = _selectedFilter == 'All' || tx.transactionType.toLowerCase().contains(_selectedFilter.toLowerCase());
             return matchesSearch && matchesFilter;
          }).toList();
          
          _filteredTransactions = filtered;

          return Column(
            children: [
              _buildSearchAndFilter(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchTransactions,
                  color: buttonGreen,
                  child: _buildBody(state),
                ),
              ),
            ],
          );
        },
      ),
        ),
    );

  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: cardBorder, width: 1.w),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _runFilter,
              style: TextStyle(fontFamily: 'Satoshi',color: Theme.of(context).textTheme.bodyMedium?.color),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: TextStyle(fontFamily: 'Satoshi',color: Colors.grey[500], fontSize: 14.sp),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: buttonGreen, size: 20.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () => _onFilterChanged(filter),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected ? buttonGreen : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isSelected ? buttonGreen : cardBorder,
                        width: 1.w,
                      ),
                    ),
                    child: Text(
                      filter.toUpperCase(),
                      style: TextStyle(fontFamily: 'Satoshi',
                        color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 12.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildBody(WalletState state) {
    if (state is WalletLoading && _filteredTransactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is WalletError && _filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.r, color: Colors.red[400]),
            SizedBox(height: 16.h),
            Text(
              'Error loading transactions',
              style: TextStyle(fontFamily: 'Satoshi', fontSize: 18.sp, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8.h),
            Text(
              state.message,
              style: TextStyle(fontFamily: 'Satoshi', color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64.r, color: Colors.grey[300]),
            SizedBox(height: 16.h),
            Text(
              'No matches found',
              style: TextStyle(fontFamily: 'Satoshi',
                fontSize: 16.sp,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Group transactions by date
    Map<String, List<Transaction>> grouped = {};
    for (var tx in _filteredTransactions) {
      String dateStr = _getDateHeader(tx.createdAt);
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(tx);
    }

    List<String> sortedHeaders = grouped.keys.toList();

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      itemCount: 1, // We'll build the whole list as a column inside a single item or use a different structure
      itemBuilder: (context, index) {
        return _buildGroupedList(grouped);
      },
    );
  }

  Widget _buildGroupedList(Map<String, List<Transaction>> grouped) {
    List<Widget> children = [];
    var sortedDates = grouped.keys.toList();
    
    for (var date in sortedDates) {
      children.add(
        Padding(
          padding: EdgeInsets.only(top: 24.h, bottom: 12.h),
          child: Text(
            date,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 1.1,
            ),
          ),
        ),
      );
      
      for (var tx in grouped[date]!) {
        children.add(_buildTransactionItem(tx));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    if (txDate == today) return 'TODAY';
    if (txDate == yesterday) return 'YESTERDAY';
    return DateFormat('MMMM dd, yyyy').format(date).toUpperCase();
  }

   Widget _buildTransactionItem(Transaction transaction) {
    Color statusColor;
    IconData iconData;
    Color iconColor;

    switch (transaction.status.toLowerCase()) {
      case 'complete':
      case 'success':
        statusColor = buttonGreen;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.red;
    }

    switch (transaction.transactionType.toLowerCase()) {
      case 'send':
      case 'transfer':
      case 'transfer_usda':
        iconData = Icons.arrow_upward;
        iconColor = Colors.red[400]!;
        break;
      case 'topup':
      case 'receive':
      case 'wallet_topup':
        iconData = Icons.arrow_downward;
        iconColor = buttonGreen;
        break;
      case 'swap':
        iconData = Icons.swap_horiz;
        iconColor = Colors.blue[400]!;
        break;
      default:
        iconData = Icons.compare_arrows;
        iconColor = Colors.grey[400]!;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailsScreen(transaction: transaction),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white.withOpacity(0.05) 
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white.withOpacity(0.1) 
                : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 20.r,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTransactionType(transaction.transactionType),
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        transaction.phoneNumber.isNotEmpty ? transaction.phoneNumber : 'N/A',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: Colors.grey[500],
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        width: 3.r,
                        height: 3.r,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        transaction.status.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: statusColor,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (transaction.currency == 'USDA')
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: USDALogo(size: 14),
                      )
                    else
                      Text(
                        USDALogo.getFlag(transaction.currency),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    SizedBox(width: 4.w),
                    Text(
                      FormatUtils.formatAmount(transaction.amount),
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  DateFormat('HH:mm').format(transaction.createdAt),
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    color: Colors.grey[500],
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

  String _formatTransactionType(String type) {
    String capitalizeWord(String word) {
      if (word.toUpperCase() == 'USDA') return 'USDA';
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }

    // Handle special cases first
    if (type.toLowerCase().contains('swap')) {
      // Format swap transactions properly
      final parts = type.split('_').map(capitalizeWord).toList();
      
      // Ensure "Swap" is at the beginning if not already
      if (!parts.first.toLowerCase().contains('swap')) {
        parts.insert(0, 'Swap');
      }
      
      return parts.join(' ');
    }
    
    // Default formatting for other transaction types
    return type.split('_').map(capitalizeWord).join(' ');
  }

}
