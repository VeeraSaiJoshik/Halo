import 'dart:math' as math;
import 'package:flutter/material.dart';

class BackgroundGradientAnimation extends StatefulWidget {
  static const int opacity = 25;

  const BackgroundGradientAnimation({
    super.key,
    this.gradientStart  = const Color.fromARGB(opacity, 108, 0, 162),
    this.gradientEnd    = const Color.fromARGB(opacity, 0, 17, 82),
    this.firstColor     = const Color.fromARGB(opacity, 18, 113, 255),
    this.secondColor    = const Color.fromARGB(opacity, 221, 74, 255),
    this.thirdColor     = const Color.fromARGB(opacity, 100, 220, 255),
    this.fourthColor    = const Color.fromARGB(opacity, 200, 50, 50),
    this.fifthColor     = const Color.fromARGB(opacity, 180, 180, 50),
    this.sixthColor     = const Color.fromARGB(opacity, 50, 200, 120),
    this.seventhColor   = const Color.fromARGB(opacity, 255, 100, 50),
    this.eighthColor    = const Color.fromARGB(opacity, 140, 60, 255),
    this.blobSizeFraction = 1.2,
    this.child,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final Color firstColor;
  final Color secondColor;
  final Color thirdColor;
  final Color fourthColor;
  final Color fifthColor;
  final Color sixthColor;
  final Color seventhColor;
  final Color eighthColor;

  final double blobSizeFraction;
  final Widget? child;

  @override
  State<BackgroundGradientAnimation> createState() =>
      _BackgroundGradientAnimationState();
}

class _BackgroundGradientAnimationState
    extends State<BackgroundGradientAnimation> with TickerProviderStateMixin {

  // Nine controllers — different durations give each blob a different speed.
  late final AnimationController _c1 = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  late final AnimationController _c2 = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
  late final AnimationController _c3 = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  late final AnimationController _c4 = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final AnimationController _c5 = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat();
  late final AnimationController _c6 = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _c7 = AnimationController(vsync: this, duration: const Duration(seconds: 11))..repeat();
  late final AnimationController _c8 = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  late final AnimationController _c9 = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();

  @override
  void dispose() {
    _c1.dispose(); _c2.dispose(); _c3.dispose();
    _c4.dispose(); _c5.dispose(); _c6.dispose();
    _c7.dispose(); _c8.dispose(); _c9.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_c1, _c2, _c3, _c4, _c5, _c6, _c7, _c8, _c9]),
      builder: (context, child) => CustomPaint(
        painter: _GradientPainter(
          gradientStart: widget.gradientStart,
          gradientEnd: widget.gradientEnd,
          colors: [
            widget.firstColor, widget.secondColor, widget.thirdColor,
            widget.fourthColor, widget.fifthColor, widget.sixthColor,
            widget.seventhColor, widget.eighthColor,
          ],
          blobSizeFraction: widget.blobSizeFraction,
          t1: _c1.value, t2: _c2.value, t3: _c3.value,
          t4: _c4.value, t5: _c5.value, t6: _c6.value,
          t7: _c7.value, t8: _c8.value, t9: _c9.value,
        ),
        child: child,
      ),
      child: widget.child ?? const SizedBox.expand(),
    );
  }
}

class _GradientPainter extends CustomPainter {
  const _GradientPainter({
    required this.gradientStart,
    required this.gradientEnd,
    required this.colors,
    required this.blobSizeFraction,
    required this.t1, required this.t2, required this.t3,
    required this.t4, required this.t5, required this.t6,
    required this.t7, required this.t8, required this.t9,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final List<Color> colors;
  final double blobSizeFraction;
  final double t1, t2, t3, t4, t5, t6, t7, t8, t9;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // Background.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [gradientStart, gradientEnd],
        ).createShader(Offset.zero & size),
    );

    final blobRadius = size.shortestSide * blobSizeFraction / 2;

    // Each blob travels from just above the top to just below the bottom.
    // A phase offset staggers them so they are spread across the screen at all
    // times — with 9 evenly-phased blobs, at least 3 are always fully visible.
    final enter  = -blobRadius;
    final travel = size.height + blobRadius * 2.0;

    // Returns a top-to-bottom position for a blob.
    // [t]     : controller value 0→1
    // [phase] : 0→1 offset so blobs start at different heights
    // [xBase] : horizontal centre lane (fraction of width)
    // [xSway] : horizontal sway amplitude (fraction of width)
    Offset pos(double t, double phase, double xFrac, double swayFrac) {
      final eff = (t + phase) % 1.0;
      final y = enter + travel * eff;
      final x = size.width * xFrac +
                size.width * swayFrac * math.sin(eff * 2 * math.pi);
      return Offset(x, y);
    }

    canvas.saveLayer(Offset.zero & size, Paint()..blendMode = BlendMode.hardLight);

    // Nine blobs, evenly phased (0/9, 1/9, … 8/9), spread across the width.
    _drawBlob(canvas, size, pos(t1, 0/9, 0.08, 0.03), blobRadius,        colors[0], BlendMode.srcOver);
    _drawBlob(canvas, size, pos(t2, 1/9, 0.22, 0.00), blobRadius * 0.9,  colors[1], BlendMode.screen);
    _drawBlob(canvas, size, pos(t3, 2/9, 0.36, 0.04), blobRadius * 0.95, colors[2], BlendMode.screen);
    _drawBlob(canvas, size, pos(t4, 3/9, 0.50, 0.00), blobRadius * 0.85, colors[3], BlendMode.screen);
    _drawBlob(canvas, size, pos(t5, 4/9, 0.64, 0.04), blobRadius * 0.9,  colors[4], BlendMode.screen);
    _drawBlob(canvas, size, pos(t6, 5/9, 0.78, 0.00), blobRadius * 0.8,  colors[5], BlendMode.screen);
    _drawBlob(canvas, size, pos(t7, 6/9, 0.20, 0.07), blobRadius * 0.85, colors[6], BlendMode.screen);
    _drawBlob(canvas, size, pos(t8, 7/9, 0.55, 0.05), blobRadius * 0.75, colors[7], BlendMode.screen);
    _drawBlob(canvas, size, pos(t9, 8/9, 0.88, 0.00), blobRadius * 0.7,  colors[0], BlendMode.screen);

    canvas.restore();
  }

  void _drawBlob(Canvas canvas, Size size, Offset center, double radius, Color color, BlendMode blendMode) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..blendMode = blendMode
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80)
        ..shader = RadialGradient(
          colors: [
            color,
            color,
            color.withValues(alpha: color.a * 0.25),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.25, 0.65, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_GradientPainter old) =>
      t1 != old.t1 || t2 != old.t2 || t3 != old.t3 ||
      t4 != old.t4 || t5 != old.t5 || t6 != old.t6 ||
      t7 != old.t7 || t8 != old.t8 || t9 != old.t9;
}
