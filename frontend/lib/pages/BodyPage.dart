import 'package:flutter/material.dart';
import 'package:frontend/controllers/BrowserTabsController.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/pages/WebView.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BodyPageDart extends StatefulWidget {
  final BrowserTabsController webController;
  const BodyPageDart({super.key, required this.webController});

  @override
  State<BodyPageDart> createState() => _BodyPageDartState();
}

class _BodyPageDartState extends State<BodyPageDart> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      padding: EdgeInsets.all(7.5),
      decoration: BoxDecoration(
        color: CustomColors.primary,
        borderRadius: BorderRadius.circular(10)
      ),
      child: Row(
        children: [
          widget.webController.getCurrentTab() == null ? Container() : 
          Expanded(child: CustomWebView(controller: widget.webController.getCurrentTab()!.webController!))
        ],
      ),
    );
  }
}