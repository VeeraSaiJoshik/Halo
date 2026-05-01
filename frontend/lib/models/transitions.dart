import 'package:flutter/material.dart';

Route createCustomRoute(Widget destination) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => destination,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // 1. Define the Curves
      var curve = Curves.easeInOutCubic;

      // 2. Scale Animation (from 0.8 to 1.0)
      var scaleTween = Tween<double>(begin: 0.8, end: 1.0)
          .chain(CurveTween(curve: curve));

      // 3. Opacity Animation
      var fadeTween = Tween<double>(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: curve));

      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: ScaleTransition(
          scale: animation.drive(scaleTween),
          child: child,
        ),
      );
    },
    // Adjust timing here (default is usually 300ms)
    transitionDuration: const Duration(milliseconds: 500),
  );
}