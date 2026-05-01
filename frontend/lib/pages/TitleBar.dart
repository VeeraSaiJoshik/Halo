import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/services/app_event_bus.dart';
import 'package:frontend/widgets/commandButtons.dart';
import 'package:frontend/widgets/window_tab.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class TitleBar extends ConsumerStatefulWidget {
  const TitleBar({super.key});

  @override
  ConsumerState<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends ConsumerState<TitleBar> {
  void initState() {
    super.initState();

    ref.read(appEventBusProvider).stream.listen((event) {
      if(event == AppEvent.newNotifcation) {
        setState(() {});
      }
    });
  }

  double newTabTilt = 0;
  bool _newTabPressed = false;
  double _settingsTilt = 0;
  bool _settingsPressed = false;

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
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => newTabTilt = 0.05),
            onExit:  (_) => setState(() => newTabTilt = 0),
            child: GestureDetector(
              onTap: () => ref.read(appEventBusProvider).emit(AppEvent.openSearch),
              onTapDown:   (_) => setState(() => _newTabPressed = true),
              onTapUp:     (_) => setState(() => _newTabPressed = false),
              onTapCancel: ()  => setState(() => _newTabPressed = false),
              child: SizedBox(
                height: 38,
                child: Center(
                  child: AnimatedScale(
                    scale: _newTabPressed ? 0.75 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOut,
                    child: AnimatedRotation(
                      turns: newTabTilt,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: FaIcon(FontAwesomeIcons.plus, size: 15, color: CustomColors.background),
                    ),
                  ),
                )
              ),
            ),
          ),
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _settingsTilt = 0.08),
            onExit:  (_) => setState(() => _settingsTilt = 0),
            child: GestureDetector(
              onTap: () => ref.read(appEventBusProvider).emit(AppEvent.openSettings),
              onTapDown:   (_) => setState(() => _settingsPressed = true),
              onTapUp:     (_) => setState(() => _settingsPressed = false),
              onTapCancel: ()  => setState(() => _settingsPressed = false),
              child: SizedBox(
                height: 38,
                width: 32,
                child: Center(
                  child: AnimatedScale(
                    scale: _settingsPressed ? 0.78 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOut,
                    child: AnimatedRotation(
                      turns: _settingsTilt,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: FaIcon(
                        FontAwesomeIcons.gear,
                        size: 14,
                        color: controller.settingsOpen
                            ? CustomColors.background
                            : CustomColors.background.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
