import 'dart:ui';

import 'package:flutter/material.dart';

class Platform {
  final String id;
  final String logoUrl;
  final Color  brandColor;
  Platform(this.id, this.brandColor): logoUrl = 'assets/images/icons/${id}.png';
}

List<Platform> buyingPlatforms = [
  Platform(
    'Webull',
    Color(0xFF1942E0),
  ),
  Platform(
    'Robinhood',
    Color(0xFF00C805),
  ),
];

List<Platform> chartingPlatforms = [
  Platform(
    'OpenTrader',
    Colors.blue,
  ),
  Platform(
    'Finiz',
    Color(0xFF5FAAF4),
  ),
  Platform(
    'Think or Swim',
    Color(0xFF00A651),
  ),
];