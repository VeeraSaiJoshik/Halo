import 'dart:math' as math; // Required for sin and cos
import 'package:flutter/material.dart';

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/services/app_event_bus.dart';

class AddSubSection extends ConsumerStatefulWidget {
  const AddSubSection({super.key});

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
      if(event == AppEvent.leftAdd) {
        _animController.forward();
      }
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-2, 0),
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

  @override
  Widget build(BuildContext context) {
    final List<String> icons = ["stocks", "icon"];

    return Positioned(
      top: 0, 
      bottom: 0, 
      left: 35, 
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: MouseRegion(
            onExit: (event) => _animController.reverse(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // Standard spacing between icons
              spacing: 35, 
              children: List.generate(icons.length, (index) {
                // 1. Calculate a "tilt" and "offset" based on position
                // This simulates being on the right side of a circle centered to the left
                final double mid = (icons.length - 1) / 2;
                final double relativePos = index - mid; // e.g., -1.5, -0.5, 0.5, 1.5
                
                // Push the middle icons further right, top/bottom icons further left
                // or vice versa to create the arc shape manually.
                final double xOffset = (relativePos.abs() * -10.0); 
                
                // Tilt the icons: negative rotation for top, positive for bottom
                final double initialRotation = relativePos * 0.08; 
                    
                return Transform.translate(
                  offset: Offset(xOffset, 0),
                  child: Transform.rotate(
                    angle: initialRotation,
                    child: SideNavBarIcon(
                      icon: icons[index],
                      // Pass the rotation to the hover state to maintain consistency
                      directionMulti: relativePos > 0 ? 1 : -1,
                    ),
                  ),
                );
              }),
            ),
          )
        ),
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