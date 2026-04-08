import 'dart:math' as math;
import 'package:flutter/material.dart';

class FluidBackground extends StatefulWidget {
  final Widget child;
  final ScrollController? scrollController;

  const FluidBackground({
    super.key,
    required this.child,
    this.scrollController,
  });

  @override
  State<FluidBackground> createState() => _FluidBackgroundState();
}

class _FluidBackgroundState extends State<FluidBackground>
    with TickerProviderStateMixin {
  late List<Bubble> _bubbles;
  late AnimationController _controller;
  double _scrollOffset = 0;
  double _lastScrollOffset = 0;
  double _scrollVelocity = 0;

  @override
  void initState() {
    super.initState();
    _bubbles = List.generate(30, (index) => Bubble.random());
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.scrollController != null) {
      final currentOffset = widget.scrollController!.offset;
      setState(() {
        _lastScrollOffset = _scrollOffset;
        _scrollVelocity = currentOffset - _scrollOffset;
        _scrollOffset = currentOffset;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update bubbles with scroll influence
        _bubbles = _bubbles.map((bubble) {
          return bubble.update(_scrollVelocity, _controller.value);
        }).toList();
        
        return CustomPaint(
          painter: FluidPainter(
            bubbles: _bubbles,
            scrollOffset: _scrollOffset,
            lastScrollOffset: _lastScrollOffset,
            animationValue: _controller.value,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class Bubble {
  final double x;
  final double y;
  final double radius;
  final double speedX;
  final double speedY;
  final Color color;

  Bubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speedX,
    required this.speedY,
    required this.color,
  });

  factory Bubble.random() {
    final random = math.Random();
    return Bubble(
      x: random.nextDouble() * 100,
      y: random.nextDouble() * 100,
      radius: 20 + random.nextDouble() * 40,
      speedX: (random.nextDouble() - 0.5) * 0.5,
      speedY: (random.nextDouble() - 0.5) * 0.5,
      color: Colors.white.withValues(alpha: 0.03 + random.nextDouble() * 0.05),
    );
  }

  Bubble update(double scrollVelocity, double animationValue) {
    final viscousFactor = 0.5; // Viscosity factor - higher = more resistance
    final scrollInfluence = scrollVelocity * viscousFactor;
    final damping = 0.95; // Damping factor for smooth deceleration
    
    return Bubble(
      x: (x + speedX + scrollInfluence * 0.15) % 100,
      y: (y + speedY + math.sin(animationValue * 2 * math.pi) * 0.2) % 100,
      radius: radius,
      speedX: (speedX * damping + scrollInfluence * 0.02).clamp(-2.0, 2.0),
      speedY: (speedY * damping).clamp(-2.0, 2.0),
      color: color,
    );
  }
}

class FluidPainter extends CustomPainter {
  final List<Bubble> bubbles;
  final double scrollOffset;
  final double lastScrollOffset;
  final double animationValue;

  FluidPainter({
    required this.bubbles,
    required this.scrollOffset,
    required this.lastScrollOffset,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final bubble in bubbles) {
      final paint = Paint()
        ..color = bubble.color
        ..style = PaintingStyle.fill;

      final x = (bubble.x / 100) * size.width;
      final y = (bubble.y / 100) * size.height;

      canvas.drawCircle(Offset(x, y), bubble.radius, paint);
    }
  }

  @override
  bool shouldRepaint(FluidPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.animationValue != animationValue;
  }
}

