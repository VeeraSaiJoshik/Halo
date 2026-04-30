import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/controllers/WebViewController.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/themes/halo_theme.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AuthWebView extends StatefulWidget {
  void Function() closeFunction;
  bool loadWebView;
  WebBundle? controller;
  HaloThemeData theme;
  AuthWebView({super.key, required this.closeFunction, required this.loadWebView, required this.controller, required this.theme});

  @override
  State<AuthWebView> createState() => _AuthWebViewState();
}

class _AuthWebViewState extends State<AuthWebView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity, 
      width: double.infinity,
      color: widget.theme.backgroundColor,
      margin: EdgeInsets.only(top: 15),
      child: Stack(
        children: [
          !widget.loadWebView ? Center(
            child: CircularProgressIndicator(color: widget.theme.whiteColor,),
          ) : Container(),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AnimatedOpacity(
              opacity: widget.loadWebView ? 1 : 0, 
              duration: Duration(milliseconds: 250),
              child: widget.controller!.widget!
            )
          ), 
          Positioned(
            top: 15,
            left: 15,
            child: AnimatedOpacity(
              opacity: widget.loadWebView ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: _WebViewCloseButton(
                theme: widget.theme,
                onTap: widget.closeFunction,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _WebViewCloseButton extends StatefulWidget {
  final VoidCallback onTap;
  final HaloThemeData theme;
  const _WebViewCloseButton({required this.onTap, required this.theme});

  @override
  State<_WebViewCloseButton> createState() => _WebViewCloseButtonState();
}

class _WebViewCloseButtonState extends State<_WebViewCloseButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) => setState(() => _pressed = false),
        onTapCancel: ()  => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.92 : _hovered ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: AnimatedRotation(
            turns: _hovered ? -0.02 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                children: [
                  // Glassmorphic base with accent fill
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: widget.theme.primaryColor.withValues(alpha: _hovered ? 1.0 : 0.9),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: widget.theme.whiteColor.withValues(alpha: 0.18),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.theme.primaryColor.withValues(alpha: _hovered ? 0.45 : 0.25),
                              blurRadius: _hovered ? 22 : 14,
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: widget.theme.whiteColor.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Inner highlight (top-left frost sheen)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.theme.whiteColor.withValues(alpha: 0.22),
                            widget.theme.whiteColor.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.55],
                        ),
                      ),
                    ),
                  ),
                  // X icon
                  Center(
                    child: FaIcon(
                      FontAwesomeIcons.x,
                      size: 13,
                      color: widget.theme.whiteColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}