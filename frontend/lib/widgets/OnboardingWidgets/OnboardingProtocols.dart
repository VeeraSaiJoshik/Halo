import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/controllers/WebViewController.dart';
import 'package:frontend/themes/theme_provider.dart';
import 'package:frontend/widgets/OnboardingWidgets/CefAuthView.dart';

abstract class AuthMethods {
  String get authName;
  Widget get authLogo;

  void launchSignupMethod(
    void Function(WebBundle)? onReady,
    void Function()? getReady,
    void Function()? exit,
  );
}

abstract class EmailAuth implements AuthMethods {
  @override
  String get authName => 'Email';

  @override
  Widget get authLogo => Consumer(
    builder: (context, ref, _) {
      final theme = ref.watch(haloThemeProvider);
      return FaIcon(
        FontAwesomeIcons.envelope,
        size: 18,
        color: theme.whiteColor,
      );
    },
  );
}

class GoogleAuth implements AuthMethods {
  final String loginUrl;
  final String id;
  final String cookieDomain;
  final IsSuccessUrl isSuccessUrl;

  const GoogleAuth({
    required this.loginUrl,
    required this.id,
    required this.cookieDomain,
    required this.isSuccessUrl,
  });

  @override
  String get authName => 'Google';

  @override
  Widget get authLogo => Consumer(
    builder: (context, ref, _) {
      final theme = ref.watch(haloThemeProvider);
      return FaIcon(FontAwesomeIcons.google, size: 18, color: theme.whiteColor);
    },
  );

  @override
  void launchSignupMethod(
    void Function(WebBundle)? onReady,
    void Function()? getReady,
    void Function()? exit,
  ) {
    final webBundle = WebBundle();

    webBundle.widget = CefAuthView(
      loginUrl: loginUrl,
      cookieDomain: cookieDomain,
      isSuccessUrl: isSuccessUrl,
      onLoaded: () => getReady?.call(),
      onSuccess: () => exit?.call(),
    );

    onReady?.call(webBundle);
  }
}

// Webull Specific Auth Methods

class WebullEmailAuth extends EmailAuth {
  @override
  void launchSignupMethod(
    void Function(WebBundle)? onReady,
    void Function()? getReady,
    void Function()? exit,
  ) {
    const authUrl =
        "https://passport.webull.com/auth/simple/login?source=seo-direct-home&hl=en&redirect_uri=https://www.webull.com/center";
    createInAppWebView(
      authUrl,
      injectionScript: 'assets/scripts/webull_email_auth.js',
      onReady: onReady,
      getReady: getReady,
      exit: exit,
      domain: "webull",
      isAuth: true,
    );
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
  void launchSignupMethod(
    void Function(WebBundle)? onReady,
    void Function()? getReady,
    void Function()? exit,
  ) {
    const authUrl =
        "https://passport.webull.com/auth/simple/login?source=seo-direct-home&hl=en&redirect_uri=https://www.webull.com/center";
    createInAppWebView(
      authUrl,
      onReady: onReady,
      getReady: getReady,
      exit: exit,
      domain: "webull",
      isAuth: true,
    );
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
  void launchSignupMethod(
    void Function(WebBundle)? onReady,
    void Function()? getReady,
    void Function()? exit,
  ) {
    const authUrl =
        "https://passport.webull.com/auth/simple/login?source=seo-direct-home&hl=en&redirect_uri=https://www.webull.com/center";
    createInAppWebView(
      authUrl,
      injectionScript: 'assets/scripts/webull_qr_auth.js',
      onReady: onReady,
      getReady: getReady,
      exit: exit,
      domain: "webull",
      isAuth: true,
    );
  }
}

// Robinhood Specific Auth Methods
class RobinhoodEmailAuth extends EmailAuth {
  @override
  void launchSignupMethod(
    void Function(WebBundle)? onReady,
    void Function()? getReady,
    void Function()? exit,
  ) {
    createInAppWebView(
      "https://robinhood.com/login/",
      onReady: onReady,
      getReady: getReady,
      exit: exit,
      domain: "robinhood",
      isAuth: true,
    );
  }
}

// TradingView Auth Methods
class TradingViewEmailAuth extends EmailAuth {
  @override
  void launchSignupMethod(
    void Function(WebBundle)? onReady,
    void Function()? getReady,
    void Function()? exit,
  ) {
    const link =
        "https://www.tradingview.com/pricing/?source=header_go_pro_button&feature=start_free_trial";
    createInAppWebView(
      link,
      injectionScript: 'assets/scripts/tradingview_email_auth.js',
      onReady: onReady,
      getReady: getReady,
      exit: exit,
      domain: "tradingview",
      isAuth: true,
    );
  }
}

// Finviz Auth Methods
class FinizEmailAuth extends EmailAuth {
  @override
  void launchSignupMethod(
    void Function(WebBundle)? onReady,
    void Function()? getReady,
    void Function()? exit,
  ) {
    const link = "https://finviz.com/login-email?remember=true";
    createInAppWebView(
      link,
      onReady: onReady,
      getReady: getReady,
      exit: exit,
      domain: "finviz",
      isAuth: true,
    );
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
      return FaIcon(
        FontAwesomeIcons.idBadge,
        size: 18,
        color: theme.whiteColor,
      );
    },
  );

  @override
  void launchSignupMethod(
    void Function(WebBundle)? onReady,
    void Function()? getReady,
    void Function()? exit,
  ) {
    const link = "https://trade.thinkorswim.com/";
    createInAppWebView(
      link,
      onReady: onReady,
      getReady: getReady,
      exit: exit,
      domain: "thinkorswim",
      isAuth: true,
    );
  }
}

enum AuthState {
  authenticated,
  notAuthenticated,
  failedAuthentication,
  checking,
}

class Platform {
  final String id;
  final String logoUrl;
  final Color brandColor;
  List<String> links;
  AuthState authenticated = AuthState.notAuthenticated;
  List<AuthMethods> authMethods;

