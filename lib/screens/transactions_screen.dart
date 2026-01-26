import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/responsive_utils.dart';
import '../constants/colors.dart';
import '../services/wallet_service.dart';
import '../services/wallet_provider.dart';
import '../models/transaction.dart';
import '../services/vibration_service.dart';

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
  final List<String> _filters = ['All', 'topup', 'send', 'link'];

  @override
  void initState() {
    super.initState();
    // Initial fetch if needed, though mostly handled by Home
    // We can rely on Provider's existing data or fetch fresh
    if (WalletProvider.instance.transactions.isEmpty) {
      WalletProvider.instance.fetchData();
    }
    
    // Initialize filtered list with current provider data
    _filteredTransactions = WalletProvider.instance.transactions;
  }

  Future<void> _fetchTransactions() async {
    // Refresh global state
    await WalletProvider.instance.fetchData();
    // _filteredTransactions will be updated in build or listener if we added one, 
    // but here we are using local filtered list. 
    // Ideally, we should update _filteredTransactions based on new data + search query.
    // simpler: just re-run filter logic.
    if (mounted) {
       _runFilter(_searchController.text);
    }
  }

  void _runFilter(String query) {
    List<Transaction> sourceList = WalletProvider.instance.transactions;
    List<Transaction> results = [];
    if (query.isEmpty && _selectedFilter == 'All') {
      results = sourceList;
    } else {
      results = sourceList.where((tx) {
        final matchesSearch = tx.phoneNumber.contains(query) || 
                             tx.transactionType.toLowerCase().contains(query.toLowerCase()) ||
                             tx.amount.toString().contains(query);
        final matchesFilter = _selectedFilter == 'All' || tx.transactionType.toLowerCase().contains(_selectedFilter.toLowerCase());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyMedium?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Transactions',
          style: GoogleFonts.poppins(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: WalletProvider.instance,
        builder: (context, child) {
          // Update filtered list when provider updates if query is empty/unchanged? 
          // Use a simple trick: if the list size changed significantly or we want real-time,
          // we might need to re-run filter every time provider notifies.
          // For now, let's re-run filter immediately.
          
          // Careful: _runFilter calls setState, which is bad inside build.
          // Better: Perform filtering inside build.
          
          final provider = WalletProvider.instance;
          final transactions = provider.transactions;
          final query = _searchController.text;
          
          final filtered = transactions.where((tx) {
             final matchesSearch = tx.phoneNumber.contains(query) || 
                                  tx.transactionType.toLowerCase().contains(query.toLowerCase()) ||
                                  tx.amount.toString().contains(query);
             final matchesFilter = _selectedFilter == 'All' || tx.transactionType.toLowerCase().contains(_selectedFilter.toLowerCase());
             return matchesSearch && matchesFilter;
          }).toList();
          
          // Assign to local for compatibility if needed, but we can just use `filtered`
          _filteredTransactions = filtered;

          return Column(
            children: [
              _buildSearchAndFilter(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchTransactions,
                  color: buttonGreen,
                  child: _buildBody(),
                ),
              ),
            ],
          );
        },
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
              style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyMedium?.color),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14.sp),
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
                      style: GoogleFonts.poppins(
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

  Widget _buildBody() {
    final provider = WalletProvider.instance;
    if (provider.isLoading && _filteredTransactions.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    if (provider.error.isNotEmpty && _filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.r, color: Colors.red[400]),
            SizedBox(height: 16.h),
            Text(
              'Error loading transactions',
              style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8.h),
            Text(
              provider.error,
              style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _fetchTransactions,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text('Try Again'),
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
            Icon(Icons.history, size: 80.r, color: Colors.grey[700]),
            SizedBox(height: 16.h),
            Text(
              'No matches found',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      itemCount: _filteredTransactions.length,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: _buildTransactionItem(transaction),
        );
      },
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    Color statusColor;
    IconData iconData;
    Color iconColor;

    switch (transaction.status.toLowerCase()) {
      case 'complete':
        statusColor = buttonGreen;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'failed':
      default:
        statusColor = Colors.red;
        break;
    }

    switch (transaction.transactionType.toLowerCase()) {
      case 'wallet_topup':
        iconData = Icons.add_circle_outline;
        iconColor = Colors.blue;
        break;
      case 'send_money':
        iconData = Icons.send_outlined;
        iconColor = Colors.orange;
        break;
      case 'payment_link':
        iconData = Icons.link;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.swap_horiz;
        iconColor = Colors.grey;
    }

    return Row(
      children: [
        Container(
          width: 50.r,
          height: 50.r,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? transactionIconLight
                : iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconData,
            color: iconColor,
            size: 24.r,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatTransactionType(transaction.transactionType),
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Text(
                    transaction.phoneNumber.isNotEmpty ? transaction.phoneNumber : 'N/A',
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    width: 4.r,
                    height: 4.r,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    transaction.status.toUpperCase(),
                    style: GoogleFonts.poppins(
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
        Text(
          'KES ${transaction.amount.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatTransactionType(String type) {
    return type.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }
}
