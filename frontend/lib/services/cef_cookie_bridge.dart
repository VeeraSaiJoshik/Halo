import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:webview_cef/webview_cef.dart';

const _kSyntheticExpiryDays = 30;

Future<int> migrateCefCookiesToInAppWebView(List<String> domainPatterns) async {
  final raw = await WebviewManager().visitAllCookies();
  if (raw is! Map) return 0;

  final expiresMs = DateTime.now()
      .add(const Duration(days: _kSyntheticExpiryDays))
      .millisecondsSinceEpoch;

  int migrated = 0;
  for (final entry in raw.entries) {
    final domain = entry.key as String;
    final matches = domainPatterns.any((p) => domain.contains(p));
    if (!matches) continue;

    final cookies = entry.value;
    if (cookies is! Map) continue;

    final cleanHost = domain.startsWith('.') ? domain.substring(1) : domain;
    final url = WebUri('https://$cleanHost/');

    for (final c in cookies.entries) {
      final name = c.key as String;
      final value = c.value as String;

      final ok = await CookieManager.instance().setCookie(
        url: url,
        name: name,
        value: value,
        domain: domain,
        path: '/',
        expiresDate: expiresMs,
        isSecure: true,
        isHttpOnly: true,
        sameSite: HTTPCookieSameSitePolicy.LAX,
      );
      if (ok) migrated++;
    }
  }

  print('[cef_cookie_bridge] migrated $migrated cookies for $domainPatterns');
  return migrated;
}
