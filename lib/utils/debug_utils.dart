import '../services/token_service.dart';
import '../services/logger_service.dart';

/// Debug utilities to troubleshoot token issues
class DebugUtils {
  /// Print current token status to console
  static Future<void> printTokenStatus() async {
    AppLogger.info(
      'DEBUG',
      '========== TOKEN STATUS DEBUG ==========',
    );

    try {
      final debugInfo = await TokenService.debugTokenData();
      AppLogger.info('DEBUG', 'Token Debug Info: $debugInfo');

      final userData = await TokenService.getUserData();
      AppLogger.info('DEBUG', 'User Data: $userData');

      final isAuth = await TokenService.isAuthenticated();
      AppLogger.info('DEBUG', 'Is Authenticated: $isAuth');
    } catch (e) {
      AppLogger.error('DEBUG', 'Error getting token status: $e');
    }

    AppLogger.info('DEBUG', '========== END TOKEN STATUS DEBUG ==========');
  }

  /// Verify token is accessible in wallet service
  static Future<void> verifyTokenForWallet() async {
    AppLogger.info('DEBUG', '========== WALLET TOKEN VERIFICATION ==========');

    try {
      final token = await TokenService.getToken();
      AppLogger.info(
        'DEBUG',
        'Token in wallet context',
        data: {
          'token_null': token == null,
          'token_empty': token?.isEmpty ?? true,
          'token_length': token?.length ?? 0,
        },
      );

      if (token != null && token.isNotEmpty) {
        AppLogger.success(
          'DEBUG',
          'Token is available for wallet operations',
          data: {
            'preview': '${token.substring(0, 20)}...',
          },
        );
      } else {
        AppLogger.error('DEBUG', 'Token is NOT available for wallet operations!');
      }
    } catch (e) {
      AppLogger.error('DEBUG', 'Error verifying wallet token: $e');
    }

    AppLogger.info('DEBUG', '========== END WALLET TOKEN VERIFICATION ==========');
  }

  /// Complete diagnostics
  static Future<void> runFullDiagnostics() async {
    AppLogger.info('DEBUG', '╔════════════════════════════════════════╗');
    AppLogger.info('DEBUG', '║  COMET WALLET - TOKEN DIAGNOSTICS  ║');
    AppLogger.info('DEBUG', '╚════════════════════════════════════════╝');

    await printTokenStatus();
    await verifyTokenForWallet();

    AppLogger.info('DEBUG', 'Diagnostics complete. Check logs above for issues.');
  }
}
