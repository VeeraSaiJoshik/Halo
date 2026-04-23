import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:frontend/browser/browser_constants.dart';
import 'package:frontend/browser/navigation_key.dart';
import 'package:webview_flutter/webview_flutter.dart';

WebViewController createWebViewController(
  String url,
  {
    String domain = "",
    String injectionScript = "",
    void Function(WebViewController)? onReady,
    void Function()? getReady,
    void Function()? exit
  }
) {
  WebViewController controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setUserAgent(kDesktopChromeUA);

  onReady?.call(controller);
  if (injectionScript == "") getReady?.call();

  controller.addJavaScriptChannel(
    'HaloAuthReady',
    onMessageReceived: (_) {
      getReady?.call();
    }
  );

  controller..setNavigationDelegate(
    NavigationDelegate(
      onProgress: (int progress) {},
      onPageFinished: (String url) async {
        if (injectionScript != "") {
          try {
            await controller.runJavaScript(injectionScript);
          } catch (e) {
            debugPrint("JS injection threw: $e");
          }
        } else {
          onReady?.call(controller);
        }
      },
      onWebResourceError: (e) => debugPrint("WEB ERROR: ${e.description}"),
      onHttpError: (HttpResponseError error) {},
      onNavigationRequest: (NavigationRequest request) {
        if (exit != null && request.url != url && request.url.contains(domain)) exit.call();
        return NavigationDecision.navigate;
      },
    ),
  )..loadRequest(Uri.parse(url));

  return controller;
}

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
      sharedCookiesEnabled: true,
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
    onWebViewCreated: (controller) {
      webBundle.controller = controller;
      // Signal the host widget that the WebBundle is ready to embed. This must
      // happen here (not onLoadStop) so auth flows with an injectionScript
      // still get the callback — onLoadStop skips onReady when a script is set.
      onReady?.call(webBundle);
      controller.addJavaScriptHandler(
        handlerName: 'HaloAuthReady',
        callback: (_) => getReady?.call(),
      );
    },
    onLoadStop: (controller, url) {
      if (injectionScript != "") {
        controller.injectJavascriptFileFromAsset(assetFilePath: injectionScript);
      }
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

      final requestUrl = navigationAction.request.url?.toString() ?? '';
      if (exit != null && requestUrl != url && requestUrl.contains(domain)) {
        exit.call();
      }

      return NavigationActionPolicy.ALLOW;
    },
  );

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
                    sharedCookiesEnabled: true,
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
