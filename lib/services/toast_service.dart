import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/custom_toast.dart';

class ToastService {
  static final ToastService _instance = ToastService._internal();
  factory ToastService() => _instance;
  ToastService._internal();

  OverlayEntry? _overlayEntry;
  Timer? _timer;

  void showSuccess(BuildContext context, String message) {
    _show(context, message, ToastType.success);
  }

  void showError(BuildContext context, String message) {
    _show(context, _getFriendlyErrorMessage(message), ToastType.error);
  }

  String _getFriendlyErrorMessage(String rawMessage) {
    final lowerMsg = rawMessage.toLowerCase();
    
    if (lowerMsg.contains('insufficient funds') || lowerMsg.contains('insufficient balance')) {
      return 'Insufficient balance to complete this transaction.';
    }
    if (lowerMsg.contains('connection') || lowerMsg.contains('network') || lowerMsg.contains('timeout')) {
      return 'Network error. Please check your connection and try again.';
    }
    if (lowerMsg.contains('invalid') && lowerMsg.contains('credentials')) {
      return 'Invalid credentials. Please check your email and password.';
    }
    if (lowerMsg.contains('unauthorized') || lowerMsg.contains('token')) {
      return 'Session expired. Please log in again.';
    }
    if (lowerMsg.contains('not found')) {
      return 'The requested resource could not be found.';
    }
    if (lowerMsg.contains('server') || lowerMsg.contains('500')) {
      return 'Server error occurred. Our team has been notified.';
    }
    if (rawMessage.contains('Exception:') || rawMessage.contains('{') || rawMessage.contains('}')) {
      // General fallback for raw developer traces or JSON strings
      return 'An unexpected error occurred. Please try again later.';
    }
    
    // Return original if no harsh technical keywords are detected, or cleaned up a bit.
    return rawMessage.replaceAll('Exception:', '').trim();
  }

  void showInfo(BuildContext context, String message) {
    _show(context, message, ToastType.info);
  }

  void _show(BuildContext context, String message, ToastType type) {
    _removeCurrentToast();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: _ToastAnimator(
          child: CustomToast(
            message: message,
            type: type,
            onDismiss: _removeCurrentToast,
          ),
        ),
      ),
    );

    // Find the overlay context provided by Navigator or MaterialApp
    final overlay = Overlay.of(context);
    overlay.insert(_overlayEntry!);

    _timer = Timer(const Duration(seconds: 3), () {
      _removeCurrentToast();
    });
  }

  void _removeCurrentToast() {
    _timer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _timer = null;
  }
}

class _ToastAnimator extends StatefulWidget {
  final Widget child;
  const _ToastAnimator({required this.child});

  @override
  State<_ToastAnimator> createState() => _ToastAnimatorState();
}

class _ToastAnimatorState extends State<_ToastAnimator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: const Offset(0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}
