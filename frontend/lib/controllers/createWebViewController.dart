import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:frontend/browser/browser_constants.dart';
import 'package:frontend/browser/navigation_key.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebBundle {
  InAppWebView? widget;
  late InAppWebViewController controller;
}

WebBundle createInAppWebView(
  String url,
  {
    String domain = "",
    String injectionScript = "",
    void Function(WebBundle)? onReady,
    void Function()? getReady,
    void Function()? exit
  }
) {
  WebBundle webBundle = WebBundle();
  bool _handlerRegistered = false;

  webBundle.widget = InAppWebView(
    initialUrlRequest: URLRequest(url: WebUri(url)),
    initialUserScripts: UnmodifiableListView<UserScript>([
      UserScript(
        source: kStealthScript,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
    ]),
    initialSettings: InAppWebViewSettings(
      userAgent: kDesktopChromeUA,
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      supportMultipleWindows: true,
      useShouldOverrideUrlLoading: true,
      sharedCookiesEnabled: false,
      thirdPartyCookiesEnabled: true,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      disableContextMenu: false,
      disableHorizontalScroll: false,
      disableVerticalScroll: false,
      // Enable Safari DevTools inspection in debug mode:
      // Safari → Develop → <device> → <page>
      isInspectable: kDebugMode,
    ),
    onLoadStop: (controller, url) {
      if (injectionScript != "") {
        webBundle.controller = controller;
    
        onReady?.call(webBundle);
        if (!_handlerRegistered) {
          _handlerRegistered = true;
          controller.addJavaScriptHandler(
            handlerName: 'HaloAuthReady',
            callback: (_) {
              print("recieved");
              getReady?.call();
            },
          );
        }
        controller.injectJavascriptFileFromAsset(assetFilePath: injectionScript);
        print("Injection was succesfull");
      } else {
        getReady?.call();
      }
    },
    onConsoleMessage: (controller, message) {
      print(message.message);
    },
    onCreateWindow: (controller, createWindowAction) async {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return false;
      _showOAuthPopup(
        context: ctx,
        createWindowAction: createWindowAction,
        onClosed: () => controller.reload(),
      );
      return true;
    },
    shouldOverrideUrlLoading: (controller, navigationAction) async {
      if (!navigationAction.isForMainFrame) return NavigationActionPolicy.ALLOW;

      print("I am here with overload");
      final requestUrl = navigationAction.request.url?.toString() ?? '';
      if (exit != null && requestUrl != url && requestUrl.contains(domain)) {
        exit.call();
      }

      return NavigationActionPolicy.ALLOW;
    },
  );

  onReady?.call(webBundle);

  return webBundle;
}

void _showOAuthPopup({
  required BuildContext context,
  required CreateWindowAction createWindowAction,
  VoidCallback? onClosed,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF0E0E1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 500,
        height: 700,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                  onPressed: () {
                    if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                  },
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: InAppWebView(
                  windowId: createWindowAction.windowId,
                  initialUserScripts: UnmodifiableListView<UserScript>([
                    UserScript(
                      source: kStealthScript,
                      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                    ),
                  ]),
                  initialSettings: InAppWebViewSettings(
                    userAgent: kDesktopChromeUA,
                    javaScriptEnabled: true,
                    javaScriptCanOpenWindowsAutomatically: true,
                    supportMultipleWindows: true,
                    sharedCookiesEnabled: false,
                    thirdPartyCookiesEnabled: true,
                    isInspectable: kDebugMode,
                  ),
                  onCloseWindow: (_) {
                    if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ).then((_) => onClosed?.call());
}
