import '../models/candle.dart';
import 'ticker_resolver.dart';

class CandleNormalizer {
  List<Candle> normalize(DataSource source, dynamic payload) {
    switch (source) {
      case DataSource.alpaca:
        return normalizeAlpaca(payload);
      case DataSource.binance:
        return normalizeBinance(payload);
      case DataSource.finnhub:
        return normalizeFinnhub(payload);
      default:
        return <Candle>[];
    }
  }

  List<Candle> normalizeAlpaca(dynamic payload) {
    final rawBars = payload is Map<String, dynamic>
        ? payload['bars']
        : payload;
    if (rawBars is! List) return <Candle>[];

    final candles = <Candle>[];
    for (final item in rawBars) {
      if (item is! Map<String, dynamic>) continue;
      final rawTime = item['t'];
      if (rawTime == null) continue;

      final dt = _parseTime(rawTime);
      if (dt == null) continue;

      final open = _toDouble(item['o']);
      final high = _toDouble(item['h']);
      final low = _toDouble(item['l']);
      final close = _toDouble(item['c']);
      final volume = _toDouble(item['v']);
      if (open == null ||
          high == null ||
          low == null ||
          close == null ||
          volume == null) {
        continue;
      }

      candles.add(
        Candle(
          timestamp: dt,
          open: open,
          high: high,
          low: low,
          close: close,
          volume: volume,
        ),
      );
    }

    candles.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return candles;
  }

  List<Candle> normalizeBinance(dynamic payload) {
    if (payload is! List) return <Candle>[];

    final candles = <Candle>[];
    for (final kline in payload) {
      if (kline is! List || kline.length < 6) continue;
      final t = kline[0];
      final open = _toDouble(kline[1]);
      final high = _toDouble(kline[2]);
      final low = _toDouble(kline[3]);
      final close = _toDouble(kline[4]);
      final volume = _toDouble(kline[5]);
      if (t is! num ||
          open == null ||
          high == null ||
          low == null ||
          close == null ||
          volume == null) {
        continue;
      }

      candles.add(
        Candle(
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            t.toInt(),
            isUtc: true,
          ),
          open: open,
          high: high,
          low: low,
          close: close,
          volume: volume,
        ),
      );
    }

    candles.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return candles;
  }

  List<Candle> normalizeFinnhub(dynamic payload) {
    if (payload is! Map<String, dynamic>) return <Candle>[];
    if (payload['s'] != 'ok') return <Candle>[];

    final t = payload['t'];
    final o = payload['o'];
    final h = payload['h'];
    final l = payload['l'];
    final c = payload['c'];
    final v = payload['v'];
    if (t is! List ||
        o is! List ||
        h is! List ||
        l is! List ||
        c is! List ||
        v is! List) {
      return <Candle>[];
    }

    final length = [
      t.length,
      o.length,
      h.length,
      l.length,
      c.length,
      v.length,
    ].reduce((a, b) => a < b ? a : b);

    final candles = <Candle>[];
    for (int i = 0; i < length; i++) {
      final ts = t[i];
      final open = _toDouble(o[i]);
      final high = _toDouble(h[i]);
      final low = _toDouble(l[i]);
      final close = _toDouble(c[i]);
      final volume = _toDouble(v[i]);
      if (ts is! num ||
          open == null ||
          high == null ||
          low == null ||
          close == null ||
          volume == null) {
        continue;
      }

      candles.add(
        Candle(
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            ts.toInt() * 1000,
            isUtc: true,
          ),
          open: open,
          high: high,
          low: low,
          close: close,
          volume: volume,
        ),
      );
    }

    candles.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return candles;
  }

  DateTime? _parseTime(dynamic raw) {
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is int) {
      final isMs = raw > 1000000000000;
      return DateTime.fromMillisecondsSinceEpoch(
        isMs ? raw : raw * 1000,
        isUtc: true,
      );
    }
    if (raw is num) {
      final i = raw.toInt();
      final isMs = i > 1000000000000;
      return DateTime.fromMillisecondsSinceEpoch(
        isMs ? i : i * 1000,
        isUtc: true,
      );
    }
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
