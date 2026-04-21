class ESimProduct {
  final int id;
  final String name;
  final String price;
  final String data;
  final String validity;
  final String region;
  final String planType;
  final List<EsimCountry> countries;
  final bool globalPlan;
  final bool isRegional;
  final bool rechargeOnly;

  ESimProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.data,
    required this.validity,
    required this.region,
    required this.planType,
    required this.countries,
    required this.globalPlan,
    required this.isRegional,
    required this.rechargeOnly,
  });

  factory ESimProduct.fromJson(Map<String, dynamic> json) {
    return ESimProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] ?? '0.00',
      data: json['data'] ?? '',
      validity: json['validity'] ?? '',
      region: json['region'] ?? '',
      planType: json['planType'] ?? '',
      countries: (json['countries'] as List?)
              ?.map((c) => EsimCountry.fromJson(c))
              .toList() ??
          [],
      globalPlan: json['global_plan'] ?? false,
      isRegional: json['isRegional'] ?? false,
      rechargeOnly: json['recharge_only'] ?? false,
    );
  }
}

class EsimCountry {
  final int id;
  final String countryName;
  final String countryCode;
  final String iso2;
  final String iso3;
  final String phoneCode;

  EsimCountry({
    required this.id,
    required this.countryName,
    required this.countryCode,
    required this.iso2,
    required this.iso3,
    required this.phoneCode,
  });

  factory EsimCountry.fromJson(Map<String, dynamic> json) {
    return EsimCountry(
      id: json['id'] ?? 0,
      countryName: json['country_name'] ?? '',
      countryCode: json['country_code'] ?? '',
      iso2: json['iso2'] ?? '',
      iso3: json['iso3'] ?? '',
      phoneCode: json['phone_code'] ?? '',
    );
  }
}

class ESimOrderRequest {
  final String orderId;
  final int planId;
  final String planName;
  final double planPriceUsd;

  ESimOrderRequest({
    required this.orderId,
    required this.planId,
    required this.planName,
    required this.planPriceUsd,
  });

  factory ESimOrderRequest.fromJson(Map<String, dynamic> json) {
    return ESimOrderRequest(
      orderId: json['order_id'] ?? '',
      planId: json['plan_id'] ?? 0,
      planName: json['plan_name'] ?? '',
      planPriceUsd: (json['plan_price_usd'] is num)
          ? (json['plan_price_usd'] as num).toDouble()
          : 0.0,
    );
  }
}

class ESimOrderCompleteResponse {
  final String? conversionAction;
  final double currentUsd;
  final String? error;
  final String message;
  final double requiredUsd;
  final double shortfallUsd;
  final bool isSuccess;

  ESimOrderCompleteResponse({
    this.conversionAction,
    required this.currentUsd,
    this.error,
    required this.message,
    required this.requiredUsd,
    required this.shortfallUsd,
    required this.isSuccess,
  });

  factory ESimOrderCompleteResponse.fromJson(Map<String, dynamic> json) {
    return ESimOrderCompleteResponse(
      conversionAction: json['conversion_action'],
      currentUsd: (json['current_usd'] is num) ? (json['current_usd'] as num).toDouble() : 0.0,
      error: json['error'],
      message: json['message'] ?? '',
      requiredUsd: (json['required_usd'] is num) ? (json['required_usd'] as num).toDouble() : 0.0,
      shortfallUsd: (json['shortfall_usd'] is num) ? (json['shortfall_usd'] as num).toDouble() : 0.0,
      isSuccess: json['status'] == 'success',
    );
  }
}
