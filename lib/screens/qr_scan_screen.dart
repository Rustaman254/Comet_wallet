import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../constants/colors.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;
  bool _torchEnabled = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onQRCodeDetected(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrData = barcodes.first.rawValue;
    if (qrData == null || qrData.isEmpty) return;

    setState(() {
      _isScanning = false;
    });

    // Stop the camera
    cameraController.stop();

    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: buttonGreen.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 50,
                color: buttonGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'QR Code Detected!',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              qrData,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close scanner
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera view
            MobileScanner(
              controller: cameraController,
              onDetect: _onQRCodeDetected,
            ),
            // Overlay with scanning frame
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Scan QR Code',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Scanner area
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // QR Scanner Frame
                        Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: buttonGreen,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              // Corner decorations
                              _buildCorner(
                                Alignment.topLeft,
                                const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                ),
                                const Border(
                                  top: BorderSide(
                                    color: buttonGreen,
                                    width: 5,
                                  ),
                                  left: BorderSide(
                                    color: buttonGreen,
                                    width: 5,
                                  ),
                                ),
                              ),
                              _buildCorner(
                                Alignment.topRight,
                                const BorderRadius.only(
                                  topRight: Radius.circular(20),
                                ),
                                const Border(
                                  top: BorderSide(
                                    color: buttonGreen,
                                    width: 5,
                                  ),
                                  right: BorderSide(
                                    color: buttonGreen,
                                    width: 5,
                                  ),
                                ),
                              ),
                              _buildCorner(
                                Alignment.bottomLeft,
                                const BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                ),
                                const Border(
                                  bottom: BorderSide(
                                    color: buttonGreen,
                                    width: 5,
                                  ),
                                  left: BorderSide(
                                    color: buttonGreen,
                                    width: 5,
                                  ),
                                ),
                              ),
                              _buildCorner(
                                Alignment.bottomRight,
                                const BorderRadius.only(
                                  bottomRight: Radius.circular(20),
                                ),
                                const Border(
                                  bottom: BorderSide(
                                    color: buttonGreen,
                                    width: 5,
                                  ),
                                  right: BorderSide(
                                    color: buttonGreen,
                                    width: 5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Instructions
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Position the QR code within the frame',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom section
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Flash toggle button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _torchEnabled = !_torchEnabled;
                          });
                          cameraController.toggleTorch();
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _torchEnabled ? Icons.flash_on : Icons.flash_off,
                            color: _torchEnabled ? buttonGreen : Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap to toggle flash',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(
    Alignment alignment,
    BorderRadius borderRadius,
    Border border,
  ) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: border,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
