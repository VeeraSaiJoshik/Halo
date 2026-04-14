import 'package:flutter/material.dart';
import 'package:frontend/controllers/DataIntakeController.dart';
import 'package:frontend/engine/clients/alpaca_client.dart';
import 'package:frontend/engine/clients/binance_client.dart';
import 'package:frontend/engine/clients/finnhub_client.dart';
import 'package:frontend/engine/stocks/ticker_identifier.dart';
import 'package:frontend/models/stocks.dart';
import 'package:frontend/services/app_event_bus.dart';
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
  bool aiListenerReady = false;
  bool browserControllerReady = false;

  List<String> notifications = [];

  IntakeService intakeService;

  void portalDomListener(String DOM) {}
  void chartDomListener(String DOM) {}

  void updateNotification(String notification) {
    notifications.add(notification);
  }
  
  Future<bool> initializeChartDomListener() async {
    try{
      await chartController!.runJavaScript('''
        const meta = document.querySelector('meta[name="viewport"]');
        if (meta) meta.content = 'width=device-width, initial-scale=1.0, user-scalable=yes';
        
        const observer = new MutationObserver((mutations) => {
          mutations.forEach((mutation) => {
            // Send data back to Flutter
            window.flutter_inappwebview.callHandler('onDOMChange', {
              type: mutation.type,
              target: mutation.target.id || mutation.target.className
            });
          });
        });

        observer.observe(document.body, {
          childList: true,
          subtree: true,
          attributes: true,
          characterData: true
        });
      ''');

      chartController!.addJavaScriptChannel(
        'onDOMChange',
        onMessageReceived: (message) {
          chartDomListener(message.message);
        },
      );

      return true;
    } catch (e) {
      print("Error initializing chart DOM listener: $e");
      return false;
    }
  }

  Future<bool> initializePortalDomListener() async {
    try {
      await portalController!.runJavaScript('''
        const meta = document.querySelector('meta[name="viewport"]');
        if (meta) meta.content = 'width=device-width, initial-scale=1.0, user-scalable=yes';

        const observer = new MutationObserver((mutations) => {
          mutations.forEach((mutation) => {
            // Send data back to Flutter
            window.flutter_inappwebview.callHandler('onDOMChange', {
              type: mutation.type,
              target: mutation.target.id || mutation.target.className
            });
          });
        });

        observer.observe(document.body, {
          childList: true,
          subtree: true,
          attributes: true,
          characterData: true
        });
      ''');

      portalController!.addJavaScriptChannel(
        'onDOMChange',
        onMessageReceived: (message) {
          portalDomListener(message.message);
        },
      );
      return true;
    } catch (e) {
      print("Error initializing portal DOM listener: $e");
      return false;
    }
  }

  WindowInfo({required this.Stock, required this.portalController, required this.chartController, required this.isActive, required AppEventBus eventBus,pages}): intakeService = IntakeService(
    alpacaClient: AlpacaClient(
      apiKey: String.fromEnvironment("ALPACA_API_KEY"), 
      secretKey: String.fromEnvironment("ALPACA_API_SECRET")
    ),
    binanceClient: BinanceClient(),
    finnhubClient: FinnhubClient(apiKey: String.fromEnvironment("FINNHUB_API_KEY")),
    eventBus: eventBus,
  ){
    intakeService.updateNotifications = updateNotification;

    if(pages == null) {
      this.pages = [AppPage.PORTAL];
    } else {
      this.pages = pages;
    }
    uuid = const Uuid().v4();
  }

  Future<bool> initializeBrowserServices() async {
    await initializeChartDomListener();
    await initializePortalDomListener();

    browserControllerReady = true;
    print("Browser services initialized for ${Stock.symbol}");

    return true;
  }

  Future<void> dispose() async {
    await portalController!.removeJavaScriptChannel('onDOMChange');
    await chartController!.removeJavaScriptChannel('onDOMChange');
    intakeService.dispose();
  }

  Future<bool> initializeIntakeService() async {
    TickerInfo? info = await intakeService.initializeInput(
      Stock.symbol,
      "5m"
    );
    aiListenerReady = true;

    return false;
  }
}

class AppController extends ChangeNotifier{
  List<WindowInfo> tabs = [];
  IntakeService intakeEngine;

  AppController({required this.intakeEngine});

  void newTab(StockName stock, AppEventBus eventBus) {
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

    WindowInfo newTab = WindowInfo(portalController: portalController, chartController: chartingController, Stock: stock, isActive: true, eventBus: eventBus);
    newTab.initializeBrowserServices().then((_) => notifyListeners());
    newTab.initializeIntakeService().then((_) => notifyListeners());

    tabs.add(
      newTab
    );

    switchTab(tabs.elementAt(tabs.length - 1));
  }

  WindowInfo? getCurrentTab() {
    for(WindowInfo window in tabs) {
      if(window.isActive) return window;
    }
    
    return null;
  }

  void switchTab(WindowInfo tab) {
    late WindowInfo currentTab;
    for(WindowInfo window in tabs) {
      if(window.uuid == tab.uuid) {
        currentTab = window;
        window.isActive = true;
      } else {
        window.isActive = false;
      }
    }

    notifyListeners();
  }

  void switchTabSubPage(AppPage page) {
    getCurrentTab()!.pages = [page];
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

  void toggleNotifications() {
    if(getCurrentTab()!.pages.contains(AppPage.NOTIFICATIONS)) {
      closeSubPage(AppPage.NOTIFICATIONS);
    } else {
      addNewSubPage(AppPage.NOTIFICATIONS, Side.right);
    }
  }

  Future<void> removeTab(WindowInfo tab) async {
    WindowInfo currentTab = tabs.firstWhere((WindowInfo element) => element.uuid == tab.uuid);
    await currentTab.dispose();

    tabs.removeWhere((window) => window.uuid == tab.uuid);
    if(tabs.isNotEmpty) switchTab(tabs.first);
    notifyListeners();
  }

}