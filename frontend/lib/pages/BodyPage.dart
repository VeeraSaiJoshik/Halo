import 'package:flutter/material.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/pages/WebView.dart';

class BodyPageDart extends StatefulWidget {
  const BodyPageDart({super.key});

  @override
  State<BodyPageDart> createState() => _BodyPageDartState();
}

class _BodyPageDartState extends State<BodyPageDart> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10, 
      width: double.infinity,
      decoration: BoxDecoration(
        color: CustomColors.accent,
        borderRadius: BorderRadius.circular(10)
      ),
      child: Row(
        children: [
          Expanded(child: WebView())
        ],
      ),
    );
  }
}