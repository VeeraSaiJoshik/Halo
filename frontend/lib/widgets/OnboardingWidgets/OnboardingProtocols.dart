import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/controllers/AppController.dart';
import 'package:frontend/controllers/createWebViewController.dart';
import 'package:frontend/themes/theme_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

abstract class AuthMethods {
  String get authName;
  Widget get authLogo;

  void launchSignupMethod(void Function(WebBundle)? onReady, void Function()? getReady, void Function()? exit);
}

abstract class EmailAuth implements AuthMethods {
  @override
  String get authName => 'Email';

  @override
  Widget get authLogo => Consumer(
    builder: (context, ref, _) {
      final theme = ref.watch(haloThemeProvider);
      return FaIcon(FontAwesomeIcons.envelope, size: 18, color: theme.whiteColor);
    },
  );
}

class GoogleAuth implements AuthMethods {
  final String loginUrl;
  final String domain;

  const GoogleAuth({required this.loginUrl, required this.domain});

  @override
  String get authName => 'Google';

  @override
  Widget get authLogo => Consumer(
    builder: (context, ref, _) {
      final theme = ref.watch(haloThemeProvider);
      return FaIcon(FontAwesomeIcons.google, size: 18, color: theme.whiteColor);
    },
  );

  // Opens the platform's login page. When the user clicks "Sign in with Google"
  // on that page, window.open() fires and onCreateWindow shows the OAuth popup.
  @override
  void launchSignupMethod(void Function(WebBundle)? onReady, void Function()? getReady, void Function()? exit) {
    print("Google Auth onboaridng started ${loginUrl}");
    createInAppWebView(loginUrl, onReady: onReady, getReady: getReady, exit: exit, domain: domain);
  }
}

// Webull Specific Auth Methods

class WebullEmailAuth extends EmailAuth {
  @override
  void launchSignupMethod(void Function(WebBundle)? onReady, void Function()? getReady, void Function()? exit) {
    const authUrl = "https://passport.webull.com/auth/simple/login?source=seo-direct-home&hl=en&redirect_uri=https://www.webull.com/center";
    createInAppWebView(authUrl, injectionScript: 'assets/scripts/webull_email_auth.js', onReady: onReady, getReady: getReady, exit: exit, domain: "webull");
  }
}

class WebullPhoneAuth implements AuthMethods {
  @override
  String get authName => 'Phone Number';

  @override
  Widget get authLogo => Consumer(
    builder: (context, ref, _) {
      final theme = ref.watch(haloThemeProvider);
      return FaIcon(FontAwesomeIcons.phone, size: 18, color: theme.whiteColor);
    },
  );

  @override
  void launchSignupMethod(void Function(WebBundle)? onReady, void Function()? getReady, void Function()? exit) {
    const authUrl = "https://passport.webull.com/auth/simple/login?source=seo-direct-home&hl=en&redirect_uri=https://www.webull.com/center";
    createInAppWebView(authUrl, onReady: onReady, getReady: getReady, exit: exit, domain: "webull");
  }
}

class WebullQRCodeAuth implements AuthMethods {
  @override
  String get authName => 'QR Code';

  @override
  Widget get authLogo => Consumer(
    builder: (context, ref, _) {
      final theme = ref.watch(haloThemeProvider);
      return FaIcon(FontAwesomeIcons.qrcode, size: 18, color: theme.whiteColor);
    },
  );

  @override
  void launchSignupMethod(void Function(WebBundle)? onReady, void Function()? getReady, void Function()? exit) {
    const authUrl = "https://passport.webull.com/auth/simple/login?source=seo-direct-home&hl=en&redirect_uri=https://www.webull.com/center";
    createInAppWebView(authUrl, injectionScript: 'assets/scripts/webull_qr_auth.js', onReady: onReady, getReady: getReady, exit: exit, domain: "webull");
  }
}

// Robinhood Specific Auth Methods
class RobinhoodEmailAuth extends EmailAuth {
  @override
  void launchSignupMethod(void Function(WebBundle)? onReady, void Function()? getReady, void Function()? exit) {
    createInAppWebView("https://robinhood.com/login/", onReady: onReady, getReady: getReady, exit: exit, domain: "robinhood");
  }
}

// TradingView Auth Methods
class TradingViewEmailAuth extends EmailAuth {
  @override
  void launchSignupMethod(void Function(WebBundle)? onReady, void Function()? getReady, void Function()? exit) {
    const link = "https://www.tradingview.com/pricing/?source=header_go_pro_button&feature=start_free_trial";
    createInAppWebView(link, injectionScript: 'assets/scripts/tradingview_email_auth.js', onReady: onReady, getReady: getReady, exit: exit, domain: "tradingview");
  }
}

// Finviz Auth Methods
class FinizEmailAuth extends EmailAuth {
  @override
  void launchSignupMethod(void Function(WebBundle)? onReady, void Function()? getReady, void Function()? exit) {
    const link = "https://finviz.com/login-email?remember=true";
    createInAppWebView(link, onReady: onReady, getReady: getReady, exit: exit, domain: "finviz");
  }
}

// Think or Swim Auth Methods
class ThinkOrSwimIDAuth implements AuthMethods {
  @override
  String get authName => 'Think or Swim ID';

  @override
  Widget get authLogo => Consumer(
    builder: (context, ref, _) {
      final theme = ref.watch(haloThemeProvider);
      return FaIcon(FontAwesomeIcons.idBadge, size: 18, color: theme.whiteColor);
    },
  );

  @override
  void launchSignupMethod(void Function(WebBundle)? onReady, void Function()? getReady, void Function()? exit) {
    const link = "https://trade.thinkorswim.com/";
    createInAppWebView(link, onReady: onReady, getReady: getReady, exit: exit, domain: "thinkorswim");
  }
}

class Platform {
  final String id;
  final String logoUrl;
  final Color brandColor;
  String link;
  bool authenticated = false;
  List<AuthMethods> authMethods;

  Platform(this.id, this.brandColor, {required this.link, required this.authMethods})
      : logoUrl = 'assets/images/icons/$id.png';
}

List<Platform> buyingPlatforms = [
  Platform(
    'Webull',
    Color(0xFF1942E0),
    link: "https://www.webull.com/",
    authMethods: [
      GoogleAuth(loginUrl: "https://passport.webull.com/auth/simple/login?source=seo-direct-home&hl=en&redirect_uri=https://www.webull.com/center", domain: "webull"),
      WebullPhoneAuth(),
      WebullEmailAuth(),
      WebullQRCodeAuth(),
    ],
  ),
  Platform(
    'Robinhood',
    Color(0xFF00C805),
    link: "https://robinhood.com/",
    authMethods: [
      RobinhoodEmailAuth(),
    ],
  ),
];

List<Platform> chartingPlatforms = [
  Platform(
    'TradingView',
    Colors.blue,
    link: "https://www.tradingview.com/",
    authMethods: [
      GoogleAuth(loginUrl: "https://www.tradingview.com/sign-in/", domain: "tradingview"),
      TradingViewEmailAuth(),
    ],
  ),
  Platform(
    'Finiz',
    Color(0xFF5FAAF4),
    link: "https://finviz.com/",
    authMethods: [
      FinizEmailAuth(),
    ],
  ),
  Platform(
    'Think or Swim',
    Color(0xFF00A651),
    link: "https://trade.thinkorswim.com/",
    authMethods: [
      ThinkOrSwimIDAuth(),
    ],
  ),
];
