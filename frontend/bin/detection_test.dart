/// Standalone detection test — pure Dart, no Flutter SDK needed.
/// Uses dart:io for HTTP so no pub dependencies required.
///
/// Run with:
///   dart bin/detection_test.dart
///   dart bin/detection_test.dart ETHUSDT 15m
///   dart bin/detection_test.dart SOLUSDT 1h
///
/// For Alpaca (US stocks):
///   ALPACA_API_KEY=xxx ALPACA_API_SECRET=yyy dart bin/detection_test.dart AAPL 5m alpaca

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

// ── DEV FLAG ──────────────────────────────────────────────────────────────────
// TODO: set this to false before shipping to beta / production.
// When false: report file is NOT written to disk (console output still works).
const bool kWriteReports = true;

// ── Asset profile ─────────────────────────────────────────────────────────────

class AssetProfile {
  final String name;
  final int staleCandles;
  final double minDispAtrMult;
  final double sweepRevMult;
  final double clusterTolMult;
  final double fvgMaxAtrMult;
  final double fvgMinAtrMult;
  final double largeDispAtrMult;
  final double veryLargeDispAtrMult;
  final double maxFillPct;
  const AssetProfile({
    required this.name,
    required this.staleCandles,
    required this.minDispAtrMult,
    required this.sweepRevMult,
    required this.clusterTolMult,
    required this.fvgMaxAtrMult,
    required this.fvgMinAtrMult,
    required this.largeDispAtrMult,
    required this.veryLargeDispAtrMult,
    required this.maxFillPct,
  });

  static const crypto = AssetProfile(
    name: 'crypto',
    staleCandles: 30,
    minDispAtrMult: 0.5,
    sweepRevMult: 0.2,
    clusterTolMult: 0.15,
    fvgMaxAtrMult: 1.5,
    fvgMinAtrMult: 0.1,
    largeDispAtrMult: 1.5,
    veryLargeDispAtrMult: 2.0,
    maxFillPct: 0.9,
  );

  static const usEquities = AssetProfile(
    name: 'us_equities',
    staleCandles: 20,
    minDispAtrMult: 0.35,
    sweepRevMult: 0.25,
    clusterTolMult: 0.12,
    fvgMaxAtrMult: 1.2,
    fvgMinAtrMult: 0.08,
    largeDispAtrMult: 1.2,
    veryLargeDispAtrMult: 1.8,
    maxFillPct: 0.9,
  );

  static const forex = AssetProfile(
    name: 'forex',
    staleCandles: 25,
    minDispAtrMult: 0.4,
    sweepRevMult: 0.3,
    clusterTolMult: 0.10,
    fvgMaxAtrMult: 1.3,
    fvgMinAtrMult: 0.08,
    largeDispAtrMult: 1.3,
    veryLargeDispAtrMult: 1.9,
    maxFillPct: 0.9,
  );

  static AssetProfile fromSource(String source) {
    switch (source) {
      case 'alpaca': return usEquities;
      case 'finnhub': return forex;
      default: return crypto; // binance, coinbase, unknown
    }
  }
}

// ── Inline Candle model (no package import needed) ────────────────────────────

