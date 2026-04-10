import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/controllers/AppController.dart';
import 'package:frontend/models/customColors.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WindowTab extends StatefulWidget {
  final WindowInfo context;
  final Function switchTab;
  const WindowTab({super.key, required this.context, required this.switchTab});

  @override
  State<WindowTab> createState() => _WindowTabState();
}

class _WindowTabState extends State<WindowTab>
    with SingleTickerProviderStateMixin {
  static const _borderRadius = BorderRadius.only(
    topLeft: Radius.circular(5),
    topRight: Radius.circular(5),
  );

  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      onHover: (hover) => setState(() => isHovering = hover),
      onTap: () => widget.switchTab(widget.context),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
        child: BackdropFilter(
          filter: widget.context.isActive ? ImageFilter.blur(sigmaX: 20, sigmaY: 20) : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            decoration: widget.context.isActive ?  BoxDecoration(
                borderRadius: _borderRadius,
                color: Colors.black.withOpacity(0.6),
              ) : BoxDecoration(
                borderRadius: _borderRadius,
                color: Colors.transparent 
              ),
            height: 34,
            width: 240,
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 17, 
                  width: 17, 
                  child: Image.network(
                    widget.context.Stock.imageUrl,
                    fit: BoxFit.contain
                  ),
                ),
                SizedBox(width: 8),
                Row(
                  spacing: 8,
                  children: [
                    Text(
                      widget.context.Stock.symbol, 
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ) 
                  ],
                ),
                Expanded(child: SizedBox()),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  height: 25,
                  decoration: BoxDecoration(
                    color: widget.context.isActive
                        ? Colors.red.withOpacity(0.4)
                        : Colors.grey.withAlpha(50),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center, 
                    mainAxisAlignment: MainAxisAlignment.center, 
                    mainAxisSize: MainAxisSize.min,
                    spacing: 3,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.arrowDown, 
                        color: Colors.white,
                        size: 12,
                      ),
                      Text(
                        '-0.42%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]
                  )
                ),
                Container(
                  width: 5
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  height: 25,
                  decoration: BoxDecoration(
                    color: widget.context.isActive
                        ? Colors.blue.withOpacity(0.4)
                        : Colors.grey.withAlpha(50),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      '9+',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
