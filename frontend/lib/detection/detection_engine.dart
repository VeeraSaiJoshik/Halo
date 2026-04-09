import '../models/candle.dart';
import '../engine/ticker_resolver.dart';

import 'asset_profile.dart';
import 'candle_buffer.dart';
import 'swing_points.dart';
import 'fvg.dart';
import 'liquidity_sweep.dart';
import 'bos.dart';
import 'confluence.dart';

export 'asset_profile.dart';
export 'candle_buffer.dart';
export 'swing_points.dart';
export 'fvg.dart';
export 'liquidity_sweep.dart';
export 'bos.dart';
export 'confluence.dart';

/// The top-level detection engine.
///
/// Wired into the intake service like this:
///
///   final engine = DetectionEngine();
///   intake.onTickerSwitch = engine.switchTicker;
///   intake.onNewCandle = (candle) {
///     final setups = engine.onCandle(candle);
///     for (final setup in setups) { /* → AI / alert */ }
///   };
class DetectionEngine {
  // Sub-detectors
  final FvgDetector _fvgDetector;
  final LiquiditySweepDetector _sweepDetector;
  final BosDetector _bosDetector;
  final ConfluenceScorer _scorer;

  // State
  final CandleBuffer _buffer;
  String _symbol = '';
  String _timeframe = '';
  AssetProfile _profile = AssetProfile.crypto;

  // Deduplication: track timestamps of events we've already emitted
  // so that a BOS/FVG detected on candle N isn't re-emitted on candle N+1.
  final Set<String> _emittedEventKeys = {};

  DetectionEngine({
    int bufferSize = 200,
    double minConfluenceScore = 2.0,
    double fvgMinAtrMultiple = 0.1,
    int swingLookback = 3,
  })  : _buffer = CandleBuffer(maxSize: bufferSize),
        _fvgDetector = FvgDetector(minAtrMultiple: fvgMinAtrMultiple),
        _sweepDetector = LiquiditySweepDetector(swingLookback: swingLookback),
        _bosDetector = BosDetector(swingLookback: swingLookback),
        _scorer = ConfluenceScorer(minScore: minConfluenceScore);

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Called by the intake service when the user switches to a new chart.
  /// Loads history, resets state, and runs a full scan so existing patterns
  /// are immediately available.
  ///
  /// Pass [source] so the engine can auto-select the correct [AssetProfile]
  /// (crypto thresholds for Binance, equity thresholds for Alpaca, etc.).
  void switchTicker(
    String symbol,
    String timeframe,
    List<Candle> history, {
    DataSource? source,
  }) {
    _symbol = symbol;
    _timeframe = timeframe;
    _profile = source != null ? AssetProfile.fromSource(source) : AssetProfile.crypto;
    _emittedEventKeys.clear();
    _buffer.loadHistory(history);
  }

  /// Called by the intake service when a new candle arrives.
  /// Runs the incremental detection scan and returns scored setups.
  /// Returns empty list if no actionable setups found.
  List<ScoredSetup> onCandle(Candle candle) {
    _buffer.add(candle);

    if (_buffer.length < 10 || _buffer.atr == 0.0) return [];

    final events = _collectEvents();
    if (events.isEmpty) return [];

    final currentPrice = candle.close;
    final atr = _buffer.atr;

    return _scorer.score(events, currentPrice: currentPrice, atr: atr);
  }

  /// Run a full scan of the buffer (useful after switchTicker for initial state).
  List<ScoredSetup> scanHistory() {
    if (_buffer.isEmpty || _buffer.atr == 0.0) return [];

    final events = _collectEvents(fullScan: true);
    if (events.isEmpty) return [];

    final currentPrice = _buffer.last?.close ?? 0.0;
    final atr = _buffer.atr;

    return _scorer.score(events, currentPrice: currentPrice, atr: atr);
  }

  // ── Accessors for debugging / UI ──────────────────────────────────────────

  String get symbol => _symbol;
  String get timeframe => _timeframe;
  AssetProfile get profile => _profile;
  CandleBuffer get buffer => _buffer;
  double get atr => _buffer.atr;

