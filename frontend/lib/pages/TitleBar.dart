import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/widgets/window_tab.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class TitleBar extends StatefulWidget {
  const TitleBar({super.key});

  @override
  State<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends State<TitleBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 53,
      padding: EdgeInsets.symmetric(horizontal: 10),
      
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            height: 45,
            child: CommandButtons()
          ), 
          Container(width: 10),
          WindowTab(
            context: WindowInfo(activeStocks: ["IXIC", "IXIC", "IXIC", "IXIC"]),
            isActive: true,
          ),
          WindowTab(
            context: WindowInfo(activeStocks: ["IXIC", "IXIC", "IXIC", "IXIC"]),
            isActive: false,
          )
        ],
      ),
    );
  }
}

class CommandButtons extends StatefulWidget {
  const CommandButtons({super.key});

  @override
  State<CommandButtons> createState() => _CommandButtonsState();
}

class _CommandButtonsState extends State<CommandButtons> with TickerProviderStateMixin {
  late AnimationController redController;
  late Animation<Color?> redAnimation;

  late AnimationController orangeController;
  late Animation<Color?> orangeAnimation;

  late AnimationController greenController;
  late Animation<Color?> greenAnimation;

  @override
  void initState() {
    super.initState();
    redController = AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    orangeController = AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    greenController = AnimationController(vsync: this, duration: Duration(milliseconds: 200));

    redAnimation = ColorTween(begin: Colors.grey, end: Colors.red).animate(redController);
    orangeAnimation = ColorTween(begin: Colors.grey, end: Colors.orange).animate(orangeController);
    greenAnimation = ColorTween(begin: Colors.grey, end: Colors.green).animate(greenController);
  }

  @override
  void dispose() {
    redController.dispose();
    orangeController.dispose();
    greenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        redController.forward();
        orangeController.forward();
        greenController.forward();
      },
      onExit: (_) {
        redController.reverse();
        orangeController.reverse();
        greenController.reverse();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([redController, orangeController, greenController]),
        builder: (context, _) => Row(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 15,
              width: 15,
              decoration: BoxDecoration(
                color: redAnimation.value,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            Container(
              height: 15,
              width: 15,
              decoration: BoxDecoration(
                color: orangeAnimation.value,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            Container(
              height: 15,
              width: 15,
              decoration: BoxDecoration(
                color: greenAnimation.value,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
