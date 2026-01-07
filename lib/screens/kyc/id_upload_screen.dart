import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../../constants/colors.dart';
import 'liveness_check_screen.dart';
import '../../services/toast_service.dart';

class IDUploadScreen extends StatefulWidget {
  const IDUploadScreen({super.key});

  @override
  State<IDUploadScreen> createState() => _IDUploadScreenState();
}

class _IDUploadScreenState extends State<IDUploadScreen> {
  // 0: Front Instruction, 1: Front Camera, 2: Front Preview
  // 3: Back Instruction, 4: Back Camera, 5: Back Preview
  int _step = 0;
  bool _isProcessing = false;
  
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  bool _isCameraInitialized = false;
  
  File? _frontIDImage;
  File? _backIDImage;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
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

  Future<void> _captureImage() async {
    if (_isProcessing) return;
    
    try {
      setState(() {
        _isProcessing = true;
      });

      final image = await _cameraController.takePicture();
      final imageFile = File(image.path);
      
      if (mounted) {
        if (_step == 1) {
          // Front ID captured
          setState(() {
            _frontIDImage = imageFile;
            _isProcessing = false;
            _step = 2; // Go to preview
          });
        } else if (_step == 4) {
          // Back ID captured
          setState(() {
            _backIDImage = imageFile;
            _isProcessing = false;
            _step = 5; // Go to preview
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ToastService().showError(context, "Failed to capture image: $e");
      }
    }
  }

  void _nextStep() {
    if (_step == 0 || _step == 3) {
      // Initialize camera and move to camera step
      if (!_isCameraInitialized) {
        _initializeCamera().then((_) {
          setState(() {
            _step++;
          });
        });
      } else {
        setState(() {
          _step++;
        });
      }
    }
  }

  void _retake() {
    setState(() {
      _step--; // Go back to camera
    });
  }

  void _confirm() {
    if (_step == 2) {
      // Confirmed Front, go to Back Instruction
      setState(() {
        _step = 3;
      });
    } else if (_step == 5) {
      // Confirmed Back, go to Liveness
      if (_cameraController.value.isInitialized) {
        _cameraController.dispose();
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LivenessCheckScreen()),
      );
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
          onPressed: () {
            if (_step > 0) {
              setState(() {
                _step--;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _step < 3 ? 'Front of ID' : 'Back of ID',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_step == 0 || _step == 3) {
      return _buildInstruction();
    } else if (_step == 1 || _step == 4) {
      return _buildCamera();
    } else {
      return _buildPreview();
    }
  }

  Widget _buildInstruction() {
    final isFront = _step == 0;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1, style: BorderStyle.solid),
            ),
            child: Icon(
              isFront ? Icons.credit_card : Icons.credit_card_outlined,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            isFront ? 'Scan Front Side' : 'Scan Back Side',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isFront
                ? 'Place your ID card within the frame. Make sure the text is clear and readable.'
                : 'Turn your ID card over and scan the back side.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCamera() {
    if (!_isCameraInitialized) {
      return Center(
        child: CircularProgressIndicator(color: buttonGreen),
      );
    }

    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            children: [
              // Camera Preview
              CameraPreview(_cameraController),
              
              // Overlay with ID frame guide
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Instructions at top
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Align your ID card within the frame',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  // ID card frame guide in center
                  Expanded(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        height: 220,
                        decoration: BoxDecoration(
                          border: Border.all(color: buttonGreen, width: 3),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.transparent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              spreadRadius: 500,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Capture button at bottom
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Center(
                      child: GestureDetector(
                        onTap: _isProcessing ? null : _captureImage,
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
                          child: _isProcessing
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
    );
  }

  Widget _buildPreview() {
    final imageFile = _step == 2 ? _frontIDImage : _backIDImage;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'Check Readability',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure all details are clear and not blurry.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: buttonGreen, width: 2),
            ),
            child: imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Center(
                    child: Icon(Icons.image, size: 50, color: Colors.white),
                  ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _retake,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Retake',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Confirm',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
