import 'package:flutter/material.dart';
import 'package:smile_id/products/selfie/smile_id_smart_selfie_enrollment.dart';
import 'package:smile_id/products/document/smile_id_document_verification.dart';
import 'package:smile_id/products/biometric/smile_id_biometric_kyc.dart';
import '../../constants/colors.dart';
import '../../constants/smile_id_config.dart';
import '../../services/kyc_service.dart';
import '../../services/token_service.dart';
import '../../services/toast_service.dart';
import '../../services/smile_id_init_service.dart';
import '../../models/kyc_model.dart';
import '../home_screen.dart';

/// The possible verification flows the user can pick.
enum _KycFlow { smartSelfie, documentVerification, biometricKyc }

class SmileIDKycScreen extends StatefulWidget {
  const SmileIDKycScreen({super.key});

  @override
  State<SmileIDKycScreen> createState() => _SmileIDKycScreenState();
}

class _SmileIDKycScreenState extends State<SmileIDKycScreen> {
  bool _smileReady = false;
  bool _initFailed = false;
  String? _userId;
  _KycFlow? _activeFlow;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _ensureSmileReady();
  }

  // ── Initialisation helpers ───────────────────────────────────────

  Future<void> _loadUserId() async {
    final id = await TokenService.getUserId();
    if (mounted) {
      setState(() {
        _userId = id ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
      });
    }
  }

  Future<void> _ensureSmileReady() async {
    try {
      // Ensure SmileID SDK is fully initialized before proceeding
      // This critical step ensures the native fileSavePath is properly set up
      await SmileIDInitService.ensureInitialized();

      // Ready for Smile ID flow
      if (mounted) setState(() => _smileReady = true);
    } catch (e) {
      debugPrint('SmileID readiness check failed: $e');
      if (mounted) {
        setState(() {
          _smileReady = false;
          _initFailed = true;
        });
      }
    }
  }

  // ── Job helpers ──────────────────────────────────────────────────

  String get _jobId => 'job_${DateTime.now().millisecondsSinceEpoch}';

  /// Called when any Smile ID flow succeeds.
  Future<void> _onFlowSuccess(dynamic result) async {
    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      final userIdStr = await TokenService.getUserId() ?? '0';
      final userIdInt = int.tryParse(userIdStr) ?? 0;

      final kycData = KYCData(
        userID: userIdInt,
        idDocumentFront: 'smile_id_verified',
        idDocumentBack: 'smile_id_verified',
        kraDocument: '',
        profilePhoto: 'smile_id_selfie',
        proofOfAddress: '',
      );

      await KYCService.submitKYC(kycData);

      if (mounted) {
        ToastService().showSuccess(context, 'Identity verified successfully!');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ToastService().showError(
          context,
          'Verification succeeded but submission failed. Please try again.',
        );
        setState(() {
          _activeFlow = null;
          _isSubmitting = false;
        });
      }
    }
  }

  /// Called when any Smile ID flow fails or is cancelled.
  void _onFlowError(dynamic error) {
    if (!mounted) return;
    setState(() => _activeFlow = null);
    ToastService().showError(
      context,
      'Verification was not completed. Please try again.',
    );
  }

  // ── Build methods ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // If a flow is active, show the SDK screen full-screen.
    if (_activeFlow != null && _userId != null) {
      return _buildActiveFlow();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : lightPrimaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Smile ID Verification',
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: isDark ? Colors.white : lightPrimaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // ── Status banner ────────────────────────────────────
              _buildStatusBanner(isDark),
              const SizedBox(height: 32),

              // ── Info section ─────────────────────────────────────
              _buildInfoSection(isDark),
              const SizedBox(height: 32),

              // ── Flow cards ───────────────────────────────────────
              Expanded(
                child: ListView(
                  children: [
                    _buildFlowCard(
                      isDark: isDark,
                      icon: Icons.face,
                      title: 'Smart Selfie',
                      subtitle:
                          'Quick selfie-based liveness and identity check',
                      flow: _KycFlow.smartSelfie,
                    ),
                    const SizedBox(height: 16),
                    _buildFlowCard(
                      isDark: isDark,
                      icon: Icons.badge_outlined,
                      title: 'Document Verification',
                      subtitle:
                          'Scan your national ID card for verification',
                      flow: _KycFlow.documentVerification,
                    ),
                    const SizedBox(height: 16),
                    _buildFlowCard(
                      isDark: isDark,
                      icon: Icons.fingerprint,
                      title: 'Biometric KYC',
                      subtitle:
                          'Full biometric check: selfie + ID document',
                      flow: _KycFlow.biometricKyc,
                    ),
                  ],
                ),
              ),

              // ── Primary CTA ──────────────────────────────────────
              const SizedBox(height: 16),
              _buildEnvironmentBadge(isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Active flow screen ───────────────────────────────────────────

  Widget _buildActiveFlow() {
    switch (_activeFlow!) {
      case _KycFlow.smartSelfie:
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() => _activeFlow = null),
            ),
            title: const Text('Smart Selfie',
                style: TextStyle(fontFamily: 'Satoshi', color: Colors.white)),
            centerTitle: true,
          ),
          body: SmileIDSmartSelfieEnrollment(
            userId: _userId!,
            allowNewEnroll: true,
            showInstructions: true,
            onSuccess: _onFlowSuccess,
            onError: _onFlowError,
          ),
        );
      case _KycFlow.documentVerification:
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() => _activeFlow = null),
            ),
            title: const Text('Document Verification',
                style: TextStyle(fontFamily: 'Satoshi', color: Colors.white)),
            centerTitle: true,
          ),
          body: SmileIDDocumentVerification(
            userId: _userId!,
            jobId: _jobId,
            countryCode: SmileIDConfig.defaultCountryCode,
            documentType: SmileIDConfig.defaultDocumentType,
            useStrictMode: true,
            showInstructions: true,
            allowGalleryUpload: true,
            onSuccess: (String? resultJson) {
              final snackBar = SnackBar(content: Text("Success: $resultJson"));
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
              _onFlowSuccess(resultJson);
            },
            onError: (String errorMessage) {
              final snackBar = SnackBar(content: Text("Error: $errorMessage"));
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
              _onFlowError(errorMessage);
            },
          ),
        );
      case _KycFlow.biometricKyc:
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() => _activeFlow = null),
            ),
            title: const Text('Biometric KYC',
                style: TextStyle(fontFamily: 'Satoshi', color: Colors.white)),
            centerTitle: true,
          ),
          body: SmileIDBiometricKYC(
            userId: _userId!,
            jobId: _jobId,
            country: SmileIDConfig.defaultCountryCode,
            idType: SmileIDConfig.defaultDocumentType,
            showInstructions: true,
            onSuccess: _onFlowSuccess,
            onError: _onFlowError,
          ),
        );
    }
  }

  // ── Sub-widgets ──────────────────────────────────────────────────

  Widget _buildStatusBanner(bool isDark) {
    if (_initFailed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: errorRed.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: errorRed.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: errorRed, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Smile ID failed to initialise. Please restart the app or check your connection.',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  color: isDark ? Colors.white : lightPrimaryText,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_smileReady) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: warningOrange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: warningOrange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: warningOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Preparing Smile ID…',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  color: isDark ? Colors.white : lightPrimaryText,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: successGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: successGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: successGreen, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Smile ID is ready. Choose a verification method below.',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 13,
                color: isDark ? Colors.white : lightPrimaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify Your Identity',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : lightPrimaryText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose one of the methods below. The process takes less than 2 minutes and unlocks higher transaction limits.',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 14,
            color: isDark ? Colors.white70 : lightSecondaryText,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFlowCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required _KycFlow flow,
  }) {
    final enabled = _smileReady && !_initFailed && _userId != null;
    return GestureDetector(
      onTap: enabled ? () => setState(() => _activeFlow = flow) : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: enabled ? 1.0 : 0.45,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? cardBackground : lightCardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? cardBorder : lightBorder,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: buttonGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: buttonGreen, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : lightPrimaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 13,
                        color: isDark ? Colors.white60 : lightSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white30 : lightSecondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnvironmentBadge(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: SmileIDConfig.useSandbox
                ? warningOrange.withOpacity(0.15)
                : successGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                SmileIDConfig.useSandbox
                    ? Icons.bug_report_outlined
                    : Icons.verified_outlined,
                size: 14,
                color:
                    SmileIDConfig.useSandbox ? warningOrange : successGreen,
              ),
              const SizedBox(width: 6),
              Text(
                SmileIDConfig.useSandbox ? 'Sandbox' : 'Production',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SmileIDConfig.useSandbox
                      ? warningOrange
                      : successGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
