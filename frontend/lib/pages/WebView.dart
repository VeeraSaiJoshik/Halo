import 'package:flutter/material.dart';
import 'package:frontend/models/customColors.dart';

class WebView extends StatefulWidget {
  const WebView({super.key});

  @override
  State<WebView> createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      margin: EdgeInsets.all(7.5),
      decoration: BoxDecoration(
        color: CustomColors.primary, 
        borderRadius: BorderRadius.circular(5)
      ),
    );
  }
}