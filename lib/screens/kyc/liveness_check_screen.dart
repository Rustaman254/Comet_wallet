import 'package:flutter/material.dart';
import 'package:smile_id/products/selfie/smile_id_smart_selfie_enrollment.dart';
import 'kra_verification_screen.dart';
import '../../constants/colors.dart';
import '../home_screen.dart';
import '../../services/toast_service.dart';
import '../../services/token_service.dart';

class LivenessCheckScreen extends StatefulWidget {
  const LivenessCheckScreen({super.key});

  @override
  State<LivenessCheckScreen> createState() => _LivenessCheckScreenState();
}

class _LivenessCheckScreenState extends State<LivenessCheckScreen> {
  String? _userId;
  bool _isSmileIDReady = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _ensureSmileIDReady();
  }

  Future<void> _ensureSmileIDReady() async {
    // Wait to ensure SmileID native initialization is complete
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isSmileIDReady = true;
      });
    }
  }

  Future<void> _loadUserId() async {
    final userId = await TokenService.getUserId();
    if (mounted) {
      setState(() {
        _userId = userId ?? "user_${DateTime.now().millisecondsSinceEpoch}";
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Selfie Verification',
          style: TextStyle(fontFamily: 'Satoshi',color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _userId == null || !_isSmileIDReady
          ? const Center(child: CircularProgressIndicator(color: buttonGreen))
          : SmileIDSmartSelfieEnrollment(
              userId: _userId!,
              allowNewEnroll: true,
        showInstructions: true,
        onSuccess: (result) {
          ToastService().showSuccess(context, "Liveness check successful");
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const KRAVerificationScreen()),
          );
        },
        onError: (error) {
          ToastService().showError(context, "Liveness verification failed: $error");
        },
      ),
    );
  }
}
