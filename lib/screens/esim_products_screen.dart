import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';
import '../models/esim_model.dart';
import '../services/esim_service.dart';
import '../services/toast_service.dart';
import '../widgets/usda_logo.dart';
import '../services/forex_service.dart';
import 'esim_product_details_screen.dart';

class ESimProductsScreen extends StatefulWidget {
  const ESimProductsScreen({super.key});

  @override
  State<ESimProductsScreen> createState() => _ESimProductsScreenState();
}

class _ESimProductsScreenState extends State<ESimProductsScreen> {
  List<ESimProduct> _allProducts = [];
  List<ESimProduct> _filteredProducts = [];
  bool _isLoading = true;
  String _selectedRegion = 'All';
  final TextEditingController _searchController = TextEditingController();
  double _usdToUsdaRate = 1.0;
  bool _isRateLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchProducts(),
      _fetchRate(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRate() async {
    try {
      final rate = await ForexService.getExchangeRate('USD', 'USDA');
      if (mounted) {
        setState(() {
          _usdToUsdaRate = rate;
          _isRateLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching rate: $e');
      if (mounted) {
        setState(() => _isRateLoading = false);
      }
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final products = await ESimService.getProducts();
      if (mounted) {
        setState(() {
          _allProducts = products;
          _filteredProducts = products;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastService().showError(context, 'Failed to load eSIM plans: $e');
      }
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final matchesSearch = product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.countries.any((c) => c.countryName.toLowerCase().contains(query.toLowerCase()));
        final matchesRegion = _selectedRegion == 'All' || product.region == _selectedRegion;
        return matchesSearch && matchesRegion;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final regions = ['All', ..._allProducts.map((p) => p.region).toSet().toList()];

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
          'eSIM Plans',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search and Filters
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterProducts,
                    style: TextStyle(fontFamily: 'Outfit', color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Search by country or plan',
                      hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: primaryBrandColor),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: regions.map((region) {
                      final isSelected = _selectedRegion == region;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: ChoiceChip(
                          label: Text(region),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedRegion = region;
                              _filterProducts(_searchController.text);
                            });
                          },
                          labelStyle: TextStyle(
                            fontFamily: 'Outfit',
                            color: isSelected ? Colors.white : (isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                          ),
                          selectedColor: primaryBrandColor,
                          backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Products List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryBrandColor))
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Text(
                          'No plans found',
                          style: TextStyle(fontFamily: 'Outfit', color: isDark ? Colors.white54 : Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return _buildProductCard(product);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ESimProduct product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final country = product.countries.isNotEmpty ? product.countries.first : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ESimProductDetailsScreen(productId: product.id),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 50.r,
              height: 50.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primaryBrandColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: country != null
                  ? Text(
                      USDALogo.getFlag(country.countryCode),
                      style: TextStyle(fontSize: 24.sp),
                    )
                  : Icon(Icons.public, color: primaryBrandColor, size: 28.r),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${product.data}GB • ${product.validity} Days',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 14.sp,
                    ),
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
                    Text(
                      '${((double.tryParse(product.price) ?? 0) * _usdToUsdaRate).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: primaryBrandColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    const USDALogo(size: 16),
                  ],
                ),
                Text(
                  'USDA',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 12.sp,
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 14.sp, color: isDark ? Colors.white.withOpacity(0.24) : Colors.black.withOpacity(0.24)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
