import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:mobile_scanner/mobile_scanner.dart';
import '../constants/colors.dart';
import '../constants/api_constants.dart';
import '../services/vibration_service.dart';
import '../services/wallet_service.dart';
import '../services/toast_service.dart';
import 'mobile_payment_confirm_screen.dart';
import 'send_money_screen.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> with WidgetsBindingObserver {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;
  bool _torchEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!cameraController.value.isInitialized) {
      return;
    }
    
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        // Dispose/Stop controller to release camera resources
        // cameraController.stop(); 
        // Note: MobileScanner usually handles this, but stopping explicitly can be safer
        // allowing it to resume on resume.
        break;
      case AppLifecycleState.resumed:
        // cameraController.start();
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

    // Feedback
    VibrationService.heavyImpact();

    // Attempt to parse as payment data
    try {
      final decodedData = jsonDecode(qrData);
      if (decodedData is Map<String, dynamic> &&
          (decodedData.containsKey('recipient') || decodedData.containsKey('phone')) &&
          decodedData.containsKey('amount')) {
        
        final String phone = decodedData['recipient'] ?? decodedData['phone'];
        final String amount = decodedData['amount'].toString();
        final String currency = decodedData['currency'] ?? 'KES';

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MobilePaymentConfirmScreen(
                phoneNumber: phone,
                amount: amount,
                currency: currency,
              ),
            ),
          );
        }
        return;
      }
    } catch (e) {
      // Not a valid JSON, carry on...
    }

    // Attempt to parse as payment link URL
    if (qrData.contains('/payment-links/')) {
      final parts = qrData.split('/payment-links/');
      if (parts.length > 1) {
        final token = parts.last.split('?').first; // Get token, ignoring any query params
        
        if (mounted) {
          _resolvePaymentLink(token);
        }
        return;
      }
    }

    // Show success dialog for non-payment QR codes
    _showSuccessDialog(qrData);
  }

  Future<void> _resolvePaymentLink(String token) async {
    setState(() {
      _isScanning = false;
    });

    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: buttonGreen),
          ),
        );
      }

      final details = await WalletService.getPaymentLinkDetails(token);
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading indicator

        final data = details['data'];
        if (data != null) {
          final String email = data['user']?['email'] ?? '';
          final String amount = data['amount']?.toString() ?? '0.00';

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => SendMoneyScreen(
                initialEmail: email,
                initialAmount: amount,
              ),
            ),
          );
        } else {
          ToastService().showError(context, 'Invalid payment link data');
          setState(() => _isScanning = true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading indicator
        ToastService().showError(context, 'Failed to resolve payment link: $e');
        setState(() => _isScanning = true);
      }
    }
  }

  void _showSuccessDialog(String qrData) {
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
              child: const Icon(
                Icons.check_circle_outline,
                size: 50,
                color: buttonGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'QR Code Detected!',
              style: TextStyle(fontFamily: 'Satoshi',
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                qrData,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      // Scan again
                      Navigator.pop(context);
                      setState(() {
                        _isScanning = true;
                      });
                    },
                    child: Text(
                      'Scan Again',
                      style: TextStyle(fontFamily: 'Satoshi',
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(qrData); // Return data
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Use Code',
                      style: TextStyle(fontFamily: 'Satoshi',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate scan window
    final double scanAreaSize = 280;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    
    // We want the scan window to be centered.
    // Rect.fromCenter(center: center, width: width, height: height)
    final Rect scanWindow = Rect.fromCenter(
      center: Offset(screenWidth / 2, screenHeight / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    return Scaffold(
      backgroundColor: darkBackground,
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            scanWindow: scanWindow,
            errorBuilder: (context, error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Camera Error',
                      style: TextStyle(fontFamily: 'Satoshi',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.errorCode == MobileScannerErrorCode.permissionDenied
                          ? 'Camera permission denied. Please enable it in settings.'
                          : 'Something went wrong: ${error.errorCode}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Satoshi',
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
            onDetect: _onQRCodeDetected,
          ),
          
          // Custom Overlay
          _buildOverlay(context, scanAreaSize),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context, double scanAreaSize) {
    return Column(
      children: [
        // Header (SafeArea included implicitly by structure or add it)
        SafeArea(
          child: Padding(
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
                  style: TextStyle(fontFamily: 'Satoshi',
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Expanded space to push scanner frame to center
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // QR Scanner Frame
                Container(
                  width: scanAreaSize,
                  height: scanAreaSize,
                  decoration: BoxDecoration(
                    // Transparent center
                    color: Colors.transparent, 
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // We can draw a dim background AROUND this box using ColorFiltered or ClipPath 
                      // but creating a simple overlay with corners is easier and cleaner.
                      
                      // Corner decorations
                      _buildCorner(
                        Alignment.topLeft,
                        const BorderRadius.only(topLeft: Radius.circular(20)),
                         const Border(
                          top: BorderSide(color: buttonGreen, width: 5),
                          left: BorderSide(color: buttonGreen, width: 5),
                        ),
                      ),
                      _buildCorner(
                        Alignment.topRight,
                        const BorderRadius.only(topRight: Radius.circular(20)),
                        const Border(
                          top: BorderSide(color: buttonGreen, width: 5),
                          right: BorderSide(color: buttonGreen, width: 5),
                        ),
                      ),
                      _buildCorner(
                        Alignment.bottomLeft,
                        const BorderRadius.only(bottomLeft: Radius.circular(20)),
                        const Border(
                          bottom: BorderSide(color: buttonGreen, width: 5),
                          left: BorderSide(color: buttonGreen, width: 5),
                        ),
                      ),
                      _buildCorner(
                        Alignment.bottomRight,
                        const BorderRadius.only(bottomRight: Radius.circular(20)),
                        const Border(
                          bottom: BorderSide(color: buttonGreen, width: 5),
                          right: BorderSide(color: buttonGreen, width: 5),
                        ),
                      ),
                      
                      // Animated scanning line could go here
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
                    style: TextStyle(fontFamily: 'Satoshi',
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
        
        // Bottom controls
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
                style: TextStyle(fontFamily: 'Satoshi',
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
