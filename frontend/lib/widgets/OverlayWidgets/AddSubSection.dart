import 'dart:math' as math; // Required for sin and cos
import 'package:flutter/material.dart';

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/services/app_event_bus.dart';

enum Side {
  left, 
  right
}

class AddSubSection extends ConsumerStatefulWidget {
  Side side;
  AddSubSection({super.key, required this.side});

  @override
  ConsumerState<AddSubSection> createState() => _AddSubSectionState();
}

class _AddSubSectionState extends ConsumerState<AddSubSection> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    ref.read(appEventBusProvider).stream.listen((event) {
      if((event == AppEvent.leftAdd && widget.side == Side.left) || (event == AppEvent.rightAdd && widget.side == Side.right)) {
        setState(() {
          _animController.forward();
        });
      }
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.side == Side.left ? -3 : 3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  static const double _iconSize = 43;
  static const double _iconSpacing = 35;

  @override
  Widget build(BuildContext context) {
    final List<String> icons = ["stocks", "icon"];

    final double menuWidth  = _iconSize;
    final double menuHeight = icons.length * _iconSize + (icons.length - 1) * _iconSpacing;

    const double edgeGap = 35;
    final double totalWidth = edgeGap + menuWidth;

    return Positioned(
      top: 0,
      bottom: 0,
      left:  widget.side == Side.left  ? 0 : null,
      right: widget.side == Side.right ? 0 : null,
      width: totalWidth,
      child: Stack(
        children: [
          Positioned(
            left:   widget.side == Side.left  ? edgeGap : null,
            right:  widget.side == Side.right ? edgeGap : null,
            top: 0,
            bottom: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  spacing: _iconSpacing,
                  children: List.generate(icons.length, (index) {
                    final double mid = (icons.length - 1) / 2;
                    final double relativePos = index - mid;
                    final double xOffset = relativePos.abs() * -10.0;
                    final double initialRotation = relativePos * 0.08;

                    return Transform.translate(
                      offset: Offset(xOffset, 0),
                      child: Transform.rotate(
                        angle: initialRotation,
                        child: SideNavBarIcon(
                          icon: icons[index],
                          directionMulti: relativePos > 0 ? 1 : -1,
                        ),
                      ),
                    );
                  }),
              ),
            ),
          ),
          Center(
            child: MouseRegion(
              onExit: (_) {
                _animController.reverse();
              },
              opaque: false,
              child: Container(
                width: totalWidth + 40,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          ),
        ],
      )
    );
  }
}

class SideNavBarIcon extends StatefulWidget {
  final String icon;
  final int directionMulti;
  final bool showFrost;

  const SideNavBarIcon({
    super.key,
    required this.icon,
    this.directionMulti = 0,
    this.showFrost = false,
  });

  @override
  State<SideNavBarIcon> createState() => _SideNavBarIconState();
}

class _SideNavBarIconState extends State<SideNavBarIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
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
              // Use AnimatedContainer to make the glow transition smoothly
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 43,
                height: 43,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: CustomColors.darkPurple,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: CustomColors.purple,
                    width: 2,
                  ),
                  // This creates the glow effect
                  boxShadow: [
                    BoxShadow(
                      color: CustomColors.purple.withValues(
                        // Make the glow more intense on hover
                        alpha: _hovered ? 0.6 : 0.3, 
                      ),
                      blurRadius: _hovered ? 15 : 8,
                      spreadRadius: _hovered ? 2 : 0,
                      offset: const Offset(0, 0), // Keeps glow centered
                    ),
                  ],
                ),
                child: Image.asset(
                  "assets/images/${widget.icon}.png",
                  fit: BoxFit.cover,
                ),
              ),
              
              // Your existing Frost Layer
              AnimatedOpacity(
                opacity: _hovered || widget.showFrost ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 43,
                  height: 43,
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
            ],
          ),
        ),
      ),
    );
  }
}