import 'package:webview_flutter/webview_flutter.dart';

WebViewController createWebViewController(String url, {String injectionScript = "", void Function(WebViewController)? onReady, void Function()? getReady}) {
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
        if (request.url.startsWith('https://www.youtube.com/')) {
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
    ),
  )..loadRequest(Uri.parse(url));

  return controller;
}
