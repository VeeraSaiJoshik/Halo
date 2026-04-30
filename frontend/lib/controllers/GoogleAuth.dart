import 'dart:collection';
import 'package:flutter/scheduler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

String getJavaScriptByPlatform(String platform_id){
  switch(platform_id) {
    case "Webull" : return "";
    case "Robinhood" : return "";
    case "TradingView" : return "";
  }

  return "";
}

bool _isGoogleAuthUrl(String url) {
  return url.contains('accounts.google.com') ||
         url.contains('google.com/o/oauth2') ||
         url.contains('oauth2/auth');
}

void createGoogleAuthWebView(String url, String platform_id, Function redirectUrl) {
  HeadlessInAppWebView? headlessView;

  headlessView = HeadlessInAppWebView(
    initialUrlRequest: URLRequest(url: WebUri(url)), 
    initialUserScripts: UnmodifiableListView([
      UserScript(
        source: getJavaScriptByPlatform(platform_id), 
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START
      )
    ]), 
    shouldOverrideUrlLoading: (controller, nav) async {
      final requestUrl = nav.request.url?.toString() ?? '';
      if(!_isGoogleAuthUrl(requestUrl)) return NavigationActionPolicy.ALLOW;
      
      redirectUrl.call(requestUrl);
      await headlessView!.dispose();
      
      return NavigationActionPolicy.CANCEL;
    }
  );

  headlessView.run();
}
