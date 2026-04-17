import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/customColors.dart';
import 'package:gradient_borders/gradient_borders.dart';

class PlushyButton extends StatefulWidget {
  final Function onPressed;
  final Widget child;
  final bool reverse;
  final Color? glowColor;
  final EdgeInsets padding;

  PlushyButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.reverse = false,
    this.glowColor,
    EdgeInsets? padding,
  }) : padding = padding ?? const EdgeInsets.symmetric(horizontal: 25, vertical: 15);

  @override
  State<PlushyButton> createState() => _PlushyButtonState();
}

class _PlushyButtonState extends State<PlushyButton> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final shadow = widget.glowColor ?? CustomColors.purple;
    final isActive = _hovering || _pressed;

    return AnimatedScale(
      scale: _pressed ? 1.08 : (_hovering ? 1.05 : 1.0),
      duration: const Duration(milliseconds: 200),
      curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
      child: AnimatedRotation(
        turns: _hovering ? -0.03 / (2 * math.pi) * (widget.reverse ? 1 : -1) : 0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: InkWell(
          onTap: () => widget.onPressed(),
          mouseCursor: SystemMouseCursors.click,
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onHover: (value) => setState(() { _hovering = value; if (!value) _pressed = false; }),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 0.5,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
              boxShadow: [
                BoxShadow(
                  color: shadow.withOpacity(isActive ? 0.55 : 0),
                  blurRadius: isActive ? 24 : 8,
                  spreadRadius: isActive ? 3 : 0,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                color: CustomColors.primary.withOpacity(isActive ? 1 : 0.4),
                child: Container(
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: GradientBoxBorder(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0.3),
                        ],
                      ),
                      width: 0.5,
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: widget.child,
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
