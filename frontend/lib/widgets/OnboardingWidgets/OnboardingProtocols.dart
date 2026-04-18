import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

abstract class AuthMethods {
  String get authName;
  Widget get authLogo;

  void launchSignupMethod();
}

class GoogleAuth implements AuthMethods {
  @override
  String get authName => 'Google';

  @override
  Widget get authLogo => FaIcon(FontAwesomeIcons.google, size: 18, color: Colors.white);

  @override
  void launchSignupMethod() {
    // Implement Google authentication flow here
    print('Launching Google authentication...');
  }
}

class WebullPhoneAuth implements AuthMethods {
  @override
  String get authName => 'Phone Number';

  @override
  Widget get authLogo => FaIcon(FontAwesomeIcons.phone, size: 18, color: Colors.white);

  @override
  void launchSignupMethod() {
    // Implement Google authentication flow here
    print('Launching Google authentication...');
  }
}

class WebullEmailAuth implements AuthMethods {
  @override
  String get authName => 'Email';

  @override
  Widget get authLogo => FaIcon(FontAwesomeIcons.envelope, size: 18, color: Colors.white);

  @override
  void launchSignupMethod() {
    print('Launching email authentication...');
  }
}

class WebullQRCodeAuth implements AuthMethods {
  @override
  String get authName => 'QR Code';

  @override
  Widget get authLogo => FaIcon(FontAwesomeIcons.qrcode, size: 18, color: Colors.white);

  @override
  void launchSignupMethod() {
    // Implement Google authentication flow here
    print('Launching Google authentication...');
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
      GoogleAuth(),
    ],
  ),
];

List<Platform> chartingPlatforms = [
  Platform(
    'OpenTrader',
    Colors.blue,
    authMethods: [
      GoogleAuth(),
    ],
  ),
  Platform(
    'Finiz',
    Color(0xFF5FAAF4),
    authMethods: [
      GoogleAuth(),
    ],
  ),
  Platform(
    'Think or Swim',
    Color(0xFF00A651),
    authMethods: [
      GoogleAuth(),
    ],
  ),
];