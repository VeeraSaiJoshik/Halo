import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/widgets/OnboardingWidgets/WelcomeWidget.dart';
import 'package:gradient_borders/gradient_borders.dart';

class PlushyButton extends StatefulWidget {
  const PlushyButton({
    super.key,
  });

  @override
  State<PlushyButton> createState() => _PlushyButtonState();
}

class _PlushyButtonState extends State<PlushyButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _hovering ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: AnimatedRotation(
        turns: _hovering ? -0.03 / (2 * math.pi) : 0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: InkWell(
          onTap: () {},
          mouseCursor: SystemMouseCursors.click,
          onHover: (bool hovering) => setState(() => _hovering = hovering),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: CustomColors.purple.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                decoration: BoxDecoration(
                  color: CustomColors.primary.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: GradientBoxBorder(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.8),
                        Colors.white.withOpacity(0.5),
                      ],
                    ),
                    width: 0.5,
                  ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 12,
                    children: [
                      Text(
                        "Get Started",
                        style: TextStyle(
                          fontSize: 23,
                          color: CustomColors.background,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      FaIcon(
                        FontAwesomeIcons.arrowRight,
                        color: CustomColors.background,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
