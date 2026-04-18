import 'package:flutter/material.dart';
import 'package:frontend/models/customColors.dart';

/// A styled button whose size is entirely determined by [child].
///
/// Manages its own hover state and bundles every interactive animation:
/// - Scale pulse on hover
/// - Slight rotation on hover (direction controlled by [directionMulti])
/// - Purple glow that intensifies on hover
/// - Frosted-glass sheen that fades in on hover
class StandardButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Sign of the hover-rotation: 1 tilts right, -1 tilts left, 0 = no rotation.
  final int directionMulti;

  const StandardButton({
    super.key,
    required this.child,
    this.onTap,
    this.directionMulti = 0,
  });

  @override
  State<StandardButton> createState() => _StandardButtonState();
}

class _StandardButtonState extends State<StandardButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
        scale: _hovered ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedRotation(
          turns: _hovered ? 0.025 * widget.directionMulti : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Stack(
            children: [
              // Base: styled container — size driven entirely by child.
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: CustomColors.darkPurple,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: CustomColors.purple,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CustomColors.purple.withValues(
                        alpha: _hovered ? 0.6 : 0.3,
                      ),
                      blurRadius: _hovered ? 15 : 8,
                      spreadRadius: _hovered ? 2 : 0,
                      offset: Offset.zero,
                    ),
                  ],
                ),
                child: widget.child,
              ),
              // Frost sheen — fills whatever size the AnimatedContainer is.
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: _hovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.00),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
