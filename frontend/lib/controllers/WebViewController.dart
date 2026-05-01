import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:frontend/browser/browser_constants.dart';
import 'package:frontend/browser/navigation_key.dart';
import 'package:frontend/pages/OnboardingPage.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebBundle {
  InAppWebView? widget;
  InAppWebViewController? controller;
  int initialCookies = 0;

  VoidCallback? reloadState;

  void reload() {
    if(controller != null) {
      controller!.reload();
    }
  }
}

Future<int> countCookies(FormController controller) async {
    List<String> links = [];

    if (controller.currentIndex == 2) {
      links = controller.selectedBuyingPlatform!.links;
    } else if (controller.currentIndex == 4) {
      links = controller.selectedChartingPlatform!.links;
    }

    int curCount = 0;
    for(String link in links) {
      curCount += (await CookieManager.instance().getCookies(url: WebUri(link))).length;
    }

    return curCount;
  }

WebBundle createInAppWebView(
  String url,
  {
    String domain = "",
    String injectionScript = "",
    void Function(WebBundle)? onReady,
    void Function()? getReady,
    void Function()? exit, 
    bool isAuth = false, 
    List<UserScript> startupScripts = const []
  }
) {
  WebBundle webBundle = WebBundle();
  bool _handlerRegistered = false;

  final scripts = [
    UserScript(
      source: kStealthScript,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
  ];

  if (isAuth) {
    scripts.add(UserScript(
      source: """
        localStorage.clear();
        sessionStorage.clear();
        console.log("successfully cleared storage");
      """,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ));
  }
  scripts.addAll(startupScripts);

  // Then use it:
  print("Auth is ${isAuth} ${scripts}");

  bool firstLoad = true;

  webBundle.widget = InAppWebView(
    initialUrlRequest: URLRequest(url: WebUri(url)),
    initialUserScripts: UnmodifiableListView<UserScript>(scripts),
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
      isInspectable: kDebugMode,
    ),
    onWebViewCreated: (controller) async {
      webBundle.controller = controller;
      
      if (isAuth) {
        final cookieManager = CookieManager.instance();
        
        // See what cookies exist BEFORE deletion
        final before = await cookieManager.getCookies(url: WebUri("https://passport.webull.com"));
        print("BEFORE deletion: ${before.map((c) => '${c.name}=${c.value}').join(', ')}");
        
        for (final domain in [
          "https://webull.com",
          "https://www.webull.com",
          "https://app.webull.com",
          "https://userapi.webull.com",
          "https://trade.webull.com",
          "https://passport.webull.com",
        ]) {
          await cookieManager.deleteCookies(url: WebUri(domain));
        }
        
        // Confirm they're gone AFTER deletion
        final after = await cookieManager.getCookies(url: WebUri("https://passport.webull.com"));
        print("AFTER deletion: ${after.map((c) => '${c.name}=${c.value}').join(', ')}");
      }
    },
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
      print("Console message : " + message.message);
    },
    onCreateWindow: (controller, createWindowAction) async {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return false;
      
      return true;
    },
    shouldOverrideUrlLoading: (controller, navigationAction) async {
      if (firstLoad) {
        firstLoad = false;
        return NavigationActionPolicy.ALLOW;
      }
      if (!navigationAction.isForMainFrame) return NavigationActionPolicy.ALLOW;

      print("I am here with overload ${navigationAction.request.url} ${url}");
      final requestUrl = navigationAction.request.url?.toString() ?? '';
      if (exit != null && requestUrl.contains(domain)) {
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

