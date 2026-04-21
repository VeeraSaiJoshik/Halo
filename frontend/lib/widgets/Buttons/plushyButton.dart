import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/themes/theme_provider.dart';
import 'package:gradient_borders/gradient_borders.dart';

class PlushyButton extends ConsumerStatefulWidget {
  final Function onPressed;
  final Widget child;
  final bool reverse;
  final Color? glowColor;
  final EdgeInsets padding;
  final bool selected;
  final bool disabled;

  PlushyButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.reverse = false,
    this.glowColor,
    this.selected = false,
    this.disabled = false,
    EdgeInsets? padding,
  }) : padding = padding ?? const EdgeInsets.symmetric(horizontal: 25, vertical: 15);

  @override
  ConsumerState<PlushyButton> createState() => _PlushyButtonState();
}

class _PlushyButtonState extends ConsumerState<PlushyButton> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(haloThemeProvider);
    final shadow = widget.glowColor ?? CustomColors.accent;
    final isActive = _hovering || _pressed;

    return Opacity(
      opacity: widget.disabled ? 0.35 : 1.0,
      child: AnimatedScale(
      scale: _pressed ? 1.08 : (_hovering ? 1.05 : 1.0),
      duration: const Duration(milliseconds: 200),
      curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
      child: AnimatedRotation(
        turns: _hovering ? -0.03 / (2 * math.pi) * (widget.reverse ? 1 : -1) : 0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: InkWell(
          onTap: widget.disabled ? null : () => widget.onPressed(),
          mouseCursor: widget.disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onHover: widget.disabled ? null : (value) => setState(() { _hovering = value; if (!value) _pressed = false; }),
          onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
          onTapUp: widget.disabled ? null : (_) => setState(() => _pressed = false),
          onTapCancel: widget.disabled ? null : () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.whiteColor.withOpacity(0.2),
                width: 0.5,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
              boxShadow: widget.selected ? [
                BoxShadow(
                  color: shadow.withOpacity(0.5),
                  blurRadius: 28,
                  spreadRadius: 5,
                ),
              ] : [
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
                color: widget.selected ? CustomColors.primary.withOpacity(1) : CustomColors.primary.withOpacity(isActive ? 1 : 0.4),
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
                          theme.whiteColor.withOpacity(0.8),
                          theme.whiteColor.withOpacity(0.3),
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
    ),
    );
  }
}