  Platform(
    this.id,
    this.brandColor, {
    required this.links,
    required this.authMethods,
  }) : logoUrl = 'assets/images/icons/$id.png';
}

List<Platform> buyingPlatforms = [
  Platform(
    'Webull',
    Color(0xFF1942E0),
    links: [
      "https://www.webull.com/",
      "https://userapi.webull.com/",
      "https://app.webull.com/",
      "https://passport.webull.com/",
      "https://trade.webull.com/",
    ],
    authMethods: [
      GoogleAuth(
        loginUrl:
            "https://passport.webull.com/auth/simple/login?source=seo-direct-home&hl=en&redirect_uri=https://www.webull.com/center",
        id: "webull",
        cookieDomain: "webull.com",
        isSuccessUrl: _isWebullSuccessUrl,
      ),
      WebullPhoneAuth(),
      WebullEmailAuth(),
      WebullQRCodeAuth(),
    ],
  ),
  Platform(
    'Robinhood',
    Color(0xFF00C805),
    links: ["https://robinhood.com/"],
    authMethods: [RobinhoodEmailAuth()],
  ),
];

List<Platform> chartingPlatforms = [
  Platform(
    'TradingView',
    Colors.blue,
    links: ["https://www.tradingview.com/"],
    authMethods: [
      GoogleAuth(
        loginUrl: "https://www.tradingview.com/sign-in/",
        id: "tradingview",
        cookieDomain: "tradingview.com",
        isSuccessUrl: _isTradingViewSuccessUrl,
      ),
      TradingViewEmailAuth(),
    ],
  ),
  Platform(
    'Finiz',
    Color(0xFF5FAAF4),
    links: ["https://finviz.com/"],
    authMethods: [FinizEmailAuth()],
  ),
  Platform(
    'Think or Swim',
    Color(0xFF00A651),
    links: ["https://trade.thinkorswim.com/"],
    authMethods: [ThinkOrSwimIDAuth()],
  ),
];

bool _isWebullSuccessUrl(String url) {
  return url.contains('webull.com/center');
}

bool _isTradingViewSuccessUrl(String url) {
  if (url.contains('accounts.google.com')) return false;
  if (url.contains('/sign-in')) return false;
  if (url.contains('/accounts/signin')) return false;
  return url.contains('tradingview.com');
}
