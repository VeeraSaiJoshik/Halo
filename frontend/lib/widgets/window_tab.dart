import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/models/customColors.dart';

class WindowInfo {
  final List<String> activeStocks;

  WindowInfo({
    required this.activeStocks
  });
}

class WindowTab extends StatefulWidget {
  final WindowInfo context;
  final bool isActive;
  const WindowTab({super.key, required this.context, required this.isActive});

  @override
  State<WindowTab> createState() => _WindowTabState();
}

class _WindowTabState extends State<WindowTab> with SingleTickerProviderStateMixin {
  static const _borderRadius = BorderRadius.only(
    topLeft: Radius.circular(10),
    topRight: Radius.circular(10),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: _borderRadius,
        color: CustomColors.accent
      ),
      height: 45, 
      width: 270, 
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Image.network(
            "https://companieslogo.com/img/orig/BULL.D-6d2a06d1.png?t=1744647436",
            width: 29, 
            height: 29,
            color: Colors.white,
          ), 
          SizedBox(width: 8),
          Row(
            spacing: 8,
            children: [...widget.context.activeStocks.indexed.map(((int, String) entry) {
              final isLast = entry.$1 == widget.context.activeStocks.length - 1;
              return Row(
                spacing: 8,
                children: [
                  Text(entry.$2, style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600
                  ),),
                  if (!isLast)
                    Container(height: 29, width: 1, color: Colors.white.withAlpha(100),)
                ],
              );
            })],
          ), 
          Expanded(child: SizedBox()),
          Container(
            width: 29, 
            height: 29, 
            decoration: BoxDecoration(
              color: Colors.blue, 
              borderRadius: BorderRadius.circular(5)
            ),
            child: Center(
              child: Text('9+', style: TextStyle(
                color: Colors.white, 
                fontSize: 14, 
                fontWeight: FontWeight.w600
              ),),
            ),
          )
        ],
      )
    );
  }
}