class CurrencyUtils {
  /// Map user location to a default local currency
  static String getDefaultCurrency(String? location) {
    if (location == null) return 'KES';
    
    final normalizedLocation = location.trim().toUpperCase();
    
    switch (normalizedLocation) {
      case 'KENYA':
        return 'KES';
      case 'UGANDA':
        return 'UGX';
      case 'TANZANIA':
        return 'TZS';
      case 'RWANDA':
        return 'RWF';
      default:
        return 'KES'; // Default fallback
    }
  }

  /// Centralized filtering and sorting logic for wallet balances
  static List<Map<String, dynamic>> filterAndSortBalances({
    required List<Map<String, dynamic>> rawBalances,
    required String localCurrency,
    required Set<String> manuallyAddedCurrencies,
  }) {
    // 1. Filter: Show Local, USDA, manually added, OR anything with balance > 0
    final filteredBalances = rawBalances.where((b) {
      final currency = b['currency']?.toString().toUpperCase() ?? '';
      final amount = double.tryParse(b['amount']?.toString() ?? '0') ?? 0.0;
      
      return currency == localCurrency || 
             currency == 'USDA' || 
             manuallyAddedCurrencies.contains(currency) ||
             amount > 0;
    }).toList();

    // 2. Sort: localCurrency first, then USDA, then alphabetical
    filteredBalances.sort((a, b) {
      final currencyA = a['currency']?.toString().toUpperCase() ?? '';
      final currencyB = b['currency']?.toString().toUpperCase() ?? '';
      
      if (currencyA == localCurrency) return -1;
      if (currencyB == localCurrency) return 1;
      if (currencyA == 'USDA') return -1;
      if (currencyB == 'USDA') return 1;
      
      return currencyA.compareTo(currencyB);
    });

    return filteredBalances;
  }
}
