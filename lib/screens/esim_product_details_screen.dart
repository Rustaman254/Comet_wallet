import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';
import '../models/esim_model.dart';
import '../services/esim_service.dart';
import '../services/toast_service.dart';
import '../services/vibration_service.dart';
import '../widgets/usda_logo.dart';
import 'swap_screen.dart';
import 'enter_pin_screen.dart';

class ESimProductDetailsScreen extends StatefulWidget {
  final int productId;

  const ESimProductDetailsScreen({super.key, required this.productId});

  @override
  State<ESimProductDetailsScreen> createState() => _ESimProductDetailsScreenState();
}

class _ESimProductDetailsScreenState extends State<ESimProductDetailsScreen> {
  ESimProduct? _product;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    try {
      final product = await ESimService.getProductDetails(widget.productId);
      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ToastService().showError(context, 'Failed to load details: $e');
        Navigator.pop(context);
      }
    }
  }

  void _initiatePurchase() async {
    if (_product == null) return;

    // 1. PIN Entry
    final pin = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => EnterPinScreen(
          recipientName: 'eSIM Purchase',
          amount: _product!.price,
          currency: 'USD',
          description: 'Purchase of ${_product!.name}',
        ),
      ),
    );

    if (pin == null) return;

    setState(() => _isProcessing = true);

    try {
      // 2. Request Order
      final orderRequest = await ESimService.requestOrder(_product!.id);

      // 3. Complete Order
      final result = await ESimService.completeOrder(
        orderId: orderRequest.orderId,
        pin: pin,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        if (result.isSuccess) {
          _showSuccess(result.message);
        } else if (result.error == 'Insufficient USD balance') {
          _showInsufficientBalanceDialog(result);
        } else {
          ToastService().showError(context, result.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ToastService().showError(context, 'Purchase failed: $e');
      }
    }
  }

  void _showSuccess(String message) {
    VibrationService.lightImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Purchase Successful',
              style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Outfit')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Details
              Navigator.pop(context); // Products
            },
            child: const Text('Great!', style: TextStyle(color: primaryBrandColor)),
          ),
        ],
      ),
    );
  }

  void _showInsufficientBalanceDialog(ESimOrderCompleteResponse result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Insufficient Balance', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You need \$${result.requiredUsd.toStringAsFixed(2)} for this plan.'),
            Text('Current balance: \$${result.currentUsd.toStringAsFixed(2)}'),
            if (result.error != null) ...[
              const SizedBox(height: 12),
              Text(
                'Error: ${result.error}',
                style: const TextStyle(fontFamily: 'Outfit', color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            Text(result.message, style: const TextStyle(fontFamily: 'Outfit', color: Colors.orange)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SwapScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryBrandColor),
            child: const Text('Swap Funds', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? darkBackground : lightBackground,
        body: const Center(child: CircularProgressIndicator(color: primaryBrandColor)),
      );
    }

    final product = _product!;
    final country = product.countries.isNotEmpty ? product.countries.first : null;

    return Scaffold(
      backgroundColor: isDark ? darkBackground : lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Plan Details',
          style: TextStyle(fontFamily: 'Outfit', color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80.r,
                    height: 80.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: primaryBrandColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: country != null
                        ? Text(USDALogo.getFlag(country.countryCode), style: TextStyle(fontSize: 40.sp))
                        : Icon(Icons.public, color: primaryBrandColor, size: 48.r),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    product.name,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    product.region,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: primaryBrandColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40.h),

            // Specs Grid
            Row(
              children: [
                _buildSpecItem('Data', '${product.data} GB', Icons.data_usage),
                _buildSpecItem('Validity', '${product.validity} Days', Icons.timer_outlined),
                _buildSpecItem('Type', product.planType, Icons.sim_card_outlined),
              ],
            ),
            SizedBox(height: 32.h),

            // Countries
            Text(
              'Coverage',
              style: TextStyle(fontFamily: 'Outfit', color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7), fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: product.countries.map((c) => Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '${USDALogo.getFlag(c.countryCode)} ${c.countryName}',
                  style: TextStyle(fontFamily: 'Outfit', color: isDark ? Colors.white : Colors.black, fontSize: 13.sp),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: isDark ? cardBackground : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Price', style: TextStyle(fontFamily: 'Outfit', color: isDark ? Colors.white54 : Colors.black54)),
                Text(
                  '\$${product.price}',
                  style: TextStyle(fontFamily: 'Outfit', color: isDark ? Colors.white : Colors.black, fontSize: 24.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(width: 24.w),
            Expanded(
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _initiatePurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBrandColor,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: _isProcessing
                    ? SizedBox(width: 20.r, height: 20.r, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Buy Now', style: TextStyle(fontFamily: 'Outfit', fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: primaryBrandColor, size: 24.r),
          SizedBox(height: 8.h),
          Text(value, style: TextStyle(fontFamily: 'Outfit', color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontFamily: 'Outfit', color: isDark ? Colors.white54 : Colors.black54, fontSize: 12.sp)),
        ],
      ),
    );
  }
}
