import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:frontend/browser/browser_constants.dart';
import 'package:frontend/browser/navigation_key.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebBundle {
  InAppWebView? widget;
  InAppWebViewController? controller;

  void reload() {
    if(controller != null) {
      controller!.reload();
    }
  }
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
    onWebViewCreated: (controller) => webBundle.controller = controller,
    onLoadStop: (controller, url) {
      if (injectionScript != "") {
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

  if (onReady != null) {
    onReady?.call(webBundle);
  }

  return webBundle;
}
