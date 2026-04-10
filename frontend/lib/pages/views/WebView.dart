import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/widgets/OverlayWidgets/TopNavModal.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CustomWebView extends StatefulWidget {
  final WebViewController controller;
  const CustomWebView({super.key, required this.controller});

  @override
  State<CustomWebView> createState() => _WebViewState();
}

class _WebViewState extends State<CustomWebView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: CustomColors.primary,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Stack(
          children: [ 
            WebViewWidget(controller: widget.controller),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Center(
                child: MouseRegion(
                  onEnter: (_) => _animController.forward(),
                  onExit: (_) => _animController.reverse(),
                  child: Container(
                    height: 60,
                    width: 216,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SlideTransition(
                          position: _slideAnimation,
                          child: Center(
                            child: TopNavModel(
                              goBack: widget.controller.goBack, 
                              goForward: widget.controller.goForward, 
                              url: "https://www.google.com"
                            )
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
