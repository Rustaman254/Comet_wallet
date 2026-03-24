import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';
import '../widgets/usda_logo.dart';

class CurrencySelectionSheet extends StatelessWidget {
  final List<Map<String, String>> currencies; // List of {code: 'USD', name: 'US Dollar'}
  final String? selectedCurrency;
  final Function(String) onCurrencySelected;
  final String title;

  const CurrencySelectionSheet({
    super.key,
    required this.currencies,
    required this.onCurrencySelected,
    this.selectedCurrency,
    this.title = 'Select Currency',
  });

  @override
  Widget build(BuildContext context) {
    // 1. Sort currencies: USDA first, then others alphabetically by code
    final sortedCurrencies = List<Map<String, String>>.from(currencies);
    
    // Remove duplicates if any (by code)
    final Map<String, Map<String, String>> uniqueMap = {};
    for (var currency in sortedCurrencies) {
      if (currency['code'] != null) {
        uniqueMap[currency['code']!] = currency;
      }
    }
    final uniqueCurrenciesList = uniqueMap.values.toList();
    
    // Sort logic: USDA first, then others
    uniqueCurrenciesList.sort((a, b) {
      final codeA = a['code'] ?? '';
      final codeB = b['code'] ?? '';
      if (codeA == 'USDA') return -1;
      if (codeB == 'USDA') return 1;
      return codeA.compareTo(codeB);
    });

    return Container(
      padding: EdgeInsets.all(24.r),
      // Ensure height is constrained to show scrolling
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          Flexible(
            child: Scrollbar(
              thumbVisibility: true,
              radius: Radius.circular(4.r),
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                shrinkWrap: true,
                itemCount: uniqueCurrenciesList.length,
                separatorBuilder: (_, __) => Divider(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey[200],
                ),
                itemBuilder: (context, index) {
                  final currencyData = uniqueCurrenciesList[index];
                  final code = currencyData['code'] ?? '';
                  final name = currencyData['name'] ?? code;
                  final isSelected = code == selectedCurrency;
                  
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        onCurrencySelected(code);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                        decoration: isSelected ? BoxDecoration(
                          color: primaryBrandColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: primaryBrandColor.withValues(alpha: 0.3)),
                        ) : null,
                        child: Row(
                          children: [
                            _buildCurrencyIcon(code, size: 32.r, context: context),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 16.sp,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  if (name != code)
                                    Text(
                                      code,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12.sp,
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle, color: primaryBrandColor, size: 24.r),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrencyName(String code) {
    return code;
  }

  Widget _buildCurrencyIcon(String currency, {required double size, required BuildContext context}) {
    if (currency == 'USDA') {
      return USDALogo(size: size);
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[100],
        shape: BoxShape.circle,
      ),
      child: Text(
        USDALogo.getFlag(currency),
        style: TextStyle(
          fontSize: size * 0.6,
        ),
      ),
    );
  }
}
