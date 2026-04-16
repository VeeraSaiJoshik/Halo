import 'dart:math' as math; // Required for sin and cos
import 'package:flutter/material.dart';

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/controllers/AppController.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/services/app_event_bus.dart';
import 'package:frontend/widgets/Buttons/StandardButton.dart';

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
    final appController = ref.watch(appControllerProvider);
    final List<String> icons = [];
    WindowInfo currentTab = appController.getCurrentTab()!;
    if(!currentTab.pages.contains(AppPage.GRAPH_VIEWER)) {
      icons.add("graph");
    }
    if(!currentTab.pages.contains(AppPage.PORTAL)) {
      icons.add("search");
    }
    if(!currentTab.pages.contains(AppPage.NOTIFICATIONS)) {
      icons.add("icon");
    }

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
                          onTap: (page) => appController.addNewSubPage(page, widget.side),
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

class SideNavBarIcon extends StatelessWidget {
  final String icon;
  final int directionMulti;
  final void Function(AppPage page) onTap;

  const SideNavBarIcon({
    super.key,
    required this.icon,
    required this.onTap,
    this.directionMulti = 0,
  });

  @override
  Widget build(BuildContext context) {
    return StandardButton(
      directionMulti: directionMulti,
      onTap: () => onTap(
        icon == "graph"
            ? AppPage.GRAPH_VIEWER
            : icon == "search"
                ? AppPage.PORTAL
                : AppPage.NOTIFICATIONS,
      ),
      child: SizedBox(
        width: 33,
        height: 33,
        child: Image.asset(
          "assets/images/$icon.png",
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}