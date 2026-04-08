import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/controllers/BrowserTabsController.dart';
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
    topLeft: Radius.circular(10),
    topRight: Radius.circular(10),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            decoration: widget.context.isActive
                ? BoxDecoration(
                    borderRadius: _borderRadius,
                    gradient: RadialGradient(
                      center: Alignment(-1, -1),
                      radius: 0.9,
                      colors: [
                        CustomColors.primary.withOpacity(0.6),
                        CustomColors.primary,
                      ],
                    ),
                  )
                : isHovering
                ? BoxDecoration(
                    borderRadius: _borderRadius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        CustomColors.primary.withAlpha(150),
                        CustomColors.primary.withAlpha(150),
                        CustomColors.primary.withAlpha(150),
                        CustomColors.primary.withAlpha(150),
                        CustomColors.primary.withAlpha(150),
                        CustomColors.primary,
                      ],
                    ),
                  )
                : BoxDecoration(
                    borderRadius: _borderRadius,
                    color: Colors.transparent,
                  ),
            height: 38,
            width: 240,
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Image.network(
                  "https://companieslogo.com/img/orig/BULL.D-6d2a06d1.png?t=1744647436",
                  width: 20,
                  height: 20,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Row(
                  spacing: 8,
                  children: [
                    ...widget.context.activeStocks.indexed.map((
                      (int, String) entry,
                    ) {
                      final isLast =
                          entry.$1 == widget.context.activeStocks.length - 1;
                      return Row(
                        spacing: 8,
                        children: [
                          Text(
                            entry.$2,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!isLast)
                            Container(
                              height: 29,
                              width: 1,
                              color: Colors.white.withAlpha(100),
                            ),
                        ],
                      );
                    }),
                  ],
                ),
                Expanded(child: SizedBox()),
                Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    color: widget.context.isActive
                        ? Colors.blue
                        : Colors.grey.withAlpha(100),
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
        ],
      ),
    );
  }
}
