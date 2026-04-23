import 'package:flutter/material.dart';
import 'package:frontend/controllers/DataIntakeController.dart';
import 'package:frontend/controllers/createWebViewController.dart';
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
  final WebBundle? portalController;
  final WebBundle? chartController;
  late bool isActive;
  late String uuid;
  late List<AppPage> pages;
  bool aiListenerReady = false;
  bool browserControllerReady = true;

  List<String> notifications = [];

  IntakeService intakeService;

  void portalDomListener(String DOM) {}
  void chartDomListener(String DOM) {}

  void updateNotification(String notification) {
    notifications.add(notification);
  }

  WindowInfo({required this.Stock, required this.portalController, required this.chartController, required this.isActive, required AppEventBus eventBus,pages}): intakeService = IntakeService(
    alpacaClient: AlpacaClient(
      apiKey: const String.fromEnvironment("ALPACA_API_KEY"), 
      secretKey: const String.fromEnvironment("ALPACA_API_SECRET")
    ),
    binanceClient: BinanceClient(),
    finnhubClient: FinnhubClient(apiKey: const String.fromEnvironment("FINNHUB_API_KEY")),
    eventBus: eventBus,
  ){
    print("ALPACA_API_KEY : ${const String.fromEnvironment("ALPACA_API_KEY")}");
    print("ALPACA_API_SECRET : ${const String.fromEnvironment("ALPACA_API_SECRET")}");
    print("FINNHUB_API_KEY : ${const String.fromEnvironment("FINNHUB_API_KEY")}");

    intakeService.updateNotifications = updateNotification;

    if(pages == null) {
      this.pages = [AppPage.PORTAL];
    } else {
      this.pages = pages;
    }
    uuid = const Uuid().v4();
  }

  Future<void> dispose() async {
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
    final tabExists = tabs.indexWhere((tab) => tab.Stock.symbol == stock.symbol);

    if(tabExists != -1) {
      switchTab(tabs.elementAt(tabExists));
      return;
    }

    final portalController = createInAppWebView(
      'https://www.webull.com/center', 
      injectionScript: "assets/scripts/dom_listener.js",
    );
    final chartingController = createInAppWebView(
      'https://www.tradingview.com/chart/d3IIUEuI/', 
      injectionScript: "assets/scripts/dom_listener.js"
    );

    WindowInfo newTab = WindowInfo(portalController: portalController, chartController: chartingController, Stock: stock, isActive: true, eventBus: eventBus);

    tabs.add(
      newTab
    );

    newTab.initializeIntakeService().then((_) => notifyListeners());

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
    print("Adding a new subpage ${page} ${side} ${getCurrentTab()!.pages}");

    if(side == Side.right) {
      getCurrentTab()!.pages.add(page);
    } else {
      getCurrentTab()!.pages.insert(0, page);
    }

    print("Adding a new subpage ${page} ${side} ${getCurrentTab()!.pages}");
    
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