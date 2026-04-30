import 'package:flutter/material.dart';
import 'package:frontend/services/cef_cookie_bridge.dart';
import 'package:webview_cef/webview_cef.dart';

typedef IsSuccessUrl = bool Function(String url);

class CefAuthView extends StatefulWidget {
  final String loginUrl;
  final String cookieDomain;
  final IsSuccessUrl isSuccessUrl;
  final VoidCallback onLoaded;
  final VoidCallback onSuccess;

  const CefAuthView({
    super.key,
    required this.loginUrl,
    required this.cookieDomain,
    required this.isSuccessUrl,
    required this.onLoaded,
    required this.onSuccess,
  });

  @override
  State<CefAuthView> createState() => _CefAuthViewState();
}

class _CefAuthViewState extends State<CefAuthView> {
  late final WebViewController _controller;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebviewManager().createWebView();
    _controller.setWebviewListener(WebviewEventsListener(
      onUrlChanged: _handleUrlChanged,
      onLoadEnd: (controller, url) {
        if (!_completed) widget.onLoaded();
      },
    ));
    _controller.initialize(widget.loginUrl);
  }

  Future<void> _handleUrlChanged(String url) async {
    if (_completed) return;
    if (!widget.isSuccessUrl(url)) return;

    _completed = true;
    await migrateCefCookiesToInAppWebView([widget.cookieDomain]);
    if (!mounted) return;
    widget.onSuccess();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _controller,
      builder: (context, ready, _) {
        if (!ready) return const SizedBox.shrink();
        return _controller.webviewWidget;
      },
    );
  }
}
