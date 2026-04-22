import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
    ..setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36');
  
  onReady?.call(controller);
  if (injectionScript == "") getReady!.call();

  controller.addJavaScriptChannel(
    'HaloAuthReady',
    onMessageReceived: (_) {
      getReady!.call();
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
            print("JS injection threw: $e");
          }
        } else {
          onReady?.call(controller);
        }
      },
      onWebResourceError: (e) => print("WEB ERROR: ${e.description}"),
      onHttpError: (HttpResponseError error) {},
      onNavigationRequest: (NavigationRequest request) {
        print(request.url + " " + url.split("/")[2]);
        if(exit != null && request.url != url && request.url.contains(domain)) exit!.call();
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
    onWebViewCreated: (controller) {
      webBundle.controller = controller;
      controller.addJavaScriptHandler(handlerName: 'HaloAuthReady', callback: (_) {
        getReady!.call();
      });
    },
    onLoadStop: (controller, url) {
      if(injectionScript == "") {
        onReady?.call(webBundle);
      } else {
        controller.injectJavascriptFileFromAsset(assetFilePath: injectionScript);
      }
    },
    shouldOverrideUrlLoading: (controller, navigationAction) async {
      if (!navigationAction.isForMainFrame) {
        return NavigationActionPolicy.ALLOW;
      }
      
      final requestUrl = navigationAction.request.url?.toString() ?? '';
      
      if (exit != null && requestUrl != url && requestUrl.contains(domain)) {
        exit!.call();
      }
      
      return NavigationActionPolicy.ALLOW;
    },
  );

  return webBundle;
}