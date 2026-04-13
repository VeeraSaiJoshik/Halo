import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/services/app_event_bus.dart';
import 'package:frontend/widgets/window_tab.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:window_manager/window_manager.dart';

class TitleBar extends ConsumerStatefulWidget {
  const TitleBar({super.key});

  @override
  ConsumerState<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends ConsumerState<TitleBar> {
  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    return Container(
      width: double.infinity,
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 17),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            height: 48,
            child: CommandButtons()
          ),
          Container(width: 10),
          ...controller.tabs.map((tab) => WindowTab(context: tab, switchTab: controller.switchTab,)),
          Container(width: 10),
          InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            onTap: () {
              setState(() {
                ref.read(appEventBusProvider).emit(AppEvent.openSearch);
              });
            },
            child: Container(height: 38, child: Center(
              child: FaIcon(FontAwesomeIcons.plus, size: 15, color: CustomColors.background)
            ))
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
            InkWell(
              splashColor: Colors.transparent, 
              onTap: () => {
                windowManager.close()
              },
              child: Container(
                height: 15,
                width: 15,
                decoration: BoxDecoration(
                  color: redAnimation.value,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            InkWell(
              splashColor: Colors.transparent, 
              onTap: () => {
                windowManager.minimize()
              },
              child: Container(
                height: 15,
                width: 15,
                decoration: BoxDecoration(
                  color: orangeAnimation.value,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            InkWell(
              splashColor: Colors.transparent, 
              onTap: () => {
                windowManager.setFullScreen(true)
              },
              child: Container(
                height: 15,
                width: 15,
                decoration: BoxDecoration(
                  color: greenAnimation.value,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
