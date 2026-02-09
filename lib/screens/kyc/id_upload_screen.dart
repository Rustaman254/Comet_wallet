import 'package:flutter/material.dart';
import 'package:smile_id/products/document/smile_id_document_verification.dart';
import 'package:smile_id/products/models/model.dart';
import '../../constants/colors.dart';
import 'liveness_check_screen.dart';
import '../../services/toast_service.dart';
import '../../services/token_service.dart';

class IDUploadScreen extends StatefulWidget {
  const IDUploadScreen({super.key});

  @override
  State<IDUploadScreen> createState() => _IDUploadScreenState();
}

class _IDUploadScreenState extends State<IDUploadScreen> {
  String? _userId;
  bool _isSmileIDReady = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _ensureSmileIDReady();
  }

  Future<void> _ensureSmileIDReady() async {
    // Wait an additional 2 seconds to ensure SmileID native initialization is complete
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
        title: const Text(
          'ID Verification',
          style: TextStyle(fontFamily: 'Satoshi', color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _userId == null || !_isSmileIDReady
          ? const Center(child: CircularProgressIndicator(color: buttonGreen))
          : SmileIDDocumentVerification(
              userId: _userId!,
              jobId: "job_${DateTime.now().millisecondsSinceEpoch}",
              countryCode: "KE",
              documentType: "ID_CARD",
        showInstructions: true,
        allowGalleryUpload: true,
        onSuccess: (result) {
          ToastService().showSuccess(context, "Document captured successfully");
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LivenessCheckScreen()),
          );
        },
        onError: (error) {
          ToastService().showError(context, "Document verification failed: $error");
        },
      ),
    );
  }
}
