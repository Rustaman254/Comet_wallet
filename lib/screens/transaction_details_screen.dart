import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../constants/colors.dart';
import '../widgets/usda_logo.dart';
import '../utils/format_utils.dart';
import 'webview_screen.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailsScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? darkBackground : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Transaction Details',
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          children: [
            _buildHeader(context),
            SizedBox(height: 32.h),
            _buildDetailsCard(context),
            if (transaction.explorerLink != null && transaction.explorerLink!.isNotEmpty) ...[
              SizedBox(height: 32.h),
              _buildExplorerButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText = transaction.status.toUpperCase();

    switch (transaction.status.toLowerCase()) {
      case 'complete':
      case 'success':
        statusColor = buttonGreen;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time_filled;
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.error;
    }

    return Column(
      children: [
        Container(
          width: 80.r,
          height: 80.r,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(statusIcon, color: statusColor, size: 40.r),
        ),
        SizedBox(height: 16.h),
        Text(
          statusText,
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: statusColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (transaction.currency == 'USDA')
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: USDALogo(size: 28),
              )
            else
              Text(
                USDALogo.getFlag(transaction.currency),
                style: TextStyle(fontSize: 24.sp),
              ),
            SizedBox(width: 8.w),
            Text(
              '${FormatUtils.formatAmount(transaction.amount)} ${transaction.currency == 'USDA' ? 'USDA (Cardano)' : transaction.currency}',
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          _buildDetailRow(context, 'Type', _formatType(transaction.transactionType)),
          _buildDivider(isDark),
          _buildDetailRow(context, 'Date', DateFormat('MMM dd, yyyy').format(transaction.createdAt)),
          _buildDivider(isDark),
          _buildDetailRow(context, 'Time', DateFormat('HH:mm').format(transaction.createdAt)),
          _buildDivider(isDark),
          _buildDetailRow(context, 'Reference', '#${transaction.id}', showCopy: true),
          if (transaction.phoneNumber.isNotEmpty) ...[
            _buildDivider(isDark),
            _buildDetailRow(context, 'Recipient/Source', transaction.phoneNumber, showCopy: true),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool showCopy = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Satoshi',
              color: Colors.grey[500],
              fontSize: 14.sp,
            ),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showCopy) ...[
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    child: Icon(Icons.copy, size: 16.r, color: buttonGreen),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
    );
  }

  Widget _buildExplorerButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewScreen(
                url: transaction.explorerLink!,
                title: 'Transaction Explorer',
              ),
            ),
          );
        },
        icon: const Icon(Icons.open_in_new, color: Colors.white),
        label: const Text(
          'View on Explorer',
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonGreen,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  String _formatType(String type) {
    return type.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }
}
