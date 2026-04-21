import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/controllers/AppController.dart';
import 'package:webview_flutter/webview_flutter.dart';

abstract class AuthMethods {
  String get authName;
  Widget get authLogo;

  WebViewController? launchSignupMethod();
}

abstract class EmailAuth implements AuthMethods {
  @override
  String get authName => 'Email';

  @override
  Widget get authLogo => FaIcon(FontAwesomeIcons.envelope, size: 18, color: Colors.white);
}

class GoogleAuth implements AuthMethods {
  @override
  String get authName => 'Google';

  @override
  Widget get authLogo => FaIcon(FontAwesomeIcons.google, size: 18, color: Colors.white);

  @override
  WebViewController? launchSignupMethod() {}
}

// Webull Specific Auth Methods

class WebullEmailAuth extends EmailAuth {
  @override
  WebViewController launchSignupMethod() {
    const authUrl = "https://passport.webull.com/auth/simple/login?source=seo-direct-home&hl=en&redirect_uri=https://www.webull.com/center";
    const script = """
      (async () => {
        const span = [...document.querySelectorAll('span')].find(s => s.textContent.trim() === 'Email Login');
        if (span) span.click();
      })();
    """;
    return createWebViewController(authUrl, injectionScript: script);
  }
}

class WebullPhoneAuth implements AuthMethods {
  @override
  String get authName => 'Phone Number';

  @override
  Widget get authLogo => FaIcon(FontAwesomeIcons.phone, size: 18, color: Colors.white);

  @override
  WebViewController? launchSignupMethod() {
    const authUrl = "https://passport.webull.com/auth/simple/login?source=seo-direct-home&hl=en&redirect_uri=https://www.webull.com/center";
    return createWebViewController(authUrl);
  }
}

class WebullQRCodeAuth implements AuthMethods {
  @override
  String get authName => 'QR Code';

  @override
  Widget get authLogo => FaIcon(FontAwesomeIcons.qrcode, size: 18, color: Colors.white);

  @override
  WebViewController? launchSignupMethod() {
    const authUrl = "https://passport.webull.com/auth/simple/login?source=seo-direct-home&hl=en&redirect_uri=https://www.webull.com/center";
    const script = """
      (async () => {
        const span = document.querySelector('div.csr30 span');
        if (span) span.click();
      })();
    """;
    return createWebViewController(authUrl, injectionScript: script);
  }
}

// Robinhood Specific Auth Methods
class RobinhoodEmailAuth extends EmailAuth {
  @override
  WebViewController? launchSignupMethod() {
    return createWebViewController("https://robinhood.com/login/");
  }
}

// TradeView Auth Methods
class TradingViewEmailAuth extends EmailAuth {
  @override
  WebViewController? launchSignupMethod() {
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

        // Step 1: Open user menu
        const menuBtn = await waitFor(() =>
          document.querySelector('[aria-label="Open user menu"]')
          || [...document.querySelectorAll('button')].find(b => b.textContent.trim() === 'Open user menu')
        );
        if (!menuBtn) return ;
        clickEl(menuBtn);

        // Step 2: Target span
        const cls = 'label-jFqVJoPk.label-mDJVFqQ3.label-YQGjel_5';
        const span = await waitFor(() => document.querySelector(`span.\${cls}`));
        if (!span) return ;
        clickEl(span);

        // Step 3: Email button
        const emailBtn = await waitFor(() =>
          [...document.querySelectorAll('button, a, [role="button"], span')]
            .find(b => b.textContent.trim() === 'Email')
        );
        if (!emailBtn) return ;
        clickEl(emailBtn);
      })();
    """;

    return createWebViewController(link, injectionScript: script);
  }
}

//Finiz Auth Methods
class FinizEmailAuth extends EmailAuth {
  @override
  WebViewController? launchSignupMethod() {
    const link = "https://finviz.com/login-email?remember=true";

    return createWebViewController(link);
  }
}

//Think or Swim Auth Methods
class ThinkOrSwimIDAuth implements AuthMethods {
  @override
  String get authName => 'Think or Swim ID';

  @override
  Widget get authLogo => FaIcon(FontAwesomeIcons.idBadge, size: 18, color: Colors.white);

  @override
  WebViewController? launchSignupMethod() {
    const link = "https://trade.thinkorswim.com/";

    return createWebViewController(link);
  }
}

class Platform {
  final String id;
  final String logoUrl;
  final Color  brandColor;
  String link = "";
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