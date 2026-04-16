import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:frontend/models/customColors.dart';

class BackgroundGradientAnimation extends StatefulWidget {
  final Widget? child;
  final List<Color>? colors;
  final double blurSigma;

  const BackgroundGradientAnimation({
    super.key,
    this.child,
    this.colors,
    this.blurSigma = 40.0,
  });

  @override
  State<BackgroundGradientAnimation> createState() => _BackgroundGradientAnimationState();
}

class _BackgroundGradientAnimationState extends State<BackgroundGradientAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // A single controller is more performant; we use math to stagger movements
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Default colors matching the React component logic
    final List<Color> themeColors = widget.colors ?? [
    const Color(0xFFF72585), // Hot Pink
    const Color(0xFF7209B7), // Deep Violet
    const Color(0xFF4CC9F0), // Soft Blue
    const Color(0xFF480CA8), // Grape Purple
    const Color(0xFFB5179E), // Magenta
    const Color(0xFF4361EE), // Royal Blue
  ];

    return Scaffold(
      body: Stack(
        children: [
          // 1. Static Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6C00A2), // gradientBackgroundStart
                  Color(0xFF001152), // gradientBackgroundEnd
                ],
              ),
            ),
          ),
          // 2. Animated Blobs
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: GradientBlobsPainter(
                  progress: _controller.value,
                  colors: themeColors,
                ),
                size: Size.infinite,
              );
            },
          ),
          // 3. The "Gooey" / Blur Layer
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
            child: Container(color: CustomColors.primary.withOpacity(0.7)),
          ),
          // 4. Content
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class GradientBlobsPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;

  GradientBlobsPainter({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // We simulate the CSS animations (moveInCircle, moveVertical, moveHorizontal)
    // using trigonometric functions based on the single 'progress' value.
    
    for (int i = 0; i < colors.length; i++) {
      final color = colors[i];
      final double t = (progress + (i / colors.length)) % 1.0;
      final double angle = t * 2 * math.pi;

      double dx = 0;
      double dy = 0;
      double radius = size.shortestSide * 0.6;

      // Logic mapping to the React Keyframes
      if (i == 0) { // Vertical move
        dy = math.sin(angle) * (size.height * 0.2);
        dx = 0;
      } else if (i == 1 || i == 2 || i == 4) { // Circular move
        dx = math.cos(angle) * (size.width * 0.3);
        dy = math.sin(angle) * (size.height * 0.3);
      } else { // Horizontal move
        dx = math.sin(angle) * (size.width * 0.4);
        dy = 0;
      }

      final center = Offset(
        size.width / 2 + dx,
        size.height / 2 + dy,
      );

      paint.shader = ui.Gradient.radial(
        center,
        radius,
        [color.withOpacity(0.3), color.withOpacity(0.0)],
      );

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GradientBlobsPainter oldDelegate) => 
      oldDelegate.progress != progress;
}