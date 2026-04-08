import 'package:flutter/material.dart';
import 'package:frontend/widgets/window_tab.dart';
import 'package:uuid/uuid.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WindowInfo {
  final List<String> activeStocks;
  final WebViewController? webController;
  late bool isActive;
  late String uuid;

  WindowInfo({required this.activeStocks, required this.webController, required this.isActive}){
    uuid = const Uuid().v4();
  }
}

class BrowserTabsController extends ChangeNotifier{
  List<WindowInfo> tabs = [];

  void newTab() {
    final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          // Update loading bar.
        },
        onPageStarted: (String url) {},
        onPageFinished: (String url) {},
        onHttpError: (HttpResponseError error) {},
        onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.startsWith('https://www.youtube.com/')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    )

    ..loadRequest(Uri.parse('https://flutter.dev'));
    tabs.add(
      WindowInfo(webController: controller, activeStocks: ["IXIC", "IXIC", "IXIC", "IXIC"], isActive: true)
    );

    notifyListeners();
  }

  WindowInfo? getCurrentTab() {
    for(WindowInfo window in tabs) {
      if(window.isActive) return window;
    }
    
    return null;
  }

  void switchTab(WindowInfo tab) {
    for(WindowInfo window in tabs) {
      if(window.uuid == tab.uuid) {
        window.isActive = true;
      } else {
        window.isActive = false;
      }
    }

    notifyListeners();
  }

}