import 'package:flutter/material.dart';
import 'package:flutter_idensic_mobile_sdk_plugin/flutter_idensic_mobile_sdk_plugin.dart';

import '../../constants/colors.dart';
import '../../services/sumsub_kyc_service.dart';
import '../../services/token_service.dart';
import '../../services/logger_service.dart';
import '../home_screen.dart';

/// Screen that initialises and launches the Sumsub KYC SDK, then displays
/// the verification result and allows re-launch if needed.
class SumsubKycScreen extends StatefulWidget {
  final Widget? nextScreen;

  const SumsubKycScreen({
    super.key,
    this.nextScreen,
  });

  @override
  State<SumsubKycScreen> createState() => _SumsubKycScreenState();
}

class _SumsubKycScreenState extends State<SumsubKycScreen> {
  bool _isLoading = true;
  bool _isSdkRunning = false;
  String? _errorMessage;
  String? _kycStatus; // e.g. "completed", "pending", "rejected"
  String? _applicantId;

  @override
  void initState() {
    super.initState();
    _launchSumsubKyc();
  }

  // ─────────────────────────────────────────────
  // Core flow
  // ─────────────────────────────────────────────

  Future<void> _launchSumsubKyc() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Get access token from backend
      final initResponse = await SumsubKycService.initKyc();
      final String accessToken = initResponse['token'] as String;
      _applicantId = initResponse['applicantId'] as String?;

      AppLogger.info(
        LogTags.kyc,
        'Sumsub KYC init success',
        data: {
          'applicantId': _applicantId,
          'userId': initResponse['userId'],
        },
      );

      setState(() {
        _isLoading = false;
        _isSdkRunning = true;
      });

      // 2. Build and launch the SDK
      final onTokenExpiration = () async {
        final refreshResponse = await SumsubKycService.initKyc();
        return refreshResponse['token'] as String;
      };

      final SNSStatusChangedHandler onStatusChanged =
          (SNSMobileSDKStatus newStatus, SNSMobileSDKStatus prevStatus) {
        AppLogger.info(
          LogTags.kyc,
          'Sumsub SDK status changed',
          data: {
            'from': prevStatus.toString(),
            'to': newStatus.toString(),
          },
        );
      };

      final snsMobileSDK = SNSMobileSDK.init(accessToken, onTokenExpiration)
          .withHandlers(onStatusChanged: onStatusChanged)
          .withDebug(true)
          .withLocale(const Locale('en'))
          .build();

      final SNSMobileSDKResult result = await snsMobileSDK.launch();

      AppLogger.info(
        LogTags.kyc,
        'Sumsub SDK completed',
        data: {'result': result.toString()},
      );

      // 3. After SDK closes, fetch status from backend
      await _fetchKycStatus();
    } catch (e) {
      AppLogger.error(
        LogTags.kyc,
        'Sumsub KYC launch error',
        data: {'error': e.toString()},
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSdkRunning = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _fetchKycStatus() async {
    try {
      final statusResponse = await SumsubKycService.getKycStatus();
      final status = (statusResponse['status'] as String?)?.toLowerCase();

      if (mounted) {
        setState(() {
          _kycStatus = status;
          _isSdkRunning = false;
        });
      }

      // Persist locally if approved
      if (status == 'completed' || status == 'approved') {
        await TokenService.saveKycVerified(true);
      }
    } catch (e) {
      AppLogger.error(
        LogTags.kyc,
        'Sumsub fetch status error',
        data: {'error': e.toString()},
      );
      if (mounted) {
        setState(() {
          _isSdkRunning = false;
          _kycStatus = 'unknown';
        });
      }
    }
  }

  // ─────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : lightPrimaryText,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Identity Verification',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: isDark ? Colors.white : lightPrimaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    // Loading state
    if (_isLoading || _isSdkRunning) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: primaryBrandColor),
            const SizedBox(height: 24),
            Text(
              _isSdkRunning
                  ? 'Verification in progress…'
                  : 'Initialising verification…',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                color: isDark ? Colors.white70 : lightSecondaryText,
              ),
            ),
          ],
        ),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return _buildStatusView(
        isDark: isDark,
        icon: Icons.error_outline,
        iconColor: errorRed,
        title: 'Something went wrong',
        subtitle: _errorMessage!,
        actionLabel: 'Retry',
        onAction: _launchSumsubKyc,
      );
    }

    // Status result
    switch (_kycStatus) {
      case 'completed':
      case 'approved':
        return _buildStatusView(
          isDark: isDark,
          icon: Icons.verified,
          iconColor: successGreen,
          title: 'KYC Approved',
          subtitle:
              'Your identity has been verified. You now have full access to all features.',
          actionLabel: 'Continue',
          onAction: () {
            if (widget.nextScreen != null) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => widget.nextScreen!),
              );
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            }
          },
        );
      case 'pending':
      case 'init':
      case 'queued':
        return _buildStatusView(
          isDark: isDark,
          icon: Icons.hourglass_top_rounded,
          iconColor: warningOrange,
          title: 'KYC Pending',
          subtitle:
              'Your documents are being reviewed. This usually takes a few minutes.',
          actionLabel: 'Continue',
          onAction: () {
            if (widget.nextScreen != null) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => widget.nextScreen!),
              );
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            }
          },
        );
      case 'rejected':
        return _buildStatusView(
          isDark: isDark,
          icon: Icons.cancel_outlined,
          iconColor: errorRed,
          title: 'KYC Rejected',
          subtitle:
              'Your verification was not successful. Please try again with valid documents.',
          actionLabel: 'Retry Verification',
          onAction: _launchSumsubKyc,
        );
      default:
        return _buildStatusView(
          isDark: isDark,
          icon: Icons.info_outline,
          iconColor: primaryBrandColor,
          title: 'Verification Status Unknown',
          subtitle: 'We couldn\'t determine your verification status.',
          actionLabel: 'Retry',
          onAction: _launchSumsubKyc,
        );
    }
  }

  Widget _buildStatusView({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: iconColor),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : lightPrimaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              color: isDark ? Colors.white70 : lightSecondaryText,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBrandColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
