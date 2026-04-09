import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/models/customColors.dart';

class BottomNavModal extends StatelessWidget {
  const BottomNavModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: CustomColors.primary,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: CustomColors.background.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        spacing: 5,
        mainAxisSize: MainAxisSize.min,
        children: [
          BototmNavBarIcons(icon: "stocks", directionMulti: 1,),
          BototmNavBarIcons(icon: "search"),
          BototmNavBarIcons(icon: "icon", directionMulti: -1)
        ],
      ),
    );
  }
}

class BototmNavBarIcons extends StatefulWidget {
  final String icon;
  final int directionMulti;
  bool showFrost;
  BototmNavBarIcons({super.key, required this.icon, this.directionMulti = 0, this.showFrost = false});

  @override
  State<BototmNavBarIcons> createState() => _BototmNavBarIconsState();
}

class _BototmNavBarIconsState extends State<BototmNavBarIcons> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _hovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedRotation(
          turns: _hovered ? 0.025 * widget.directionMulti : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Stack(
            children: [
              Container(
                width: 47,
                height: 47,
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 41, 54, 69),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: CustomColors.background.withValues(alpha: 0.07),
                    width: 2,
                  ),
                ),
                child: Image.asset(
                  "assets/images/${widget.icon}.png",
                  fit: BoxFit.cover,
                ),
              ),
              AnimatedOpacity(
                  opacity: _hovered || widget.showFrost ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 47,
                    height: 47,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.02),
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