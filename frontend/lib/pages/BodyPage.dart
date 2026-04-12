import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/controllers/AppController.dart';
import 'package:frontend/pages/views/AISummaryView.dart';
import 'package:frontend/pages/views/WebView.dart';
import 'package:frontend/widgets/OverlayWidgets/AddSubSection.dart';
import 'package:frontend/widgets/OverlayWidgets/BottomNavModal.dart';

class BodyPageDart extends ConsumerStatefulWidget {
  final AppController webController;
  const BodyPageDart({super.key, required this.webController});

  @override
  ConsumerState<BodyPageDart> createState() => _BodyPageDartState();
}

class _BodyPageDartState extends ConsumerState<BodyPageDart> {
  @override
  Widget build(BuildContext context) {
    bool tabExists = widget.webController.getCurrentTab() != null;
    WindowInfo? currentTab = widget.webController.getCurrentTab();
    return Container(
      margin: EdgeInsets.fromLTRB(5, 0, 5, 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: EdgeInsets.all(5),
                  child: Row(
                    spacing: 5,
                    children: tabExists ? currentTab!.pages.map((AppPage page) {
                      switch(page) {
                        case AppPage.PORTAL:
                          return Expanded(child: CustomWebView(controller: currentTab.portalController!));
                        case AppPage.GRAPH_VIEWER:
                          return Expanded(child: CustomWebView(controller: currentTab.chartController!));
                        case AppPage.NOTIFICATIONS:
                          return Expanded(child: AISummaryView());
                      }
                    }).toList() : []
                  ),
                ),
                tabExists ? 
                  AddSubSection(side: Side.left, controller: widget.webController) : SizedBox(),
                tabExists ? AddSubSection(side: Side.right, controller: widget.webController) : SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
