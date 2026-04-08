/// Smile ID configuration constants.
///
/// Environment is driven by [useSandbox]. Toggle this single flag
/// to switch every Smile ID call between sandbox and production.
class SmileIDConfig {
  SmileIDConfig._();

  // ── Environment toggle ───────────────────────────────────────────
  /// Set to `false` before shipping a production build.
  static const bool useSandbox = true;

  // ── Partner credentials ──────────────────────────────────────────
  static const String partnerId = '6482';
  static const String authToken = '7bd88c7b-801b-420a-b35b-86d7a232ba70';

  // ── Base URLs ────────────────────────────────────────────────────
  static const String prodBaseUrl =
      'https://api.smileidentity.com/v1';
  static const String sandboxBaseUrl =
      'https://testapi.smileidentity.com/v1';

  /// The URL Smile ID will POST job results to on your backend.
  static const String callbackUrl =
      'https://api.fusionfi.io/api/v1/kyc/smile-id-callback';

  // ── Default country / document for Kenyan ID ─────────────────────
  static const String defaultCountryCode = 'KE';
  static const String defaultDocumentType = 'NATIONAL_ID';
}
