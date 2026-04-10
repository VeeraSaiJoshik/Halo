import 'dart:math' as math;
import 'package:flutter/material.dart';

class BackgroundGradientAnimation extends StatefulWidget {
  static const int opacity = 35;

  const BackgroundGradientAnimation({
    super.key,
    this.gradientStart = const Color.fromARGB(opacity, 108, 0, 162),
    this.gradientEnd = const Color.fromARGB(opacity, 0, 17, 82),
    this.firstColor  = const Color.fromARGB(opacity, 18, 113, 255),
    this.secondColor = const Color.fromARGB(opacity, 221, 74, 255),
    this.thirdColor  = const Color.fromARGB(opacity, 100, 220, 255),
    this.fourthColor = const Color.fromARGB(opacity, 200, 50, 50),
    this.fifthColor  = const Color.fromARGB(opacity, 180, 180, 50),
    this.sixthColor  = const Color.fromARGB(opacity, 50, 200, 120),
    this.seventhColor = const Color.fromARGB(opacity, 255, 100, 50),
    this.eighthColor = const Color.fromARGB(opacity, 140, 60, 255),
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

  /// Blob radius as a fraction of the shorter screen dimension.
  final double blobSizeFraction;

  final Widget? child;

  @override
  State<BackgroundGradientAnimation> createState() =>
      _BackgroundGradientAnimationState();
}

class _BackgroundGradientAnimationState
    extends State<BackgroundGradientAnimation> with TickerProviderStateMixin {

  late final AnimationController _c1 = AnimationController(
    vsync: this, duration: const Duration(seconds: 12))..repeat();

  late final AnimationController _c2 = AnimationController(
    vsync: this, duration: const Duration(seconds: 7))..repeat();

  late final AnimationController _c3 = AnimationController(
    vsync: this, duration: const Duration(seconds: 10))..repeat();

  late final AnimationController _c4 = AnimationController(
    vsync: this, duration: const Duration(seconds: 8))..repeat();

  late final AnimationController _c5 = AnimationController(
    vsync: this, duration: const Duration(seconds: 9))..repeat();

  late final AnimationController _c6 = AnimationController(
    vsync: this, duration: const Duration(seconds: 6))..repeat();

  late final AnimationController _c7 = AnimationController(
    vsync: this, duration: const Duration(seconds: 11))..repeat();

  late final AnimationController _c8 = AnimationController(
    vsync: this, duration: const Duration(seconds: 14))..repeat();

  late final AnimationController _c9 = AnimationController(
    vsync: this, duration: const Duration(seconds: 5))..repeat();

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
            widget.firstColor,
            widget.secondColor,
            widget.thirdColor,
            widget.fourthColor,
            widget.fifthColor,
            widget.sixthColor,
            widget.seventhColor,
            widget.eighthColor,
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
    final cy = size.height / 2;

    // Dark space background.
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
    final o300 = size.width * 0.25;
    final o500 = size.width * 0.42;

    canvas.saveLayer(Offset.zero & size, Paint()..blendMode = BlendMode.hardLight);

    // Blob 1 — top edge horizontal sweep.
    _drawBlob(canvas, size,
      Offset(cx + size.width * 0.45 * math.sin(t1 * 2 * math.pi), 0),
      blobRadius, colors[0], BlendMode.srcOver);

    // Blob 2 — orbits top-left corner at a tighter radius.
    final a2 = -(t2 * 2 * math.pi);
    _drawBlob(canvas, size,
      Offset(o300 * math.cos(a2), o300 * math.sin(a2)),
      blobRadius * 0.9, colors[1], BlendMode.screen);

    // Blob 3 — orbits top-right corner.
    final a3 = t3 * 2 * math.pi;
    _drawBlob(canvas, size,
      Offset(size.width + o300 * math.cos(a3), o300 * math.sin(a3)),
      blobRadius * 0.9, colors[2], BlendMode.screen);

    // Blob 4 — center horizontal sweep, stays fully within screen bounds.
    _drawBlob(canvas, size,
      Offset(cx + size.width * 0.38 * math.sin(t4 * 2 * math.pi), cy - size.height * 0.1),
      blobRadius * 0.85, colors[3], BlendMode.screen);

    // Blob 5 — bottom sweep with a vertical wobble.
    _drawBlob(canvas, size,
      Offset(
        cx + size.width * 0.4 * math.sin(t5 * 2 * math.pi + math.pi / 3),
        size.height * 0.8 + size.height * 0.08 * math.cos(t5 * 4 * math.pi),
      ),
      blobRadius * 0.8, colors[4], BlendMode.screen);

    // Blob 6 — small fast circular orbit near centre. Always on screen.
    final a6 = t6 * 2 * math.pi;
    _drawBlob(canvas, size,
      Offset(cx + size.width * 0.18 * math.cos(a6), cy + size.height * 0.12 * math.sin(a6)),
      blobRadius * 0.7, colors[5], BlendMode.screen);

    // Blob 7 — wide diagonal orbit for overall coverage.
    final a7 = t7 * 2 * math.pi;
    _drawBlob(canvas, size,
      Offset(
        cx - o500 + o500 * (math.cos(a7) - math.sin(a7)),
        cy + o500 - o500 * (math.sin(a7) + math.cos(a7)),
      ),
      blobRadius * 0.85, colors[6], BlendMode.screen);

    // Blob 8 — left-side vertical bounce. Always on screen.
    _drawBlob(canvas, size,
      Offset(size.width * 0.2, cy + size.height * 0.3 * math.sin(t8 * 2 * math.pi)),
      blobRadius * 0.75, colors[7], BlendMode.screen);

    // Blob 9 — fast small orbit near upper-centre. Always on screen.
    final a9 = t9 * 2 * math.pi;
    _drawBlob(canvas, size,
      Offset(
        cx + size.width * 0.14 * math.cos(a9),
        size.height * 0.3 + size.height * 0.12 * math.sin(a9),
      ),
      blobRadius * 0.65, colors[3], BlendMode.screen);

    canvas.restore();
  }

  void _drawBlob(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    Color color,
    BlendMode blendMode,
  ) {
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
