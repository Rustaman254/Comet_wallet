import 'package:flutter/material.dart';
import 'package:smile_id/products/selfie/smile_id_smart_selfie_enrollment.dart';
import 'package:camera/camera.dart';
import 'kra_verification_screen.dart';
import '../../constants/colors.dart';
import '../home_screen.dart';
import '../../services/toast_service.dart';

class LivenessCheckScreen extends StatefulWidget {
  const LivenessCheckScreen({super.key});

  @override
  State<LivenessCheckScreen> createState() => _LivenessCheckScreenState();
}

class _LivenessCheckScreenState extends State<LivenessCheckScreen> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      
      if (cameras.isEmpty) {
        if (mounted) {
          ToastService().showError(context, "No camera found on this device");
        }
        return;
      }
      
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = _cameraController.initialize();
      
      await _initializeControllerFuture;
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastService().showError(context, "Failed to initialize camera: $e");
      }
    }
  }

  Future<void> _takeSelfie() async {
    if (_isCapturing) return;
    
    try {
      setState(() {
        _isCapturing = true;
      });

      if (!_cameraController.value.isInitialized) {
        throw Exception('Camera not initialized');
      }

      await _cameraController.takePicture();
      
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
        
        ToastService().showSuccess(context, "Selfie captured successfully");
        
        // Navigate to home after successful capture
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          if (_cameraController.value.isInitialized) {
            await _cameraController.dispose();
          }
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
        ToastService().showError(context, "Failed to capture selfie: $e");
      }
    }
  }

  @override
  void dispose() {
    if (_cameraController.value.isInitialized) {
      _cameraController.dispose();
    }
    super.dispose();
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
      body: SmileIDSmartSelfieEnrollment(
        userId: "user_${DateTime.now().millisecondsSinceEpoch}",
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
