/// Persona configuration constants.
///
/// Environment is driven by [useSandbox]. Toggle this single flag
/// to switch every Persona call between sandbox and production.
class PersonaConfig {
  PersonaConfig._();

  // ── Environment toggle ───────────────────────────────────────────
  /// Set to `false` before shipping a production build.
  static const bool useSandbox = true;

  // ── Template & API credentials ───────────────────────────────────
  static const String templateId = 'tmpl_xxxxxxxx';
  static const String apiKey = 'your_api_key_here';

  // ── Base URLs ────────────────────────────────────────────────────
  static const String prodBaseUrl =
      'https://persona-api.personatech.com';
  static const String sandboxBaseUrl =
      'https://persona-api.sandbox.personatech.com';

  /// The URL Persona will POST job results to on your backend.
  static const String callbackUrl =
      'https://api.fusionfi.io/api/v1/kyc/persona-callback';

  // ── Default country / document for Kenyan ID ─────────────────────
  static const String defaultCountryCode = 'KE';
  static const String defaultDocumentType = 'NATIONAL_ID';
}
