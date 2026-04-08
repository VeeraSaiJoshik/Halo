import 'package:flutter/material.dart';
import 'package:frontend/models/customColors.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CustomWebView extends StatefulWidget {
  final WebViewController controller;
  const CustomWebView({super.key, required this.controller});

  @override
  State<CustomWebView> createState() => _WebViewState();
}

class _WebViewState extends State<CustomWebView> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      onHover: (hoverState) {
        setState(() {
          hover = hoverState;
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: CustomColors.primary, 
            borderRadius: BorderRadius.circular(5)
          ),
          child: Stack(children: [
            WebViewWidget(controller: widget.controller),
            LiquidGlassLayer(
              settings: LiquidGlassSettings(
                blur: 10,
                glassColor: Color(0x33FFFFFF)
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0, 
                    right: 0, 
                    top: 10,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LiquidGlass(
                            child: Container(
                              width: 25, 
                              height: 25
                            ), shape: LiquidRoundedRectangle(borderRadius: 5)
                          )
                        ],
                      )
                    )
                  )
                ],
              )
            )
          ],)
        ),
      ),
    );
  }
}