class Candle {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  const Candle({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

// ── Inline CandleBuffer ───────────────────────────────────────────────────────

class CandleBuffer {
  final int maxSize;
  final List<Candle> _c = [];
  double _atr = 0.0;
  static const int _p = 14;

  CandleBuffer({this.maxSize = 200});

  void loadHistory(List<Candle> candles) {
    _c.clear();
    final t = candles.length > maxSize ? candles.sublist(candles.length - maxSize) : candles;
    _c.addAll(t);
    _recalcAtr();
  }

  List<Candle> get candles => List.unmodifiable(_c);
  int get length => _c.length;
  Candle? get last => _c.isEmpty ? null : _c.last;
  double get atr => _atr;

  void _recalcAtr() {
    if (_c.length < 2) { _atr = 0.0; return; }
    final trs = <double>[];
    for (int i = 1; i < _c.length; i++) trs.add(_tr(_c[i], _c[i - 1]));
    if (trs.length < _p) { _atr = trs.reduce((a, b) => a + b) / trs.length; return; }
    double a = trs.sublist(0, _p).reduce((x, y) => x + y) / _p;
    for (int i = _p; i < trs.length; i++) a = (a * (_p - 1) + trs[i]) / _p;
    _atr = a;
  }

  double _tr(Candle c, Candle p) {
    final hl = c.high - c.low;
    final hc = (c.high - p.close).abs();
    final lc = (c.low - p.close).abs();
    return [hl, hc, lc].reduce((a, b) => a > b ? a : b);
  }
}

// ── Inline SwingPoint detector ────────────────────────────────────────────────

enum SwingType { high, low }

class SwingPoint {
  final SwingType type;
  final double price;
  final DateTime timestamp;
  final int idx;
  const SwingPoint({required this.type, required this.price, required this.timestamp, required this.idx});
  bool get isHigh => type == SwingType.high;
  bool get isLow  => type == SwingType.low;
}

List<SwingPoint> findSwings(List<Candle> candles, {int lookback = 3}) {
  final result = <SwingPoint>[];
  final n = candles.length;
  for (int i = lookback; i < n - lookback; i++) {
    final pivot = candles[i].high;
    bool isHigh = true;
    for (int k = 1; k <= lookback; k++) {
      if (candles[i - k].high >= pivot || candles[i + k].high >= pivot) { isHigh = false; break; }
    }
    if (isHigh) result.add(SwingPoint(type: SwingType.high, price: pivot, timestamp: candles[i].timestamp, idx: i));

    final pivotL = candles[i].low;
    bool isLow = true;
    for (int k = 1; k <= lookback; k++) {
      if (candles[i - k].low <= pivotL || candles[i + k].low <= pivotL) { isLow = false; break; }
    }
    if (isLow) result.add(SwingPoint(type: SwingType.low, price: pivotL, timestamp: candles[i].timestamp, idx: i));
  }
  return result;
}

// ── Inline FVG detector ───────────────────────────────────────────────────────

enum FvgDir { bullish, bearish }
enum FvgStatus { active, partial, filled }

class Fvg {
  final FvgDir dir;
  final double upper, lower;
  final DateTime timestamp;
  final double dispSize;
  FvgStatus status;
  double fillPct;

  Fvg({required this.dir, required this.upper, required this.lower,
       required this.timestamp, required this.dispSize,
       this.status = FvgStatus.active, this.fillPct = 0.0});

  double get gap => upper - lower;
  double get mid => (upper + lower) / 2;
}

List<Fvg> findFvgs(CandleBuffer buf, {AssetProfile? profile, double minAtrMult = 0.1, double maxAtrMult = 1.5, double minDispAtrMult = 0.5}) {
  minAtrMult    = profile?.fvgMinAtrMult    ?? minAtrMult;
  maxAtrMult    = profile?.fvgMaxAtrMult    ?? maxAtrMult;
  minDispAtrMult = profile?.minDispAtrMult  ?? minDispAtrMult;
  final candles = buf.candles;
  final atr = buf.atr;
  final result = <Fvg>[];
  if (candles.length < 3) return result;

  for (int i = 1; i < candles.length - 1; i++) {
    final c0 = candles[i - 1], c1 = candles[i], c2 = candles[i + 1];
    final minGap = atr * minAtrMult;
    final maxGap = atr * maxAtrMult; // reject gaps wider than 150% ATR — those are full candle ranges, not clean imbalances
    final minDisp = atr * minDispAtrMult; // reject FVGs where the displacement candle is too small to be meaningful

    final dispSize = (c1.close - c1.open).abs();
    if (dispSize < minDisp) continue; // noise candle — skip regardless of gap

    final bullGap = c2.low - c0.high;
    if (bullGap > minGap && bullGap <= maxGap && c1.close > c1.open) {
      result.add(Fvg(dir: FvgDir.bullish, lower: c0.high, upper: c2.low,
                     timestamp: c1.timestamp, dispSize: dispSize));
    }
    final bearGap = c0.low - c2.high;
    if (bearGap > minGap && bearGap <= maxGap && c1.close < c1.open) {
      result.add(Fvg(dir: FvgDir.bearish, lower: c2.high, upper: c0.low,
                     timestamp: c1.timestamp, dispSize: dispSize));
    }
  }

  // Update fill status against last candle
  final last = candles.last;
  for (final fvg in result) {
    if (fvg.dir == FvgDir.bullish) {
      if (last.low <= fvg.lower) { fvg.status = FvgStatus.filled; fvg.fillPct = 1.0; }
      else if (last.low < fvg.upper) { fvg.fillPct = (fvg.upper - last.low) / fvg.gap; fvg.status = FvgStatus.partial; }
    } else {
      if (last.high >= fvg.upper) { fvg.status = FvgStatus.filled; fvg.fillPct = 1.0; }
      else if (last.high > fvg.lower) { fvg.fillPct = (last.high - fvg.lower) / fvg.gap; fvg.status = FvgStatus.partial; }
    }
  }

  // Auto-invalidate near-fully-filled FVGs (imbalance is consumed — drop them)
  final maxFill = profile?.maxFillPct ?? 0.9;
  final unfilled = result.where((f) => f.status != FvgStatus.filled && f.fillPct < maxFill).toList();

  // FIX: deduplicate overlapping FVG zones within 1x ATR — collapse into the strongest (largest gap) representative
  return _deduplicateFvgs(unfilled, atr);
}

/// Merge FVGs of the same direction whose zones overlap or are within 1x ATR of each other.
/// Keeps the one with the largest gap as the representative.
List<Fvg> _deduplicateFvgs(List<Fvg> fvgs, double atr) {
  if (fvgs.length < 2) return fvgs;

  final result = <Fvg>[];

  for (final dir in [FvgDir.bullish, FvgDir.bearish]) {
    final sideFvgs = fvgs.where((f) => f.dir == dir).toList()
      ..sort((a, b) => a.lower.compareTo(b.lower));

    final used = List.filled(sideFvgs.length, false);

    for (int i = 0; i < sideFvgs.length; i++) {
      if (used[i]) continue;
      final group = [sideFvgs[i]];
      for (int j = i + 1; j < sideFvgs.length; j++) {
        if (used[j]) continue;
        // Zones overlap or are within 1x ATR of each other
        final gap = sideFvgs[j].lower - sideFvgs[i].upper;
        final overlap = sideFvgs[i].upper > sideFvgs[j].lower;
        if (overlap || gap < atr) {
          group.add(sideFvgs[j]);
          used[j] = true;
        }
      }
      used[i] = true;
      // Keep the largest gap as the representative for this zone cluster
      result.add(group.reduce((a, b) => a.gap >= b.gap ? a : b));
    }
  }

  return result;
}

// ── Inline Liquidity Cluster + Sweep ─────────────────────────────────────────

enum SweepDir { bullish, bearish }

class LiqCluster {
  final SweepDir side;
  final double price;
  final int count;
  const LiqCluster({required this.side, required this.price, required this.count});
}

class Sweep {
  final SweepDir dir;
  final LiqCluster cluster;
  final double extreme, close;
  final DateTime timestamp;
  final int candleIndex;
  final int repeatCount; // how many candles swept this same cluster
  double get depth => (extreme - cluster.price).abs();
  const Sweep({required this.dir, required this.cluster, required this.extreme,
               required this.close, required this.timestamp, required this.candleIndex,
               this.repeatCount = 1});
}

List<LiqCluster> findClusters(CandleBuffer buf, {int lookback = 3, double tolMult = 0.15, int minPts = 2}) {
  final swings = findSwings(buf.candles, lookback: lookback);
  final atr = buf.atr;
  if (atr == 0.0 || swings.isEmpty) return [];
  final tol = atr * tolMult;

  List<LiqCluster> side(List<SwingPoint> pts, SweepDir dir) {
    final sorted = List<SwingPoint>.from(pts)..sort((a, b) => a.price.compareTo(b.price));
    final out = <LiqCluster>[];
    int i = 0;
    while (i < sorted.length) {
      final grp = [sorted[i]];
      int j = i + 1;
      while (j < sorted.length && (sorted[j].price - sorted[i].price).abs() <= tol) grp.add(sorted[j++]);
      if (grp.length >= minPts) {
        final avg = grp.map((p) => p.price).reduce((a, b) => a + b) / grp.length;
        out.add(LiqCluster(side: dir, price: avg, count: grp.length));
      }
      i = j;
    }
    return out;
  }

  return [
    ...side(swings.where((s) => s.isHigh).toList(), SweepDir.bearish),
    ...side(swings.where((s) => s.isLow).toList(),  SweepDir.bullish),
  ];
}

/// FIX: one sweep event per cluster (not one per candle).
/// Keeps the most recent sweep as representative; tracks repeat count.
List<Sweep> findSweeps(CandleBuffer buf, {double revMult = 0.2, double tolMult = 0.15}) {
  final clusters = findClusters(buf, tolMult: tolMult);
  final atr = buf.atr;
  final minRev = atr * revMult;
  final candles = buf.candles;

  // Map: cluster price key → best (most recent) sweep for that cluster
  final Map<String, Sweep> bestPerCluster = {};

  for (int ci = 0; ci < candles.length; ci++) {
    final c = candles[ci];
    for (final cl in clusters) {
      final key = '${cl.side.name}:${cl.price.toStringAsFixed(2)}';
      if (cl.side == SweepDir.bullish && c.low < cl.price && c.close > cl.price && (c.close - c.low) >= minRev) {
        final existing = bestPerCluster[key];
        bestPerCluster[key] = Sweep(
          dir: SweepDir.bullish, cluster: cl, extreme: c.low, close: c.close,
          timestamp: c.timestamp, candleIndex: ci,
          repeatCount: (existing?.repeatCount ?? 0) + 1,
        );
      }
      if (cl.side == SweepDir.bearish && c.high > cl.price && c.close < cl.price && (c.high - c.close) >= minRev) {
        final existing = bestPerCluster[key];
        bestPerCluster[key] = Sweep(
          dir: SweepDir.bearish, cluster: cl, extreme: c.high, close: c.close,
          timestamp: c.timestamp, candleIndex: ci,
          repeatCount: (existing?.repeatCount ?? 0) + 1,
        );
      }
    }
  }

  // Invalidation: if any candle after the sweep closes back beyond the cluster
  // (below for bullish sweep, above for bearish), the reversal failed — drop it.
  final valid = bestPerCluster.values.where((sweep) {
    for (int ci = sweep.candleIndex + 1; ci < candles.length; ci++) {
      final c = candles[ci];
      if (sweep.dir == SweepDir.bullish && c.close < sweep.cluster.price) return false;
      if (sweep.dir == SweepDir.bearish && c.close > sweep.cluster.price) return false;
    }
    return true;
  }).toList();

  return valid..sort((a, b) => a.timestamp.compareTo(b.timestamp));
}

// ── Inline BOS detector ───────────────────────────────────────────────────────

enum BosDir { bullish, bearish }

class Bos {
  final BosDir dir;
  final double level;
  final DateTime timestamp;  // when it was FIRST broken
  final double dist;
  final int candleIndex;     // buffer index of the breaking candle
  final int repeatCount;     // how many subsequent candles also broke this level
  const Bos({required this.dir, required this.level, required this.timestamp,
             required this.dist, required this.candleIndex, this.repeatCount = 1});
}

/// FIX: one BOS per broken swing level (not one per candle).
/// Tracks how many candles re-broke the same level as repeatCount metadata.
/// Also applies recency decay — events older than [staleCandleAge] candles
/// are still returned but flagged via candleIndex so the scorer can down-weight them.
List<Bos> findBos(CandleBuffer buf, {int lookback = 3, double minMult = 0.05}) {
  final candles = buf.candles;
  final atr = buf.atr;
  if (candles.length < 5 || atr == 0.0) return [];
  final swings = findSwings(candles, lookback: lookback);
  final minBreak = atr * minMult;

  final highs = swings.where((s) => s.isHigh).toList();
  final lows  = swings.where((s) => s.isLow).toList();

  // Map: level price (rounded to 2dp) → first Bos event + repeat count
  final Map<String, Bos> seenHighBreaks = {};
  final Map<String, Bos> seenLowBreaks  = {};

  for (int i = 1; i < candles.length; i++) {
    final c = candles[i];
    final ph = highs.where((s) => s.idx < i).toList();
    final pl = lows.where((s)  => s.idx < i).toList();

    if (ph.isNotEmpty) {
      final d = c.close - ph.last.price;
      if (d > minBreak) {
        final key = ph.last.price.toStringAsFixed(2);
        if (seenHighBreaks.containsKey(key)) {
          // Already recorded — just increment repeat count
          final existing = seenHighBreaks[key]!;
          seenHighBreaks[key] = Bos(
            dir: existing.dir, level: existing.level, timestamp: existing.timestamp,
            dist: existing.dist, candleIndex: existing.candleIndex,
            repeatCount: existing.repeatCount + 1,
          );
        } else {
          seenHighBreaks[key] = Bos(dir: BosDir.bullish, level: ph.last.price,
              timestamp: c.timestamp, dist: d, candleIndex: i);
        }
      }
    }

    if (pl.isNotEmpty) {
      final d = pl.last.price - c.close;
      if (d > minBreak) {
        final key = pl.last.price.toStringAsFixed(2);
        if (seenLowBreaks.containsKey(key)) {
          final existing = seenLowBreaks[key]!;
          seenLowBreaks[key] = Bos(
            dir: existing.dir, level: existing.level, timestamp: existing.timestamp,
            dist: existing.dist, candleIndex: existing.candleIndex,
            repeatCount: existing.repeatCount + 1,
          );
        } else {
          seenLowBreaks[key] = Bos(dir: BosDir.bearish, level: pl.last.price,
              timestamp: c.timestamp, dist: d, candleIndex: i);
        }
      }
    }
  }

  return [...seenHighBreaks.values, ...seenLowBreaks.values]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
}

// ── HTTP helpers (dart:io, no packages) ──────────────────────────────────────

Future<List<Candle>> fetchBinance(String symbol, String interval) async {
  final base = Platform.environment['BINANCE_BASE_URL'] ?? 'https://api.binance.us';
  final url = Uri.parse(
    '$base/api/v3/klines?symbol=$symbol&interval=$interval&limit=200',
  );
  final client = HttpClient();
  final req = await client.getUrl(url);
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  client.close();

  if (res.statusCode != 200) throw Exception('Binance ${res.statusCode}: $body');

  final data = jsonDecode(body) as List;
  return data.map((k) {
    final row = k as List;
    return Candle(
      timestamp: DateTime.fromMillisecondsSinceEpoch(row[0] as int, isUtc: true),
      open:   double.parse(row[1] as String),
      high:   double.parse(row[2] as String),
      low:    double.parse(row[3] as String),
      close:  double.parse(row[4] as String),
      volume: double.parse(row[5] as String),
    );
  }).toList();
}

Future<List<Candle>> fetchAlpaca(String symbol, String timeframe) async {
  final key    = Platform.environment['ALPACA_API_KEY']    ?? '';
  final secret = Platform.environment['ALPACA_API_SECRET'] ?? '';
  if (key.isEmpty || secret.isEmpty) throw Exception('Set ALPACA_API_KEY and ALPACA_API_SECRET');

  final tf = _alpacaTf(timeframe);
  final url = Uri.parse(
    'https://data.alpaca.markets/v2/stocks/$symbol/bars?timeframe=$tf&limit=200&adjustment=split&feed=iex&sort=asc',
  );
  final client = HttpClient();
  final req = await client.getUrl(url);
  req.headers.set('APCA-API-KEY-ID', key);
  req.headers.set('APCA-API-SECRET-KEY', secret);
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  client.close();

  if (res.statusCode != 200) throw Exception('Alpaca ${res.statusCode}: $body');

  final data = jsonDecode(body) as Map<String, dynamic>;
  final bars = data['bars'] as List? ?? [];
  return bars.map((b) {
    final bar = b as Map<String, dynamic>;
    return Candle(
      timestamp: DateTime.parse(bar['t'] as String),
      open:   (bar['o'] as num).toDouble(),
      high:   (bar['h'] as num).toDouble(),
      low:    (bar['l'] as num).toDouble(),
      close:  (bar['c'] as num).toDouble(),
      volume: (bar['v'] as num).toDouble(),
    );
  }).toList();
}

String _alpacaTf(String tf) {
  final m = RegExp(r'^(\d+)([mhd])$').firstMatch(tf);
  if (m == null) return '5Min';
  final n = m.group(1)!, u = m.group(2)!;
  return u == 'm' ? '${n}Min' : u == 'h' ? '${n}Hour' : '${n}Day';
}

// ── Main ──────────────────────────────────────────────────────────────────────

Future<void> main(List<String> args) async {
  final symbol    = args.isNotEmpty ? args[0].toUpperCase() : 'BTCUSDT';
  final timeframe = args.length > 1 ? args[1] : '5m';
  final source    = args.length > 2 ? args[2].toLowerCase() : 'binance';

  print('═══════════════════════════════════════════════════');
  print('  Halo Detection Test');
  print('  Symbol: $symbol  Timeframe: $timeframe  Source: $source');
  print('═══════════════════════════════════════════════════\n');

  List<Candle> candles;
  try {
    print('Fetching 200 candles...');
    candles = source == 'alpaca'
        ? await fetchAlpaca(symbol, timeframe)
        : await fetchBinance(symbol, timeframe);
  } catch (e) {
    print('❌ Fetch failed: $e');
    exit(1);
  }

  if (candles.isEmpty) { print('❌ No candles returned.'); exit(1); }

  print('✓ ${candles.length} candles fetched');

  final profile = AssetProfile.fromSource(source);

  final buf = CandleBuffer();
  buf.loadHistory(candles);

  final swings   = findSwings(buf.candles);
  final fvgs     = findFvgs(buf, profile: profile);
  final clusters = findClusters(buf, tolMult: profile.clusterTolMult);
  final sweeps   = findSweeps(buf, revMult: profile.sweepRevMult, tolMult: profile.clusterTolMult);
  final bosList  = findBos(buf);
  final price    = candles.last.close;
  final atr      = buf.atr;

  // Build scored setups
  // Recency: signals older than profile.staleCandles are stale (half score).
  // Directional alignment: opposing signals flag setup as mixed-direction.
  final int staleCandles = profile.staleCandles;
  final totalCandles = buf.length;

  final allSetups = <_Setup>[];
  for (final f in fvgs) {
    final nearFvg     = (price - f.mid).abs() < atr * 1.5;
    final matchSweeps = sweeps.where((s) => (s.cluster.price - f.mid).abs() < atr).toList();
    final matchBos    = bosList.where((b) => (b.level - f.mid).abs() < atr).toList();

    // Directional agreement: bullish FVG expects bullish sweeps/BOS, bearish FVG expects bearish
    final fvgIsBull = f.dir == FvgDir.bullish;
    final alignedSweeps   = matchSweeps.where((s) => fvgIsBull ? s.dir == SweepDir.bullish  : s.dir == SweepDir.bearish).toList();
    final opposingSweeps  = matchSweeps.where((s) => fvgIsBull ? s.dir == SweepDir.bearish  : s.dir == SweepDir.bullish).toList();
    final alignedBos      = matchBos.where((b) => fvgIsBull ? b.dir == BosDir.bullish  : b.dir == BosDir.bearish).toList();
    final opposingBos     = matchBos.where((b) => fvgIsBull ? b.dir == BosDir.bearish  : b.dir == BosDir.bullish).toList();
    final hasMixed        = opposingSweeps.isNotEmpty || opposingBos.isNotEmpty;

    double score = 1.5; // base: FVG

    // Displacement magnitude bonus: large displacement candles signal stronger imbalance
    if (atr > 0 && f.dispSize > atr * profile.veryLargeDispAtrMult) score += 1.0;      // god candle
    else if (atr > 0 && f.dispSize > atr * profile.largeDispAtrMult) score += 0.5;     // large displacement

    // Aligned sweeps: full weight if fresh, half if stale
    if (alignedSweeps.isNotEmpty) {
      final fresh = alignedSweeps.any((s) => (totalCandles - 1 - s.candleIndex) <= staleCandles);
      score += fresh ? 2.0 : 1.0;
    }
    // Opposing sweeps: quarter weight regardless (they add mild uncertainty, not confirmation)
    if (opposingSweeps.isNotEmpty) score += 0.25;

    // Aligned BOS: full weight if fresh, half if stale
    if (alignedBos.isNotEmpty) {
      final fresh = alignedBos.any((b) => (totalCandles - 1 - b.candleIndex) <= staleCandles);
      score += fresh ? 1.5 : 0.5;
    }
    // Opposing BOS: quarter weight
    if (opposingBos.isNotEmpty) score += 0.25;

    allSetups.add(_Setup(fvg: f, score: score, approaching: nearFvg,
                         matchSweeps: matchSweeps, matchBos: matchBos,
                         hasMixedDirection: hasMixed));
  }
  allSetups.sort((a, b) => b.score.compareTo(a.score));

  final aiSetups = allSetups.where((s) => s.score >= 3.5 && s.approaching).toList();

  // Terminal output (brief)
  print('  Price: \$${price.toStringAsFixed(2)}  ATR(14): \$${atr.toStringAsFixed(4)}');
  print('  Swing points: ${swings.length}  FVGs: ${fvgs.length}  Sweeps: ${sweeps.length}  BOS: ${bosList.length}');
  print('  Setups ≥ score 2.0: ${allSetups.where((s) => s.score >= 2.0).length}');
  print('  Would trigger AI (≥3.5 + approaching): ${aiSetups.length}\n');

  // Write markdown report (dev only — see kWriteReports flag at top of file)
  if (kWriteReports) {
    final ts  = DateTime.now().toUtc();
    final slug = '${symbol}_${timeframe}_${ts.toIso8601String().substring(0, 16).replaceAll(':', '-')}';
    final outPath = 'reports/${slug}.md';
    await Directory('reports').create(recursive: true);

    final md = _buildReport(
      symbol: symbol, timeframe: timeframe, source: source,
      profile: profile,
      generatedAt: ts, candles: candles, buf: buf,
      swings: swings, fvgs: fvgs, clusters: clusters,
      sweeps: sweeps, bosList: bosList,
      allSetups: allSetups, aiSetups: aiSetups,
      totalCandles: totalCandles, staleCandles: staleCandles,
    );

    await File(outPath).writeAsString(md);
    print('✓ Report written → $outPath');
  }
  print('\nDone.');
}

// ── Setup container ───────────────────────────────────────────────────────────

class _Setup {
  final Fvg fvg;
  final double score;
  final bool approaching;
  final List<Sweep> matchSweeps;
  final List<Bos> matchBos;
  /// True if any contributing signal points in the opposite direction to the FVG.
  /// e.g. a bullish sweep near a bearish FVG. Score is penalised; LLM is warned.
  final bool hasMixedDirection;
  const _Setup({
    required this.fvg, required this.score, required this.approaching,
    required this.matchSweeps, required this.matchBos,
    required this.hasMixedDirection,
  });
}

// ── Report builder ────────────────────────────────────────────────────────────

String _buildReport({
  required String symbol,
  required String timeframe,
  required String source,
  required AssetProfile profile,
  required DateTime generatedAt,
  required List<Candle> candles,
  required CandleBuffer buf,
  required List<SwingPoint> swings,
  required List<Fvg> fvgs,
  required List<LiqCluster> clusters,
  required List<Sweep> sweeps,
  required List<Bos> bosList,
  required List<_Setup> allSetups,
  required List<_Setup> aiSetups,
  required int totalCandles,
  required int staleCandles,
}) {
  final sb = StringBuffer();
  final price = candles.last.close;
  final atr   = buf.atr;
  final highs = swings.where((s) => s.isHigh).toList();
  final lows  = swings.where((s) => s.isLow).toList();

  // ── Context header ──────────────────────────────────────────────────────────
  sb.writeln('# Halo Detection Report — $symbol $timeframe');
  sb.writeln();
  sb.writeln('**Generated:** ${generatedAt.toUtc().toIso8601String()}  ');
  sb.writeln('**Symbol:** $symbol  ');
  sb.writeln('**Timeframe:** $timeframe  ');
  sb.writeln('**Data source:** $source  ');
  sb.writeln('**Asset profile:** ${profile.name}  ');
  sb.writeln('**Current price:** \$${price.toStringAsFixed(4)}  ');
  sb.writeln('**ATR(14):** \$${atr.toStringAsFixed(4)}  ');
  sb.writeln();
  sb.writeln('---');
  sb.writeln();

  // ── What is this ────────────────────────────────────────────────────────────
  sb.writeln('## What Is This');
  sb.writeln();
  sb.writeln('''
**Halo** is a custom trading browser (Flutter desktop app) that watches which chart a trader has open, fetches live OHLCV candle data from market APIs, and runs an algorithmic detection engine to find high-probability trade setups in real time.

This report is a snapshot of what the detection engine found when scanning the last ${candles.length} candles of **$symbol** on the **$timeframe** timeframe. It contains:

1. **Raw market structure data** — every swing point, fair value gap, liquidity cluster, sweep, and break of structure the engine identified
2. **Scored setups** — groups of signals that coincide in the same price zone, ranked by confluence score
3. **AI-trigger candidates** — the setups that scored ≥ 3.5 AND have price currently approaching the zone. These are the ones that would be sent to an LLM for deeper analysis in production.

**Your job as the LLM reviewing this:** You are evaluating the quality and reliability of the detection engine's output — not making a trade recommendation. For each AI-trigger candidate at the bottom, give your honest assessment of:

- **Signal quality** — does the structure the engine found actually look meaningful on the raw candle data, or does it look like noise / too many FVGs cluttering the zone?
- **Confluence strength** — do the signals (FVG + sweep + BOS) tell a coherent story together, or do they just happen to be near each other by coincidence?
- **Zone validity** — is the FVG zone a clean, well-defined imbalance, or is it buried inside a messy consolidation range?
- **Recency** — how fresh are the signals? A sweep that happened 3 hours ago on a 5m chart is much less relevant than one that just formed.
- **Engine accuracy** — based on the raw candles, do you agree the engine correctly identified these patterns? Call out anything that looks like a misfire.
- **Overall verdict** — is this setup worth escalating to a detailed AI analysis, or should the engine's threshold be raised to filter it out?

Be direct and critical. The goal is to calibrate the engine, not to find reasons to like the setup.
''');
  sb.writeln('---');
  sb.writeln();

  // ── Asset profile context ───────────────────────────────────────────────────
  sb.writeln('## Asset Profile: `${profile.name}`');
  sb.writeln();
  sb.writeln('''
The engine uses **asset-specific tuning profiles** because crypto, US equities, and forex have structurally different price behaviour. The same raw threshold (e.g. what counts as a "large" displacement candle, or how quickly a signal goes stale) would misfire badly if applied uniformly across asset classes.

This report was generated using the **`${profile.name}`** profile. Key behavioural differences vs. other profiles:
''');

  // Print a comparison table of all three profiles so the LLM has full context
  sb.writeln('| Parameter | crypto | us_equities | forex | **This report** |');
  sb.writeln('|-----------|--------|-------------|-------|-----------------|');
  sb.writeln('| Staleness cutoff (candles) | 30 | 20 | 25 | **${profile.staleCandles}** |');
  sb.writeln('| Min displacement (× ATR) | 0.50 | 0.35 | 0.40 | **${profile.minDispAtrMult}** |');
  sb.writeln('| Sweep reversal min (× ATR) | 0.20 | 0.25 | 0.30 | **${profile.sweepRevMult}** |');
  sb.writeln('| Cluster tolerance (× ATR) | 0.15 | 0.12 | 0.10 | **${profile.clusterTolMult}** |');
  sb.writeln('| FVG max width (× ATR) | 1.50 | 1.20 | 1.30 | **${profile.fvgMaxAtrMult}** |');
  sb.writeln('| Large displacement (× ATR) | 1.50 | 1.20 | 1.30 | **${profile.largeDispAtrMult}** |');
  sb.writeln('| "God candle" threshold (× ATR) | 2.00 | 1.80 | 1.90 | **${profile.veryLargeDispAtrMult}** |');
  sb.writeln('| FVG invalidated above fill % | 90% | 90% | 90% | **${(profile.maxFillPct * 100).toStringAsFixed(0)}%** |');
  sb.writeln();
  sb.writeln('''**Why this matters for your evaluation:**
- A signal being "stale" in this report means it is older than **${profile.staleCandles} candles** on a $timeframe chart — that is approximately ${_stalePretty(profile.staleCandles, timeframe)}. Stale signals score at half weight.
- A "large displacement" FVG here means the displacement candle body exceeded **${profile.largeDispAtrMult}× ATR** at time of formation. A "god candle" exceeded **${profile.veryLargeDispAtrMult}× ATR**.
- Sweep wicks must reverse at least **${profile.sweepRevMult}× ATR** from the extreme to be counted. Anything less is treated as a continuation, not a reversal.
- FVGs are dropped from scoring once they are **>${(profile.maxFillPct * 100).toStringAsFixed(0)}% filled** — the imbalance is considered consumed.
- If you are comparing this report to one from a different asset class, the scores are not directly comparable — the coefficients are different by design.
''');
  sb.writeln('---');
  sb.writeln();

  // ── Scoring legend ──────────────────────────────────────────────────────────
  sb.writeln('## Scoring System (Quick Reference)');
  sb.writeln();
  sb.writeln('| Signal | Score Contribution |');
  sb.writeln('|--------|--------------------|');
  sb.writeln('| Fair Value Gap (FVG) base | 1.5 |');
  sb.writeln('| + Displacement candle ≥ ${profile.largeDispAtrMult}× ATR | +0.5 |');
  sb.writeln('| + Displacement candle ≥ ${profile.veryLargeDispAtrMult}× ATR ("god candle") | +1.0 |');
  sb.writeln('| + Aligned Liquidity Sweep (fresh ≤${profile.staleCandles} candles) | +2.0 |');
  sb.writeln('| + Aligned Liquidity Sweep (stale) | +1.0 |');
  sb.writeln('| + Opposing Sweep (mixed signal flag) | +0.25 |');
  sb.writeln('| + Aligned Break of Structure (fresh) | +1.5 |');
  sb.writeln('| + Aligned Break of Structure (stale) | +0.5 |');
  sb.writeln('| + Opposing BOS (mixed signal flag) | +0.25 |');
  sb.writeln();
  sb.writeln('Signals within 1× ATR of the same price level combine. Minimum score to appear: **2.0**. AI trigger threshold: **3.5** with price approaching the zone.');
  sb.writeln();
  sb.writeln('---');
  sb.writeln();

  // ── Raw candle data ─────────────────────────────────────────────────────────
  sb.writeln('## Raw Candle Data (Last ${candles.length} Candles)');
  sb.writeln();
  sb.writeln('| # | Timestamp (UTC) | Open | High | Low | Close | Volume |');
  sb.writeln('|---|----------------|------|------|-----|-------|--------|');
  for (int i = 0; i < candles.length; i++) {
    final c = candles[i];
    sb.writeln('| ${i + 1} | ${_fmt(c.timestamp)} | ${c.open} | ${c.high} | ${c.low} | ${c.close} | ${c.volume.toStringAsFixed(2)} |');
  }
  sb.writeln();
  sb.writeln('---');
  sb.writeln();

  // ── Swing points ────────────────────────────────────────────────────────────
  sb.writeln('## Swing Points (${swings.length} total)');
  sb.writeln();
  sb.writeln('Confirmed swing highs and lows (lookback = 3 candles each side).');
  sb.writeln();
  sb.writeln('| Type | Price | Timestamp |');
  sb.writeln('|------|-------|-----------|');
  for (final s in highs) {
    sb.writeln('| ▲ HIGH | \$${s.price.toStringAsFixed(4)} | ${_fmt(s.timestamp)} |');
  }
  for (final s in lows) {
    sb.writeln('| ▼ LOW | \$${s.price.toStringAsFixed(4)} | ${_fmt(s.timestamp)} |');
  }
  if (swings.isEmpty) sb.writeln('| — | none found | — |');
  sb.writeln();
  sb.writeln('---');
  sb.writeln();

  // ── FVGs ────────────────────────────────────────────────────────────────────
  sb.writeln('## Active Fair Value Gaps (${fvgs.length})');
  sb.writeln();
  sb.writeln('Price gaps left by aggressive displacement candles. Only unfilled gaps shown.');
  sb.writeln();
  sb.writeln('| Direction | Lower | Upper | Gap Size | Fill % | Displacement Candle |');
  sb.writeln('|-----------|-------|-------|----------|--------|---------------------|');
  for (final f in fvgs) {
    final dir = f.dir == FvgDir.bullish ? '▲ Bullish' : '▼ Bearish';
    sb.writeln('| $dir | \$${f.lower.toStringAsFixed(4)} | \$${f.upper.toStringAsFixed(4)} | \$${f.gap.toStringAsFixed(4)} | ${(f.fillPct * 100).toStringAsFixed(0)}% | ${_fmt(f.timestamp)} |');
  }
  if (fvgs.isEmpty) sb.writeln('| — | none | — | — | — | — |');
  sb.writeln();
  sb.writeln('---');
  sb.writeln();

  // ── Liquidity clusters ──────────────────────────────────────────────────────
  sb.writeln('## Liquidity Clusters (${clusters.length})');
  sb.writeln();
  sb.writeln('Price levels where multiple swing highs or lows cluster together — stop orders accumulate here and are targets for sweeps.');
  sb.writeln();
  sb.writeln('| Side | Price | Swing Points in Cluster |');
  sb.writeln('|------|-------|------------------------|');
  for (final c in clusters) {
    final side = c.side == SweepDir.bullish ? '▲ Equal Lows (buy-side liq.)' : '▼ Equal Highs (sell-side liq.)';
    sb.writeln('| $side | \$${c.price.toStringAsFixed(4)} | ${c.count} |');
  }
  if (clusters.isEmpty) sb.writeln('| — | none | — |');
  sb.writeln();
  sb.writeln('---');
  sb.writeln();

  // ── Sweeps ──────────────────────────────────────────────────────────────────
  sb.writeln('## Liquidity Sweeps (${sweeps.length} unique clusters swept)');
  sb.writeln();
  sb.writeln('One row per cluster. "Times swept" = how many candles pierced and reversed the same cluster. Most recent sweep shown.');
  sb.writeln();
  sb.writeln('| Direction | Cluster Price | Most Recent Wick | Close | Penetration | Times Swept | Recency | Timestamp |');
  sb.writeln('|-----------|--------------|-----------------|-------|-------------|-------------|---------|-----------|');
  for (final s in sweeps) {
    final dir     = s.dir == SweepDir.bullish ? '▲ Bullish' : '▼ Bearish';
    final age     = totalCandles - 1 - s.candleIndex;
    final recency = age <= staleCandles ? '🟢 fresh' : '🟡 stale (${age}c ago)';
    sb.writeln('| $dir | \$${s.cluster.price.toStringAsFixed(4)} | \$${s.extreme.toStringAsFixed(4)} | \$${s.close.toStringAsFixed(4)} | \$${s.depth.toStringAsFixed(4)} | ${s.repeatCount}x | $recency | ${_fmt(s.timestamp)} |');
  }
  if (sweeps.isEmpty) sb.writeln('| — | none | — | — | — | — | — | — |');
  sb.writeln();
  sb.writeln('---');
  sb.writeln();

  // ── BOS ─────────────────────────────────────────────────────────────────────
  sb.writeln('## Break of Structure Events (${bosList.length} unique levels)');
  sb.writeln();
  sb.writeln('One row per broken swing level. "Repeat breaks" = how many candles re-broke the same level after the first. First break timestamp shown.');
  sb.writeln();
  sb.writeln('| Direction | Broken Level | Break Distance | Repeat Breaks | Recency | First Break |');
  sb.writeln('|-----------|-------------|---------------|---------------|---------|-------------|');
  for (final b in bosList) {
    final dir     = b.dir == BosDir.bullish ? '▲ Bullish' : '▼ Bearish';
    final age     = totalCandles - 1 - b.candleIndex;
    final recency = age <= staleCandles ? '🟢 fresh' : '🟡 stale (${age}c ago)';
    final repeats = b.repeatCount > 1 ? '+${b.repeatCount - 1}' : '—';
    sb.writeln('| $dir | \$${b.level.toStringAsFixed(4)} | \$${b.dist.toStringAsFixed(4)} | $repeats | $recency | ${_fmt(b.timestamp)} |');
  }
  if (bosList.isEmpty) sb.writeln('| — | none | — | — | — | — |');
  sb.writeln();
  sb.writeln('---');
  sb.writeln();

  // ── All scored setups ───────────────────────────────────────────────────────
  sb.writeln('## All Scored Setups (score ≥ 2.0)');
  sb.writeln();
  sb.writeln('Every setup the engine found, ranked by confluence score. "Approaching" = current price within 1.5× ATR of the zone.');
  sb.writeln();

  final scored = allSetups.where((s) => s.score >= 2.0).toList();
  if (scored.isEmpty) {
    sb.writeln('_No setups met the minimum score threshold._');
  } else {
    for (int i = 0; i < scored.length; i++) {
      final s = scored[i];
      final dir = s.fvg.dir == FvgDir.bullish ? '▲ Bullish' : '▼ Bearish';
      final app = s.approaching ? ' 🔴 PRICE NEAR ZONE' : '';
      final mixed = s.hasMixedDirection ? ' ⚠️ mixed signals' : '';
      sb.writeln('### Setup ${i + 1} — $dir · Score ${s.score.toStringAsFixed(1)}$app$mixed');
      sb.writeln();
      sb.writeln('| Field | Value |');
      sb.writeln('|-------|-------|');
      sb.writeln('| Direction | $dir |');
      sb.writeln('| Score | ${s.score.toStringAsFixed(1)} |');
      sb.writeln('| FVG Zone | \$${s.fvg.lower.toStringAsFixed(4)} – \$${s.fvg.upper.toStringAsFixed(4)} |');
      sb.writeln('| Zone Midpoint | \$${s.fvg.mid.toStringAsFixed(4)} |');
      sb.writeln('| Gap Size | \$${s.fvg.gap.toStringAsFixed(4)} (${(s.fvg.gap / atr * 100).toStringAsFixed(0)}% of ATR) |');
      sb.writeln('| Displacement Size | \$${s.fvg.dispSize.toStringAsFixed(4)} (${(s.fvg.dispSize / atr).toStringAsFixed(2)}× ATR) |');
      sb.writeln('| Fill % | ${(s.fvg.fillPct * 100).toStringAsFixed(0)}% |');
      sb.writeln('| Price Approaching | ${s.approaching ? "Yes" : "No"} |');
      sb.writeln('| Distance from Current Price | \$${(price - s.fvg.mid).abs().toStringAsFixed(4)} |');
      if (s.matchSweeps.isNotEmpty) {
        sb.writeln('| Sweep Confluence | ${s.matchSweeps.length} sweep(s) near zone |');
        for (final sw in s.matchSweeps) {
          sb.writeln('|   ↳ Sweep | ${sw.dir.name} · cluster \$${sw.cluster.price.toStringAsFixed(4)} · ${_fmt(sw.timestamp)} |');
        }
      }
      if (s.matchBos.isNotEmpty) {
        sb.writeln('| BOS Confluence | ${s.matchBos.length} BOS event(s) near zone |');
        for (final b in s.matchBos.take(3)) {
          sb.writeln('|   ↳ BOS | ${b.dir.name} · broke \$${b.level.toStringAsFixed(4)} · ${_fmt(b.timestamp)} |');
        }
        if (s.matchBos.length > 3) sb.writeln('|   ↳ | +${s.matchBos.length - 3} more BOS events |');
      }
      sb.writeln();
    }
  }

  sb.writeln('---');
  sb.writeln();

  // ── AI trigger candidates ───────────────────────────────────────────────────
  sb.writeln('## AI-Trigger Candidates (score ≥ 3.5 + price approaching)');
  sb.writeln();
  sb.writeln('These are the setups that would be sent to the AI reasoning layer in production. Price is currently near the zone and multiple signals are confluent.');
  sb.writeln();

  if (aiSetups.isEmpty) {
    sb.writeln('_No setups met the AI trigger threshold at this time._');
    sb.writeln();
    sb.writeln('> The engine found ${allSetups.where((s) => s.score >= 2.0).length} lower-score setups. Price may not be near any high-confidence zone right now, or the window lacks enough structure.');
  } else {
    sb.writeln('> **${aiSetups.length} setup(s) flagged.** For each one below: critique the engine\'s findings, assess signal quality and coherence, and give a verdict on whether this should escalate to full AI analysis or be filtered as noise.');
    sb.writeln();
    for (int i = 0; i < aiSetups.length; i++) {
      final s = aiSetups[i];
      final dir = s.fvg.dir == FvgDir.bullish ? '▲ BULLISH' : '▼ BEARISH';
      final mixedTag = s.hasMixedDirection ? ' ⚠️ mixed signals' : '';
      sb.writeln('### 🔴 Candidate ${i + 1} — $dir · Score ${s.score.toStringAsFixed(1)}$mixedTag');
      sb.writeln();
      sb.writeln('**Current price:** \$${price.toStringAsFixed(4)}  ');
      sb.writeln('**Zone:** \$${s.fvg.lower.toStringAsFixed(4)} – \$${s.fvg.upper.toStringAsFixed(4)}  ');
      sb.writeln('**Zone midpoint:** \$${s.fvg.mid.toStringAsFixed(4)}  ');
      sb.writeln('**Distance to zone:** \$${(price - s.fvg.mid).abs().toStringAsFixed(4)}  ');
      sb.writeln('**ATR(14):** \$${atr.toStringAsFixed(4)}  ');
      sb.writeln('**Gap size:** \$${s.fvg.gap.toStringAsFixed(4)} (${(s.fvg.gap / atr * 100).toStringAsFixed(0)}% of ATR)  ');
      sb.writeln('**Gap fill so far:** ${(s.fvg.fillPct * 100).toStringAsFixed(0)}%  ');
      sb.writeln();
      sb.writeln('**Contributing signals:**');
      sb.writeln('- Fair Value Gap (${s.fvg.dir.name}) formed at ${_fmt(s.fvg.timestamp)}');
      for (final sw in s.matchSweeps) {
        sb.writeln('- Liquidity sweep (${sw.dir.name}) of cluster at \$${sw.cluster.price.toStringAsFixed(4)} on ${_fmt(sw.timestamp)} — wick to \$${sw.extreme.toStringAsFixed(4)}, closed \$${sw.close.toStringAsFixed(4)}');
      }
      for (final b in s.matchBos.take(3)) {
        sb.writeln('- Break of structure (${b.dir.name}) above/below \$${b.level.toStringAsFixed(4)} on ${_fmt(b.timestamp)}, distance \$${b.dist.toStringAsFixed(4)}');
      }
      if (s.matchBos.length > 3) sb.writeln('- +${s.matchBos.length - 3} additional BOS events near zone');
      sb.writeln();

      // Mixed-direction warning
      if (s.hasMixedDirection) {
        sb.writeln('> ⚠️ **Mixed-direction signals detected.** One or more contributing signals point in the '
            'opposite direction to this FVG (e.g. a bullish sweep near a bearish FVG). '
            'These were scored at quarter weight. Treat confluence as weaker than the score suggests.');
        sb.writeln();
      }

      // Zone interaction candles — only from after the FVG formed
      final zoneCandles = candles.where((c) =>
        !c.timestamp.isBefore(s.fvg.timestamp) &&
        (c.high >= s.fvg.lower - atr && c.low <= s.fvg.upper + atr)
      ).toList();
      if (zoneCandles.isNotEmpty) {
        sb.writeln('**Candles that interacted with this zone (since FVG formed at ${_fmt(s.fvg.timestamp)}):**');
        sb.writeln();
        sb.writeln('| Timestamp | Open | High | Low | Close | Note |');
        sb.writeln('|-----------|------|------|-----|-------|------|');
        for (final c in zoneCandles.take(15)) {
          String note = '';
          if (c.low < s.fvg.lower && c.close > s.fvg.lower) note = 'swept below zone, closed inside';
          else if (c.high > s.fvg.upper && c.close < s.fvg.upper) note = 'swept above zone, closed inside';
          else if (c.close >= s.fvg.lower && c.close <= s.fvg.upper) note = 'closed inside zone';
          else if (c.low >= s.fvg.lower) note = 'trading above zone';
          else note = 'interacted with zone boundary';
          sb.writeln('| ${_fmt(c.timestamp)} | ${c.open} | ${c.high} | ${c.low} | ${c.close} | $note |');
        }
        if (zoneCandles.length > 15) sb.writeln('_...${zoneCandles.length - 15} more candles omitted_');
      } else {
        sb.writeln('_No candles have interacted with this zone since it formed — freshly created imbalance._');
      }
      sb.writeln();
    }
  }

  sb.writeln('---');
  sb.writeln();
  sb.writeln('*Report generated by Halo detection engine. Data source: $source. This is algorithmic pattern detection output for engine calibration purposes.*');

  return sb.toString();
}

String _fmt(DateTime dt) => dt.toUtc().toIso8601String().substring(0, 16);

/// Converts a candle count + timeframe string into an approximate human duration.
/// e.g. 30 candles on "5m" → "~2.5 hours", 20 candles on "1h" → "~20 hours"
String _stalePretty(int candles, String timeframe) {
  final m = RegExp(r'^(\d+)([mhd])$').firstMatch(timeframe);
  if (m == null) return '$candles candles';
  final n = int.parse(m.group(1)!);
  final unit = m.group(2)!;
  final totalMinutes = candles * (unit == 'm' ? n : unit == 'h' ? n * 60 : n * 1440);
  if (totalMinutes < 60) return '~$totalMinutes minutes';
  final hours = totalMinutes / 60;
  if (hours < 24) return '~${hours % 1 == 0 ? hours.toInt() : hours.toStringAsFixed(1)} hours';
  final days = hours / 24;
  return '~${days % 1 == 0 ? days.toInt() : days.toStringAsFixed(1)} days';
}
