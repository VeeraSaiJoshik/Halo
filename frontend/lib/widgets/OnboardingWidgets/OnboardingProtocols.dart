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

  void launchSignupMethod(void Function(WebViewController)? onReady, void Function()? getReady, void Function()? exit);
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
  void launchSignupMethod(void Function(WebViewController)? onReady, void Function()? getRead, void Function()? exity) {}
}

// Webull Specific Auth Methods

class WebullEmailAuth extends EmailAuth {
  @override
  void launchSignupMethod(void Function(WebViewController)? onReady, void Function()? getReady, void Function()? exit) {
    const authUrl = "https://passport.webull.com/auth/simple/login?source=seo-direct-home&hl=en&redirect_uri=https://www.webull.com/center";
    const script = """
      (async () => {
        const waitFor = (findFn, timeout = 8000) => new Promise((resolve) => {
          const start = Date.now();
          const check = () => {
            const el = findFn();
            if (el) return resolve(el);
            if (Date.now() - start > timeout) return resolve(null);
            requestAnimationFrame(check);
          };
          check();
        });
        const span = await waitFor(() =>
          [...document.querySelectorAll('span')].find(s => s.textContent.trim() === 'Email Login')
        );
        if (span) span.click();
        HaloAuthReady.postMessage('ready');
      })();
    """;
    createWebViewController(authUrl, injectionScript: script, onReady: onReady, getReady: getReady, exit: exit, domain: "webull");
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
  void launchSignupMethod(void Function(WebViewController)? onReady, void Function()? getReady, void Function()? exit) {
    const authUrl = "https://passport.webull.com/auth/simple/login?source=seo-direct-home&hl=en&redirect_uri=https://www.webull.com/center";
    createWebViewController(authUrl, onReady: onReady, getReady: getReady, exit: exit, domain: "webull");
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
  void launchSignupMethod(void Function(WebViewController)? onReady, void Function()? getReady, void Function()? exit) {
    const authUrl = "https://passport.webull.com/auth/simple/login?source=seo-direct-home&hl=en&redirect_uri=https://www.webull.com/center";
    const script = """
      (async () => {
        const waitFor = (findFn, timeout = 8000) => new Promise((resolve) => {
          const start = Date.now();
          const check = () => {
            const el = findFn();
            if (el) return resolve(el);
            if (Date.now() - start > timeout) return resolve(null);
            requestAnimationFrame(check);
          };
          check();
        });
        const span = await waitFor(() => document.querySelector('div.csr30 span'));
        if (span) span.click();
        HaloAuthReady.postMessage('ready');
      })();
    """;
    createWebViewController(authUrl, injectionScript: script, onReady: onReady, getReady: getReady, exit: exit, domain: "webull");
  }
}

// Robinhood Specific Auth Methods
class RobinhoodEmailAuth extends EmailAuth {
  @override
  void launchSignupMethod(void Function(WebViewController)? onReady, void Function()? getReady, void Function()? exit) {
    createWebViewController("https://robinhood.com/login/", onReady: onReady, getReady: getReady, exit: exit, domain: "robinhood");
  }
}

// TradeView Auth Methods
class TradingViewEmailAuth extends EmailAuth {
  @override
  void launchSignupMethod(void Function(WebViewController)? onReady, void Function()? getReady, void Function()? exit) {
    const link = "https://www.tradingview.com/pricing/?source=header_go_pro_button&feature=start_free_trial";
    const script = """
      (async () => {
        const waitFor = (findFn, timeout = 5000) => new Promise((resolve) => {
          const start = Date.now();
          const check = () => {
            const el = findFn();
            if (el) return resolve(el);
            if (Date.now() - start > timeout) return resolve(null);
            requestAnimationFrame(check);
          };
          check();
        });

        const clickEl = (el) => {
          const target = el.closest('button, a, [role="button"], [onclick]') || el;
          target.click();
        };

        const menuBtn = await waitFor(() =>
          document.querySelector('[aria-label="Open user menu"]')
          || [...document.querySelectorAll('button')].find(b => b.textContent.trim() === 'Open user menu')
        );
        if (!menuBtn) { HaloAuthReady.postMessage('ready'); return; }
        clickEl(menuBtn);

        const cls = 'label-jFqVJoPk.label-mDJVFqQ3.label-YQGjel_5';
        const span = await waitFor(() => document.querySelector(`span.\${cls}`));
        if (!span) { HaloAuthReady.postMessage('ready'); return; }
        clickEl(span);

        const emailBtn = await waitFor(() =>
          [...document.querySelectorAll('button, a, [role="button"], span')]
            .find(b => b.textContent.trim() === 'Email')
        );
        if (!emailBtn) { HaloAuthReady.postMessage('ready'); return; }
        clickEl(emailBtn);

        HaloAuthReady.postMessage('ready');
      })();
    """;

    createWebViewController(link, injectionScript: script, onReady: onReady, getReady: getReady, exit: exit, domain: "tradingview");
  }
}

//Finiz Auth Methods
class FinizEmailAuth extends EmailAuth {
  @override
  void launchSignupMethod(void Function(WebViewController)? onReady, void Function()? getReady, void Function()? exit) {
    const link = "https://finviz.com/login-email?remember=true";
    createWebViewController(link, onReady: onReady, getReady: getReady, exit: exit, domain: "finviz");
  }
}

//Think or Swim Auth Methods
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
  void launchSignupMethod(void Function(WebViewController)? onReady, void Function()? getReady, void Function()? exit) {
    const link = "https://trade.thinkorswim.com/";
    createWebViewController(link, onReady: onReady, getReady: getReady, exit: exit, domain: "thinkorswim");
  }
}

class Platform {
  final String id;
  final String logoUrl;
  final Color  brandColor;
  String link = "";
  bool authenticated = false;
  List<AuthMethods> authMethods;

  Platform(this.id, this.brandColor, {required this.authMethods}): logoUrl = 'assets/images/icons/${id}.png';
}

List<Platform> buyingPlatforms = [
  Platform(
    'Webull',
    Color(0xFF1942E0),
    authMethods: [
      GoogleAuth(),
      WebullPhoneAuth(),
      WebullEmailAuth(),
      WebullQRCodeAuth(),
    ],
  ),
  Platform(
    'Robinhood',
    Color(0xFF00C805),
    authMethods: [
      RobinhoodEmailAuth()
    ],
  ),
];

List<Platform> chartingPlatforms = [
  Platform(
    'TradingView',
    Colors.blue,
    authMethods: [
      GoogleAuth(),
      TradingViewEmailAuth(),
    ],
  ),
  Platform(
    'Finiz',
    Color(0xFF5FAAF4),
    authMethods: [
      FinizEmailAuth(),
    ],
  ),
  Platform(
    'Think or Swim',
    Color(0xFF00A651),
    authMethods: [
      ThinkOrSwimIDAuth(),
    ],
  ),
];