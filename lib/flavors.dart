enum Flavor {
  sandbox,
  production,
}

class F {
  static Flavor? appFlavor;

  static String get name => appFlavor?.name ?? '';

  static String get title {
    switch (appFlavor) {
      case Flavor.sandbox:
        return 'Fusionfi_Sandbox';
      case Flavor.production:
        return 'Fusionfi';
      default:
        return 'Fusionfi';
    }
  }

  static String get baseUrl {
    switch (appFlavor) {
      case Flavor.sandbox:
        return 'https://sandbox.fusionfi.io/api/v1';
      case Flavor.production:
        return 'https://api.fusionfi.io/api/v1';
      default:
        return 'https://api.fusionfi.io/api/v1';
    }
  }
}
