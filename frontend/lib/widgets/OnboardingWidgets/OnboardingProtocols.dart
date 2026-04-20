import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

abstract class AuthMethods {
  String get authName;
  Widget get authLogo;

  void launchSignupMethod();
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
  void launchSignupMethod() {}
}

// Webull Specific Auth Methods

class WebullEmailAuth extends EmailAuth {
  @override
  void launchSignupMethod() {
  }
}

class WebullPhoneAuth implements AuthMethods {
  @override
  String get authName => 'Phone Number';

  @override
  Widget get authLogo => FaIcon(FontAwesomeIcons.phone, size: 18, color: Colors.white);

  @override
  void launchSignupMethod() {}
}

class WebullQRCodeAuth implements AuthMethods {
  @override
  String get authName => 'QR Code';

  @override
  Widget get authLogo => FaIcon(FontAwesomeIcons.qrcode, size: 18, color: Colors.white);

  @override
  void launchSignupMethod() {
  }
}

// Robinhood Specific Auth Methods
class RobinhoodEmailAuth extends EmailAuth {
  @override
  void launchSignupMethod() {}
}

// TradeView Auth Methods
class TradingViewEmailAuth extends EmailAuth {
  @override
  void launchSignupMethod() {}
}

//Finiz Auth Methods
class FinizEmailAuth extends EmailAuth {
  @override
  void launchSignupMethod() {}
}

//Think or Swim Auth Methods
class ThinkOrSwimIDAuth implements AuthMethods {
  @override
  String get authName => 'Think or Swim ID';

  @override
  Widget get authLogo => FaIcon(FontAwesomeIcons.idBadge, size: 18, color: Colors.white);

  @override
  void launchSignupMethod() {}
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