  /// All active (unfilled) FVGs in the current buffer.
  List<Fvg> get activeFvgs => _fvgDetector
      .scan(_buffer)
      .where((f) => f.status == FvgStatus.active)
      .toList();

  /// All liquidity clusters in the current buffer.
  List<LiquidityCluster> get liquidityClusters =>
      _sweepDetector.findClusters(_buffer);

  /// All swing points in the current buffer.
  List<SwingPoint> get swingPoints =>
      SwingPointDetector().scan(_buffer);

  // ── Internals ──────────────────────────────────────────────────────────────

  List<DetectionEvent> _collectEvents({bool fullScan = false}) {
    final events = <DetectionEvent>[];

    if (fullScan) {
      // Full scan: gather all events from the buffer history
      _collectFvgEvents(events, fullScan: true);
      _collectSweepEvents(events, fullScan: true);
      _collectBosEvents(events, fullScan: true);
    } else {
      // Incremental: only check what could have just formed
      _collectFvgEvents(events, fullScan: false);
      _collectSweepEvents(events, fullScan: false);
      _collectBosEvents(events, fullScan: false);
    }

    return events;
  }

  void _collectFvgEvents(List<DetectionEvent> out, {required bool fullScan}) {
    if (fullScan) {
      final fvgs = _fvgDetector.scan(_buffer);
      for (final fvg in fvgs) {
        if (fvg.status == FvgStatus.filled) continue; // ignore filled gaps
        final key = 'fvg:${fvg.direction.name}:${fvg.timestamp.millisecondsSinceEpoch}';
        if (_emittedEventKeys.contains(key)) continue;
        _emittedEventKeys.add(key);
        out.add(fvgToEvent(fvg, _symbol, _timeframe));
      }
    } else {
      final fvg = _fvgDetector.checkLatest(_buffer);
      if (fvg != null && fvg.status != FvgStatus.filled) {
        final key = 'fvg:${fvg.direction.name}:${fvg.timestamp.millisecondsSinceEpoch}';
        if (!_emittedEventKeys.contains(key)) {
          _emittedEventKeys.add(key);
          out.add(fvgToEvent(fvg, _symbol, _timeframe));
        }
      }
    }
  }

  void _collectSweepEvents(List<DetectionEvent> out, {required bool fullScan}) {
    if (fullScan) {
      final sweeps = _sweepDetector.scan(_buffer);
      for (final sweep in sweeps) {
        final key = 'sweep:${sweep.direction.name}:${sweep.timestamp.millisecondsSinceEpoch}';
        if (_emittedEventKeys.contains(key)) continue;
        _emittedEventKeys.add(key);
        out.add(sweepToEvent(sweep, _symbol, _timeframe));
      }
    } else {
      final sweep = _sweepDetector.checkLatest(_buffer);
      if (sweep != null) {
        final key = 'sweep:${sweep.direction.name}:${sweep.timestamp.millisecondsSinceEpoch}';
        if (!_emittedEventKeys.contains(key)) {
          _emittedEventKeys.add(key);
          out.add(sweepToEvent(sweep, _symbol, _timeframe));
        }
      }
    }
  }

  void _collectBosEvents(List<DetectionEvent> out, {required bool fullScan}) {
    if (fullScan) {
      final bosEvents = _bosDetector.scan(_buffer);
      for (final bos in bosEvents) {
        final key = 'bos:${bos.direction.name}:${bos.timestamp.millisecondsSinceEpoch}';
        if (_emittedEventKeys.contains(key)) continue;
        _emittedEventKeys.add(key);
        out.add(bosToEvent(bos, _symbol, _timeframe));
      }
    } else {
      final bos = _bosDetector.checkLatest(_buffer);
      if (bos != null) {
        final key = 'bos:${bos.direction.name}:${bos.timestamp.millisecondsSinceEpoch}';
        if (!_emittedEventKeys.contains(key)) {
          _emittedEventKeys.add(key);
          out.add(bosToEvent(bos, _symbol, _timeframe));
        }
      }
    }
  }
}
