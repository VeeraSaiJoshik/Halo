import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/controllers/AppController.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/themes/halo_theme.dart';
import 'package:frontend/themes/theme_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WindowTab extends ConsumerStatefulWidget {
  final WindowInfo context;
  final Function switchTab;
  const WindowTab({super.key, required this.context, required this.switchTab});

  @override
  ConsumerState<WindowTab> createState() => _WindowTabState();
}

class _WindowTabState extends ConsumerState<WindowTab>
    with SingleTickerProviderStateMixin {
  static const _borderRadius = BorderRadius.only(
    topLeft: Radius.circular(5),
    topRight: Radius.circular(5),
  );

  bool isHovering = false;
  bool closeButtonIsHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(haloThemeProvider);
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      onHover: (hover) => setState(() => isHovering = hover),
      onTap: () => widget.switchTab(widget.context),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
        child: BackdropFilter(
          filter: widget.context.isActive
              ? ImageFilter.blur(sigmaX: 20, sigmaY: 20)
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            decoration: widget.context.isActive
                ? BoxDecoration(
                    borderRadius: _borderRadius,
                    color: Colors.white.withOpacity(0.10),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5),
                      left: BorderSide(color: Colors.white.withOpacity(0.15)),
                      right: BorderSide(color: Colors.white.withOpacity(0.15)),
                    ),
                  )
                : isHovering
                ? BoxDecoration(
                    borderRadius: _borderRadius,
                    color: Colors.white.withOpacity(0.15),
                  )
                : BoxDecoration(
                    borderRadius: _borderRadius,
                    color: Colors.transparent,
                  ),
            height: 34,
            width: 240,
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 17,
                  width: 17,
                  child: Image.network(
                    widget.context.Stock.imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(width: 8),
                Row(
                  spacing: 8,
                  children: [
                    Text(
                      widget.context.Stock.symbol,
                      style: theme.ticker,
                    ),
                  ],
                ),
                Expanded(child: SizedBox()),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                        size: 11,
                      ),
                      Text(
                        '-0.42%',
                        style: theme.ticker,
                      ),
                    ],
                  ),
                ),
                Container(width: 5),
                InkWell(
                  onHover: (value) => setState(() {
                    closeButtonIsHovering = value;
                  }),
                  onTap: () async {
                    await ref.read(appControllerProvider).removeTab(widget.context);
                  },
                  mouseCursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeInOut,
                    width: 35,
                    margin: EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: closeButtonIsHovering
                          ? Colors.red.withOpacity(0.5)
                          : widget.context.isActive
                          ? theme.textAccent.withOpacity(0.25)
                          : Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        switchInCurve: Curves.easeIn,
                        switchOutCurve: Curves.easeOut,
                        child: closeButtonIsHovering
                            ? FaIcon(
                                key: const ValueKey('x'),
                                FontAwesomeIcons.xmark,
                                color: Colors.white.withOpacity(0.5),
                                size: 13,
                              )
                            : widget.context.aiListenerReady
                            ? widget.context.notifications.isEmpty
                                  ? FaIcon(
                                      key: const ValueKey('eye'),
                                      FontAwesomeIcons.solidEye,
                                      color: Colors.white.withOpacity(0.5),
                                      size: 13,
                                    )
                                  : Text(
                                      key: ValueKey('notif_${widget.context.notifications.length}'),
                                      '${widget.context.notifications.length > 9 ? '9+' : widget.context.notifications.length}',
                                      style: theme.ticker,
                                    )
                            : SizedBox(
                                key: const ValueKey('loading'),
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
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
