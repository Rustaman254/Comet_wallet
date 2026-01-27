import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
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
          style: TextStyle(fontFamily: 'Outfit',color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: !_isCameraInitialized
          ? Center(
              child: CircularProgressIndicator(color: buttonGreen),
            )
          : FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    children: [
                      // Camera Preview
                      CameraPreview(_cameraController),
                      
                      // Overlay with instructions
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Instructions at top
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Take a Selfie',
                                    style: TextStyle(fontFamily: 'Outfit',
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Look directly at the camera and take a clear selfie',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontFamily: 'Outfit',
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Face oval guide in center
                          Center(
                            child: Container(
                              width: 200,
                              height: 240,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(120),
                                border: Border.all(
                                  color: buttonGreen,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    spreadRadius: 500,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Capture button at bottom
                          Padding(
                            padding: const EdgeInsets.only(bottom: 40.0),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _isCapturing ? null : _takeSelfie,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: buttonGreen,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                    ),
                                    child: _isCapturing
                                        ? const Padding(
                                            padding: EdgeInsets.all(20.0),
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 35,
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tap to capture',
                                  style: TextStyle(fontFamily: 'Outfit',
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Center(
                    child: CircularProgressIndicator(color: buttonGreen),
                  );
                }
              },
            ),
    );
  }
}
