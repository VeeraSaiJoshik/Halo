import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/themes/theme_provider.dart';

class BackgroundGradientAnimation extends ConsumerStatefulWidget {
  final Widget? child;
  // Optional color override — when null, colors come from haloThemeProvider.
  final List<Color>? colors;
  final double blurSigma;

  const BackgroundGradientAnimation({
    super.key,
    this.child,
    this.colors,
    this.blurSigma = 40.0,
  });

  @override
  ConsumerState<BackgroundGradientAnimation> createState() =>
      _BackgroundGradientAnimationState();
}

class _BackgroundGradientAnimationState
    extends ConsumerState<BackgroundGradientAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
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
    final theme = ref.watch(haloThemeProvider);
    final List<Color> blobColors = widget.colors ?? theme.blobColors;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Static background gradient — theme-driven, replaces generic purple→navy
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.backgroundGradient,
              ),
            ),
          ),
          // 2. Animated ambient blobs — theme colors, low opacity per UI/UX Pro Max
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: GradientBlobsPainter(
                  progress: _controller.value,
                  colors: blobColors,
                  blobOpacity: theme.blobOpacity,
                ),
                size: Size.infinite,
              );
            },
          ),
          // 3. Glass blur layer — dark overlay, theme-tinted
          BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: widget.blurSigma,
              sigmaY: widget.blurSigma,
            ),
            child: Container(color: theme.glassOverlay),
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
  final double blobOpacity;

  GradientBlobsPainter({
    required this.progress,
    required this.colors,
    this.blobOpacity = 0.12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < colors.length; i++) {
      final color = colors[i];
      final double t = (progress + (i / colors.length)) % 1.0;
      final double angle = t * 2 * math.pi;

      double dx = 0;
      double dy = 0;
      final double radius = size.shortestSide * 0.6;

      if (i == 0) {
        dy = math.sin(angle) * (size.height * 0.2);
        dx = 0;
      } else if (i == 1 || i == 2 || i == 4) {
        dx = math.cos(angle) * (size.width * 0.3);
        dy = math.sin(angle) * (size.height * 0.3);
      } else {
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
        [color.withValues(alpha: blobOpacity), color.withValues(alpha: 0.0)],
      );

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GradientBlobsPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.blobOpacity != blobOpacity;
}
