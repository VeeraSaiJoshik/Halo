import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/controllers/AppController.dart';
import 'package:frontend/models/customColors.dart';

class BottomNavModal extends StatelessWidget {
  AppController controller;
  BottomNavModal({super.key, required this.controller});

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
          InkWell(
            mouseCursor: SystemMouseCursors.click,
            splashColor: Colors.transparent,
            onTap: () => {
              controller.switchTabSubPage(AppPage.GRAPH_VIEWER)
            },
            child: BototmNavBarIcons(icon: "stocks", directionMulti: 1, showFrost: controller.getCurrentTab()!.pages[0] == AppPage.GRAPH_VIEWER ,),
          ),
          InkWell(
            mouseCursor: SystemMouseCursors.click,
            splashColor: Colors.transparent,
            onTap: () => {
              controller.switchTabSubPage(AppPage.GRAPH_VIEWER)
            },
            child: BototmNavBarIcons(icon: "search", showFrost: controller.getCurrentTab()!.pages[0] == AppPage.GRAPH_VIEWER),
          ),
          InkWell(
            mouseCursor: SystemMouseCursors.click,
            splashColor: Colors.transparent,
            onTap: () => {
              controller.switchTabSubPage(AppPage.GRAPH_VIEWER)
            },
            child: BototmNavBarIcons(icon: "icon", directionMulti: -1, showFrost: controller.getCurrentTab()!.pages[0] == AppPage.GRAPH_VIEWER)
          ),
        ],
      ),
    );
  }
}

class BototmNavBarIcons extends StatefulWidget {
  final String icon;
  final int directionMulti;
  bool showFrost;
  bool isAccented;
  BototmNavBarIcons({super.key, required this.icon, this.directionMulti = 0, this.showFrost = false, this.isAccented = false});

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
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 47,
                height: 47,
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: CustomColors.accent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: widget.isAccented
                        ? CustomColors.accent.withValues(alpha: 0.6)
                        : CustomColors.background.withValues(alpha: 0.07),
                    width: 2,
                  ),
                  boxShadow: widget.isAccented
                      ? [
                          BoxShadow(
                            color: CustomColors.accent.withValues(alpha: 0.35),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Image.asset(
                  "assets/images/${widget.icon}.png",
                  fit: BoxFit.cover,
                ),
              ),
              AnimatedOpacity(
                opacity: _hovered || widget.showFrost || widget.isAccented ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 47,
                  height: 47,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isAccented
                          ? [
                              CustomColors.accent.withValues(alpha: 0.30),
                              CustomColors.accent.withValues(alpha: 0.10),
                              CustomColors.accent.withValues(alpha: 0.00),
                            ]
                          : [
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