import 'package:flutter/services.dart';

class NativeCookieManager {
  static const _channel = MethodChannel('com.example.frontend/cookies');

  static Future<void> deleteCookiesForDomain(String domain) async {
    try {
      final count = await _channel.invokeMethod<int>(
        'deleteCookiesForDomain',
        {'domain': domain},
      );
      print("Deleted $count WKWebsiteDataStore records for $domain");
    } catch (e) {
      print("Native cookie deletion failed: $e");
    }
  }
}