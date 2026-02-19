class ApiConstants {
  static const String baseUrl = 'https://api.fusionfi.io/api/v1'; // https://api.fusionfi.io - https://api.yeshara.network
  static const String loginEndpoint = '$baseUrl/users/login';
  static const String registerEndpoint = '$baseUrl/users/create';
  static const String userProfileEndpoint = '$baseUrl/users/profile';
  static const String kycCreateEndpoint = '$baseUrl/kyc/create';
  static const String walletTopupEndpoint = '$baseUrl/wallet/topup';
  static const String walletTransferEndpoint = '$baseUrl/wallet/transfer';
  static const String walletBalanceEndpoint = '$baseUrl/wallet/balance';
  static const String walletTransactionsEndpoint = '$baseUrl/wallets/transactions';
  static const String transactionsListEndpoint = '$baseUrl/transactions/list';
  static const String paymentLinksEndpoint = '$baseUrl/payment-links';
  static const String walletSendMoneyEndpoint = '$baseUrl/wallet/send-money';
  static const String verifyPinEndpoint = '$baseUrl/users/verify-pin';
  static const String imageUploadUrl = 'https://images.cradlevoices.com/';
  
  // Wallet endpoints
  static const String walletSwapEndpoint = '$baseUrl/wallet/swap';
  static const String walletTransferUsdaEndpoint = '$baseUrl/wallet/transfer-usda';
  
  // Real estate endpoints
  static const String realEstatePropertiesEndpoint = '$baseUrl/real-estate/properties';
  static const String realEstatePropertyDetailsEndpoint = '$baseUrl/real-estate/property';
  static const String realEstateBuyTokensEndpoint = '$baseUrl/real-estate/buy-tokens';
  static const String realEstateMyInvestmentsEndpoint = '$baseUrl/real-estate/my-investments';
  static const String realEstateMarketplaceEndpoint = '$baseUrl/real-estate/marketplace';
  static const String realEstateSellTokensEndpoint = '$baseUrl/real-estate/sell-tokens';
  static const String realEstateTransactionsEndpoint = '$baseUrl/real-estate/transactions';
}
