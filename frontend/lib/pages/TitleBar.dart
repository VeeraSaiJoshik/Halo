import 'package:flutter/material.dart';
import 'package:frontend/models/customColors.dart';

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
      height: 45,
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: BoxBorder.fromLTRB(
          bottom: BorderSide(color: CustomColors.accent, width: 2)
        )
      ),
      child: Row(
        children: [
          CommandButtons()
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
