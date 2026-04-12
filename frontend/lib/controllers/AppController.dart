import 'package:flutter/material.dart';
import 'package:frontend/models/stocks.dart';
import 'package:frontend/widgets/OverlayWidgets/AddSubSection.dart';
import 'package:frontend/widgets/window_tab.dart';
import 'package:uuid/uuid.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum AppPage {
  PORTAL, 
  GRAPH_VIEWER, 
  NOTIFICATIONS
}

class WindowInfo {
  final StockName Stock;
  final WebViewController? portalController;
  final WebViewController? chartController;
  late bool isActive;
  late String uuid;
  late List<AppPage> pages;

  WindowInfo({required this.Stock, required this.portalController, required this.chartController, required this.isActive, pages}){
    if(pages == null) {
      this.pages = [AppPage.PORTAL];
    } else {
      this.pages = pages;
    }
    uuid = const Uuid().v4();
  }
}

class AppController extends ChangeNotifier{
  List<WindowInfo> tabs = [];

  void newTab(StockName stock) {
    final portalController = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36')
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
    ..loadRequest(Uri.parse('https://www.webull.com/center'));

    final chartingController = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36')
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
    ..loadRequest(Uri.parse('https://www.tradingview.com/chart/d3IIUEuI/'));


    tabs.add(
      WindowInfo(portalController: portalController, chartController: chartingController, Stock: stock, isActive: true)
    );
    switchTab(tabs.elementAt(tabs.length - 1));

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

  void switchTabSubPage(AppPage page) {
    //getCurrentTab()!.currentPage = page;
    notifyListeners();
  }

  void addNewSubPage(AppPage page, Side side) {
    if(side == Side.right) getCurrentTab()!.pages.add(page);
    else getCurrentTab()!.pages.insert(0, page);
    
    notifyListeners();
  }

  void closeSubPage(AppPage page) {
    getCurrentTab()!.pages.remove(page);
    notifyListeners();
  }

}