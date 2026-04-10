import 'dart:math' as math;
import 'package:flutter/material.dart';

class BackgroundGradientAnimation extends StatefulWidget {
  static const int opacity = 35;

  const BackgroundGradientAnimation({
    super.key,
    this.gradientStart = const Color.fromARGB(opacity, 108, 0, 162),
    this.gradientEnd = const Color.fromARGB(opacity, 0, 17, 82),
    this.firstColor = const Color.fromARGB(opacity, 18, 113, 255),
    this.secondColor = const Color.fromARGB(opacity, 221, 74, 255),
    this.thirdColor = const Color.fromARGB(opacity, 100, 220, 255),
    this.fourthColor = const Color.fromARGB(opacity, 200, 50, 50),
    this.fifthColor = const Color.fromARGB(opacity, 180, 180, 50),
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
    vsync: this,
    duration: const Duration(seconds: 30),
  )..repeat();

  late final AnimationController _c2 = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  late final AnimationController _c3 = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  )..repeat();

  late final AnimationController _c4 = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  )..repeat(reverse: true);

  late final AnimationController _c5 = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    _c3.dispose();
    _c4.dispose();
    _c5.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_c1, _c2, _c3, _c4, _c5]),
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
          ],
          blobSizeFraction: widget.blobSizeFraction,
          t1: _c1.value,
          t2: _c2.value,
          t3: _c3.value,
          t4: _c4.value,
          t5: _c5.value,
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
    required this.t1,
    required this.t2,
    required this.t3,
    required this.t4,
    required this.t5,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final List<Color> colors;
  final double blobSizeFraction;
  final double t1, t2, t3, t4, t5;

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

    // Orbit distances scaled from the original 1440px reference design.
    final o400 = size.width * 0.40;
    final o800 = size.width * 0.65;

    canvas.saveLayer(Offset.zero & size, Paint()..blendMode = BlendMode.hardLight);

    // Blob 1 — centre pinned to y=0, sweeps left↔right along the top edge.
    // Glow radiates downward from the top the entire time.
    _drawBlob(canvas, size,
      Offset(cx + size.width * 0.45 * math.sin(t1 * 2 * math.pi), 0),
      blobRadius, colors[0], BlendMode.srcOver);

    // Blob 2 — orbits the top-left corner; centre traces a circle around (0, 0).
    final a2 = -(t2 * 2 * math.pi);
    _drawBlob(canvas, size,
      Offset(o400 * math.cos(a2), o400 * math.sin(a2)),
      blobRadius, colors[1], BlendMode.screen);

    // Blob 3 — orbits the top-right corner; centre traces a circle around (width, 0).
    final a3 = t3 * 2 * math.pi;
    _drawBlob(canvas, size,
      Offset(size.width + o400 * math.cos(a3), o400 * math.sin(a3)),
      blobRadius, colors[2], BlendMode.screen);

    // Blob 4 — full-width horizontal sweep sitting close to the top edge.
    _drawBlob(canvas, size,
      Offset(
        cx + size.width * 0.5 * (t4 * 2 - 1),
        size.height * 0.08 + size.height * 0.06 * math.sin(t4 * math.pi),
      ),
      blobRadius * 0.85, colors[3], BlendMode.screen);

    // Blob 5 — large diagonal orbit keeps colour in the lower / overall area.
    final a5 = t5 * 2 * math.pi;
    _drawBlob(canvas, size,
      Offset(
        cx - o800 + o800 * (math.cos(a5) - math.sin(a5)),
        cy + o800 - o800 * (math.sin(a5) + math.cos(a5)),
      ),
      blobRadius * 0.9, colors[4], BlendMode.screen);

    canvas.restore();
  }

  /// Paints a nebula cloud: a wide radial gradient with a bright core fading
  /// to transparent. [blendMode] controls how it merges with previously drawn
  /// blobs inside the shared layer.
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
            color,                                   // bright centre
            color,                                   // peak glow ring
            color.withValues(alpha: color.a * 0.25), // long outer fade
            color.withValues(alpha: 0.0),            // transparent edge
          ],
          stops: const [0.0, 0.25, 0.65, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_GradientPainter old) =>
      t1 != old.t1 ||
      t2 != old.t2 ||
      t3 != old.t3 ||
      t4 != old.t4 ||
      t5 != old.t5;
}
