import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';
import '../services/vibration_service.dart';

/// The current visual state of the overlay.
enum TransactionOverlayState { loading, success, failure }

/// Controller to update the overlay state from outside.
class TransactionOverlayController {
  _TransactionResultOverlayState? _state;

  void _attach(_TransactionResultOverlayState state) => _state = state;

  void showLoading({String message = 'Processing Transaction…'}) {
    _state?._updateState(TransactionOverlayState.loading, message: message);
  }

  void showSuccess({
    required String title,
    required String subtitle,
    VoidCallback? onAutoDismiss,
    Duration autoDismissDelay = const Duration(milliseconds: 2500),
  }) {
    _state?._updateState(
      TransactionOverlayState.success,
      message: title,
      subtitle: subtitle,
      onAutoDismiss: onAutoDismiss,
      autoDismissDelay: autoDismissDelay,
    );
  }

  void showFailure({
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    _state?._updateState(
      TransactionOverlayState.failure,
      message: message,
      onRetry: onRetry,
      onCancel: onCancel,
    );
  }

  void dismiss() {
    _state?._dismiss();
  }

  /// Show the overlay as a full-screen modal route.
  static TransactionOverlayController show(
    BuildContext context, {
    String initialMessage = 'Processing Transaction…',
  }) {
    final controller = TransactionOverlayController();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (ctx, anim, secondaryAnim) {
          return TransactionResultOverlay(
            controller: controller,
            initialMessage: initialMessage,
          );
        },
        transitionsBuilder: (ctx, anim, secondaryAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
    return controller;
  }
}

class TransactionResultOverlay extends StatefulWidget {
  final TransactionOverlayController controller;
  final String initialMessage;

  const TransactionResultOverlay({
    super.key,
    required this.controller,
    this.initialMessage = 'Processing Transaction…',
  });

  @override
  State<TransactionResultOverlay> createState() =>
      _TransactionResultOverlayState();
}

class _TransactionResultOverlayState extends State<TransactionResultOverlay>
    with TickerProviderStateMixin {
  TransactionOverlayState _overlayState = TransactionOverlayState.loading;
  String _message = '';
  String _subtitle = '';
  VoidCallback? _onRetry;
  VoidCallback? _onCancel;
  Timer? _autoDismissTimer;

  late AnimationController _iconAnimController;
  late Animation<double> _iconScaleAnimation;

  @override
  void initState() {
    super.initState();
    _message = widget.initialMessage;
    widget.controller._attach(this);

    _iconAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _iconScaleAnimation = CurvedAnimation(
      parent: _iconAnimController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _iconAnimController.dispose();
    super.dispose();
  }

  void _updateState(
    TransactionOverlayState newState, {
    String? message,
    String? subtitle,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
    VoidCallback? onAutoDismiss,
    Duration autoDismissDelay = const Duration(milliseconds: 2500),
  }) {
    if (!mounted) return;

    _autoDismissTimer?.cancel();

    setState(() {
      _overlayState = newState;
      if (message != null) _message = message;
      _subtitle = subtitle ?? '';
      _onRetry = onRetry;
      _onCancel = onCancel;
    });

    if (newState == TransactionOverlayState.success) {
      VibrationService.lightImpact();
      _iconAnimController.forward(from: 0);
      if (onAutoDismiss != null) {
        _autoDismissTimer = Timer(autoDismissDelay, () {
          if (mounted) {
            _dismiss();
            onAutoDismiss();
          }
        });
      }
    } else if (newState == TransactionOverlayState.failure) {
      VibrationService.errorVibrate();
      _iconAnimController.forward(from: 0);
    }
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        body: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOut,
            child: _buildContent(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    switch (_overlayState) {
      case TransactionOverlayState.loading:
        return _buildLoadingContent(isDark);
      case TransactionOverlayState.success:
        return _buildSuccessContent(isDark);
      case TransactionOverlayState.failure:
        return _buildFailureContent(isDark);
    }
  }

  Widget _buildLoadingContent(bool isDark) {
    return Container(
      key: const ValueKey('loading'),
      constraints: BoxConstraints(minWidth: 200.w, maxWidth: 300.w),
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56.r,
            height: 56.r,
            child: CircularProgressIndicator(
              color: primaryBrandColor,
              strokeWidth: 3.5,
              strokeCap: StrokeCap.round,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please do not close the app',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent(bool isDark) {
    return Container(
      key: const ValueKey('success'),
      constraints: BoxConstraints(minWidth: 200.w, maxWidth: 320.w),
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: primaryBrandColor.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _iconScaleAnimation,
            child: Container(
              width: 80.r,
              height: 80.r,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryBrandColor.withValues(alpha: 0.2),
                    primaryBrandColor.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: primaryBrandColor,
                size: 50.r,
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_subtitle.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              _subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: primaryBrandColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _autoDismissTimer?.cancel();
                _dismiss();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBrandColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'View Details',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureContent(bool isDark) {
    return Container(
      key: const ValueKey('failure'),
      constraints: BoxConstraints(minWidth: 200.w, maxWidth: 320.w),
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _iconScaleAnimation,
            child: Container(
              width: 80.r,
              height: 80.r,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.withValues(alpha: 0.2),
                    Colors.red.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_rounded,
                color: Colors.red,
                size: 50.r,
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Transaction Failed',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 28.h),
          if (_onRetry != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _dismiss();
                  _onRetry?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Try Again',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                _dismiss();
                _onCancel?.call();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white60 : Colors.black54,
                side: BorderSide(
                  color: isDark ? Colors.white24 : Colors.grey[300]!,
                ),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
