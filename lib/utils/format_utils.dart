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
}
