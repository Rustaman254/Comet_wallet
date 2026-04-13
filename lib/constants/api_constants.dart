import '../flavors.dart';

class ApiConstants {
  static String get baseUrl => F.baseUrl;
  static String get loginEndpoint => '$baseUrl/users/login';
  static String get registerEndpoint => '$baseUrl/users/create';
  static String get userProfileEndpoint => '$baseUrl/users/profile';
  static String get kycCreateEndpoint => '$baseUrl/kyc/create';
  static String get kycVerifyEndpoint => '$baseUrl/kyc/verify';
  static String get walletTopupEndpoint => '$baseUrl/wallet/topup';
  static String get walletTransferEndpoint => '$baseUrl/wallet/transfer';
  static String get walletBalanceEndpoint => '$baseUrl/wallet/balance';
  static String get walletTransactionsEndpoint => '$baseUrl/wallets/transactions';
  static String get transactionsListEndpoint => '$baseUrl/transactions/list';
  static String get paymentLinksEndpoint => '$baseUrl/payment-links';
  static String get walletSendMoneyEndpoint => '$baseUrl/wallet/send-money';
  static String get walletTillPaymentEndpoint => '$baseUrl/wallet/till-payment';
  static String get walletBankTransferEndpoint => '$baseUrl/wallet/bank-transfer';
  static String get verifyPinEndpoint => '$baseUrl/users/verify-pin';
  static String get resetPinEndpoint => '$baseUrl/users/reset-pin';
  static const String imageUploadUrl = 'https://images.cradlevoices.com/';
  
  // Wallet endpoints
  static String get walletSwapEndpoint => '$baseUrl/wallet/swap';
  static String get walletTransferUsdaEndpoint => '$baseUrl/wallet/transfer-usda';
  
  // Real estate endpoints
  static String get realEstatePropertiesEndpoint => '$baseUrl/real-estate/properties';
  static String get realEstatePropertyDetailsEndpoint => '$baseUrl/real-estate/property';
  static String get realEstateBuyTokensEndpoint => '$baseUrl/real-estate/buy-tokens';
  static String get realEstateMyInvestmentsEndpoint => '$baseUrl/real-estate/my-investments';
  static String get realEstateMarketplaceEndpoint => '$baseUrl/real-estate/marketplace';
  static String get realEstateSellTokensEndpoint => '$baseUrl/real-estate/sell-tokens';
  static String get realEstateTransactionsEndpoint => '$baseUrl/real-estate/transactions';

  // Forex endpoints
  static String get forexRatesEndpoint => '$baseUrl/forex/rates';
  static const String currenciesEndpoint = 'https://api.yeshara.network/api/v1/forex/currencies';

  // Forgot password endpoints
  static String get resetTokenEndpoint => '$baseUrl/users/reset-token';
  static String get verifyTokenEndpoint => '$baseUrl/users/verify-token';
  static String get resetPasswordEndpoint => '$baseUrl/users/reset-password';
}
