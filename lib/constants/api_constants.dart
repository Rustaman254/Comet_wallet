class ApiConstants {
  static const String baseUrl = 'https://api.yeshara.network/api/v1';
  static const String loginEndpoint = '$baseUrl/users/login';
  static const String registerEndpoint = '$baseUrl/users/create';
  static const String userProfileEndpoint = '$baseUrl/users/profile';
  static const String kycCreateEndpoint = '$baseUrl/kyc/create';
  static const String walletTopupEndpoint = '$baseUrl/wallet/topup';
  static const String walletTransferEndpoint = '$baseUrl/wallet/transfer';
  static const String walletBalanceEndpoint = '$baseUrl/wallet/balance';
  static const String walletTransactionsEndpoint = '$baseUrl/wallets/transactions';
  static const String paymentLinksEndpoint = '$baseUrl/payment-links';
  static const String walletSendMoneyEndpoint = '$baseUrl/wallet/send-money';
  static const String imageUploadUrl = 'https://images.cradlevoices.com/';
}
