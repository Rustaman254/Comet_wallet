import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/colors.dart';
import '../services/vibration_service.dart';
import '../services/toast_service.dart';
import '../services/wallet_service.dart';
import '../services/token_service.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../utils/responsive_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';
import 'sign_in_screen.dart';
import 'transaction_details_screen.dart';
import '../models/transaction.dart';
import '../widgets/transaction_result_overlay.dart';

class EnterPinScreen extends StatefulWidget {
  final String recipientName;
  final String amount;
  final String currency;
  final String description;
  final Future<Map<String, dynamic>> Function(String pin)? onVerify;

  const EnterPinScreen({
    super.key,
    required this.recipientName,
    required this.amount,
    required this.currency,
    this.description = 'Money transfer',
    this.onVerify,
  });

  @override
  State<EnterPinScreen> createState() => _EnterPinScreenState();
}

class _EnterPinScreenState extends State<EnterPinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isVerifying = false;
  String? _processingTransactionId;
  TransactionOverlayController? _overlayController;
  
  // Biometric state
  bool _biometricsAvailable = false;
  bool _hasFaceID = false;
  bool _isBiometricScanning = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -10, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Check biometric availability
    _checkBiometrics();
  }
  
  Future<void> _checkBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('biometric_enabled') ?? false;
    
    if (!isEnabled) {
      if (mounted) setState(() => _biometricsAvailable = false);
      return;
    }

    final isAvailable = await BiometricService.isAvailable();
    final hasFace = await BiometricService.hasFaceID();
    final hasFingerprint = await BiometricService.hasFingerprint();
    
    if (mounted) {
      setState(() {
        _biometricsAvailable = isAvailable;
        _hasFaceID = hasFace;
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    if (_pin.length < 4 && !_isVerifying) {
      VibrationService.selectionClick();
      setState(() {
        _pin += number;
      });

      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty && !_isVerifying) {
      VibrationService.selectionClick();
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _showOverlay({String message = 'Processing Transaction…'}) {
    setState(() => _isVerifying = true);
    _overlayController = TransactionOverlayController.show(
      context,
      initialMessage: message,
    );
  }

  void _dismissOverlay() {
    _overlayController?.dismiss();
    _overlayController = null;
    if (mounted) setState(() => _isVerifying = false);
  }

  void _navigateToTransactionDetails(Transaction transaction) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TransactionDetailsScreen(
          transaction: transaction,
          fromTransaction: true,
        ),
      ),
    );
  }

  Future<void> _handleTransactionResponse(Map<String, dynamic> response) async {
    final transactionId = response['transaction_id'] ?? 
                         response['gateway_transaction_id'] ?? 
                         response['transactionId'] ?? 
                         response['id'];

    if (transactionId != null) {
      final idStr = transactionId.toString();
      _overlayController?.showLoading(message: 'Processing Transaction…');
      setState(() => _processingTransactionId = idStr);
      context.read<WalletBloc>().add(TrackTransactionStatus(transactionId: idStr));
    } else {
      // No transaction ID returned — show inline success
      VibrationService.lightImpact();
      _overlayController?.showSuccess(
        title: 'Transaction Successful',
        subtitle: '${widget.currency} ${widget.amount} withdrawn to ${widget.recipientName}',
        onAutoDismiss: () {
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      );
    }
  }

  Future<void> _verifyPin() async {
    _showOverlay(message: 'Processing Transaction…');

    try {
      // 1. Verify PIN via API
      final isVerified = await AuthService.verifyPin(_pin);

      if (!isVerified) {
        _dismissOverlay();
        if (mounted) {
          VibrationService.errorVibrate();
          _shakeController.forward(from: 0.0).then((_) {
            if (mounted) setState(() => _pin = '');
          });
          ToastService().showError(context, 'Wrong PIN.');
        }
        return;
      }

      // 2. PIN Verified, proceed with transaction
      _overlayController?.showLoading(message: 'Processing Transaction…');

      Map<String, dynamic> response;
      if (widget.onVerify != null) {
        response = await widget.onVerify!(_pin);
      } else {
        final amount = double.tryParse(widget.amount.replaceAll(',', '')) ?? 0.0;
        response = await WalletService.sendMoney(
          recipientPhone: widget.recipientName,
          amount: amount,
          currency: widget.currency,
          description: widget.description,
          pin: _pin,
        );
      }

      if (mounted) await _handleTransactionResponse(response);
    } on TokenExpiredException catch (_) {
      _dismissOverlay();
      if (!mounted) return;
      await TokenService.logout();
      if (mounted && context.mounted) {
        ToastService().showError(context, 'Session expired. Please login again.');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString();

      final isNetworkError = e is SocketException ||
          e is http.ClientException ||
          errorMsg.contains('SocketException') ||
          errorMsg.contains('Failed host lookup') ||
          errorMsg.contains('Connection refused');

      if (isNetworkError) {
        _dismissOverlay();
        ToastService().showError(context, 'Connection error. Please check your internet.');
        return;
      }

      if (errorMsg.contains('401') ||
          errorMsg.contains('expired') ||
          errorMsg.contains('unauthorized')) {
        _dismissOverlay();
        ToastService().showError(context, 'Session expired. Please login again.');
        await TokenService.logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SignInScreen()),
            (route) => false,
          );
        }
      } else {
        final friendlyMessage = _parseErrorMessage(errorMsg);
        _overlayController?.showFailure(
          message: friendlyMessage,
          onRetry: () {
            setState(() => _pin = '');
          },
          onCancel: () {
            if (mounted) Navigator.of(context).pop();
          },
        );
      }
    }
  }

  Future<void> _onBiometric() async {
    if (!_biometricsAvailable || _isVerifying) return;

    try {
      final authenticated = await BiometricService.authenticate(
        localizedReason: 'Authenticate to authorize this payment',
        useErrorDialogs: true,
        stickyAuth: true,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => false,
      );

      if (!mounted) return;

      if (authenticated) {
        _showOverlay(message: 'Processing Transaction…');

        try {
          Map<String, dynamic> response;
          if (widget.onVerify != null) {
            response = await widget.onVerify!(_pin);
          } else {
            final amount = double.tryParse(widget.amount.replaceAll(',', '')) ?? 0.0;
            response = await WalletService.sendMoney(
              recipientPhone: widget.recipientName,
              amount: amount,
              currency: widget.currency,
              description: widget.description,
            );
          }

          if (mounted) await _handleTransactionResponse(response);
        } on TokenExpiredException catch (_) {
          _dismissOverlay();
          if (!mounted) return;
          await TokenService.logout();
          if (mounted && context.mounted) {
            ToastService().showError(context, 'Session expired. Please login again.');
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SignInScreen()),
              (route) => false,
            );
          }
        } catch (e) {
          if (!mounted) return;
          final errorMsg = e.toString();

          final isNetworkError = e is SocketException ||
              e is http.ClientException ||
              errorMsg.contains('SocketException') ||
              errorMsg.contains('Failed host lookup') ||
              errorMsg.contains('Connection refused');

          if (isNetworkError ||
              errorMsg.contains('401') ||
              errorMsg.contains('expired') ||
              errorMsg.contains('unauthorized')) {
            _dismissOverlay();
            ToastService().showError(context, 'Session expired. Please login again.');
            await TokenService.logout();
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                (route) => false,
              );
            }
          } else {
            final friendlyMessage = _parseErrorMessage(errorMsg);
            _overlayController?.showFailure(
              message: friendlyMessage,
              onRetry: () {
                setState(() => _pin = '');
              },
              onCancel: () {
                if (mounted) Navigator.of(context).pop();
              },
            );
          }
        }
      } else {
        VibrationService.errorVibrate();
      }
    } catch (e) {
      debugPrint('Biometric error: $e');
      if (mounted) VibrationService.errorVibrate();
    }
  }

  String _parseErrorMessage(String error) {
    String cleaned = error.replaceAll('Exception:', '').trim();

    if (cleaned.toLowerCase().contains('socketexception') ||
        cleaned.toLowerCase().contains('failed host lookup') ||
        cleaned.toLowerCase().contains('network')) {
      return 'Network connection error. Please check your internet connection and try again.';
    }
    if (cleaned.toLowerCase().contains('insufficient')) return cleaned;
    if (cleaned.toLowerCase().contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (cleaned.toLowerCase().contains('not found') ||
        cleaned.toLowerCase().contains('404')) {
      return 'Recipient not found. Please verify the phone number.';
    }
    if (cleaned.toLowerCase().contains('unauthorized') ||
        cleaned.toLowerCase().contains('401')) {
      return 'Session expired. Please login again.';
    }
    if (!cleaned.contains('error:') &&
        !cleaned.contains('Error:') &&
        cleaned.length < 100) {
      return cleaned;
    }
    return 'Transaction failed. Please try again or contact support.';
  }

  Widget _buildDashPin() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final isFilled = index < _pin.length;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: SizedBox(
              width: 32.w,
              height: 32.h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dash background
                  Positioned(
                    bottom: 8.h,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 2.h,
                      width: 32.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999.r),
                        color: isFilled
                            ? primaryBrandColor
                            : (isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                  // Asterisk when filled
                  if (isFilled)
                    Text(
                      '*',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((n) => _buildKeypadButton(n)).toList(),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((n) => _buildKeypadButton(n)).toList(),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((n) => _buildKeypadButton(n)).toList(),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeyActionButton(
              onPressed: _onBackspace,
              icon: Icons.backspace_outlined,
            ),
            _buildKeypadButton('0'),
            _biometricsAvailable
                ? _buildKeyActionButton(
                    onPressed: _onBiometric,
                    icon: _hasFaceID ? Icons.face : Icons.fingerprint,
                    color: primaryBrandColor,
                  )
                : SizedBox(width: 70.r, height: 70.r),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String number) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _onNumberPressed(number),
      child: Container(
        width: 70.r,
        height: 70.r,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF6F6F6),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            number,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: isDark ? Colors.white : Colors.black,
              fontSize: 24.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    Color? color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: _isVerifying ? null : onPressed,
      child: Container(
        width: 70.r,
        height: 70.r,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF6F6F6),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            color: color ?? (isDark ? Colors.white : Colors.black),
            size: 24.r,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is TransactionStatusUpdate &&
            state.transactionId == _processingTransactionId) {
          final status = state.status.toLowerCase();
          if (status == 'completed' || status == 'success' || status == 'complete') {
            WalletService.getTransactionStatus(state.transactionId)
                .then((transaction) {
              if (!mounted) return;
              if (transaction != null) {
                _overlayController?.showSuccess(
                  title: 'Transaction Successful',
                  subtitle:
                      '${widget.currency} ${widget.amount} withdrawn to ${widget.recipientName}',
                  onAutoDismiss: () => _navigateToTransactionDetails(transaction),
                );
              } else {
                _overlayController?.showSuccess(
                  title: 'Transaction Successful',
                  subtitle:
                      '${widget.currency} ${widget.amount} withdrawn to ${widget.recipientName}',
                  onAutoDismiss: () {
                    if (mounted) {
                      Navigator.of(context)
                          .popUntil((route) => route.isFirst);
                    }
                  },
                );
              }
            });
          } else if (status == 'timeout') {
            _overlayController?.showFailure(
              message: 'Request timed out. ${state.message}',
              onRetry: () => _verifyPin(),
              onCancel: () {
                if (mounted) Navigator.of(context).pop();
              },
            );
          } else if (status == 'failed') {
            _overlayController?.showFailure(
              message: state.message.isNotEmpty ? state.message : 'Transaction failed. Please try again.',
              onRetry: () {
                setState(() => _pin = '');
              },
              onCancel: () {
                if (mounted) Navigator.of(context).pop();
              },
            );
          }
          // Ignore other intermediate statuses like 'pending', 'initiated', etc.
        }
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              // Back button
              GestureDetector(
                onTap: _isVerifying ? null : () => Navigator.pop(context),
                child: Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white.withValues(alpha: 0.1) 
                        : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: getTextColor(context),
                    size: 20.r,
                  ),
                ),
              ),
              SizedBox(height: 40.h),
              Text(
                'Enter your PIN',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: getTextColor(context),
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Confirm this transaction securely.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: getSecondaryTextColor(context),
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 32.h),
              // Amount & recipient (still themed)
              Text(
                '${widget.currency} ${widget.amount}',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: primaryBrandColor,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'to ${widget.recipientName}',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: getTextColor(context),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 40.h),
              // PIN dashes
              _buildDashPin(),
              const Spacer(),
              _buildKeypad(),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
