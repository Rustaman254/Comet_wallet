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
    _show(context, message, ToastType.error);
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
