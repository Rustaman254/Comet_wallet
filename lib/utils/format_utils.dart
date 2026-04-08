import 'package:intl/intl.dart';

class FormatUtils {
  static String formatAmount(double amount) {
    if (amount % 1 == 0) {
      return NumberFormat("#,###").format(amount);
    }
    return NumberFormat("#,##0.00").format(amount);
  }

  static String formatCurrency(double amount, String currency) {
    return '$currency ${formatAmount(amount)}';
  }
  
  /// Convert USDA blockchain value (lovelace) to dollars
  /// 1 USDA = 1,000,000 lovelace (similar to ADA)
  static double lovelaceToDollars(int lovelace) {
    return lovelace / 1000000.0;
  }
  
  /// Convert dollars to lovelace
  static int dollarsToLovelace(double dollars) {
    return (dollars * 1000000).round();
  }
  
  /// Format USDA amount for display
  /// Returns formatted dollar amount
  static String formatUSDA(int lovelace) {
    final dollars = lovelaceToDollars(lovelace);
    return formatAmount(dollars);
  }
  
  /// Format lovelace for display
  /// Returns formatted blockchain value with unit
  static String formatLovelace(int lovelace) {
    return '${NumberFormat("#,###").format(lovelace)} lovelace';
  }
}
