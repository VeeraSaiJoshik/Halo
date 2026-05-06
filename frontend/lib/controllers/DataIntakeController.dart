import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frontend/controllers/DetectionController.dart';
import 'package:frontend/controllers/NotificationController.dart';
import 'package:frontend/models/stocks.dart';
import 'package:frontend/services/app_event_bus.dart';

import '../ai/verdict_dispatcher.dart';
import '../models/candle.dart';
import '../engine/stocks/candle_aggregator.dart';
import '../engine/clients/alpaca_client.dart';
import '../engine/clients/binance_client.dart';
import '../engine/clients/finnhub_client.dart';
import '../engine/stocks/ticker_identifier.dart';
import '../engine/stocks/ticker_resolver.dart';

typedef OnCandlesReady = void Function(
  String symbol,
  String timeframe,
  List<Candle> historicalCandles,
  DataSource source,
);

class IntakeService {
  final TickerIdentifier _identifier = TickerIdentifier();
  final TickerResolver _resolver = TickerResolver();

  final AlpacaClient? alpacaClient;
  final BinanceClient binanceClient;
  final FinnhubClient? finnhubClient;
  final NotificationController notificationController = NotificationController();
  final AppEventBus eventBus;

  /// Optional: when set, scored setups from the detection engine flow through
  /// this dispatcher → Claude → notification + sidebar.
  /// Left null for environments with no proxy token configured (detection
  /// still runs; only the AI layer is silent).
  VerdictDispatcher? verdictDispatcher;

  OnCandlesReady? onTickerSwitch;

  // Fires with (latestClose, changePercent) whenever a new price is known.
  // changePercent is relative to the close of the candle before it.
  void Function(double price, double changePercent)? onPriceUpdate;

  String? _currentSymbol;
  String? _currentTimeframe;
  ResolvedTicker? _currentResolved;
  Timer? _pollTimer;
  CandleAggregator? _aggregator;
  DateTime? _lastCandleTimestamp;
  double? _lastKnownClose;
  DetectionEngine? detectionEngine;
  StockName data;

  late Function updateNotifications;

  IntakeService({
    this.alpacaClient,
    BinanceClient? binanceClient,
    this.finnhubClient,
    required this.data,
    required this.eventBus,
  }) : binanceClient = binanceClient ?? BinanceClient( baseUrl: Platform.environment['BINANCE_BASE_URL'] ?? 'https://api.binance.com', ) {
    detectionEngine = DetectionEngine();
  }

  Future<TickerInfo?> initializeInput(String symbol, String timeframe) async {
    print("[IntakeService] Tab title changed: $symbol - $timeframe");
    if (symbol == _currentSymbol && timeframe == _currentTimeframe) {
      return TickerInfo(symbol: symbol, timeframe: timeframe);
    }

    await _switchTo(symbol, timeframe);
    return TickerInfo(symbol: symbol, timeframe: timeframe);
  }

  Future<void> manualOverride(String symbol, String timeframe) async {
    await _switchTo(symbol, timeframe);
  }

  void dispose() {
    _pollTimer?.cancel();
    _aggregator?.reset();
  }

  String? get currentSymbol => _currentSymbol;
  String? get currentTimeframe => _currentTimeframe;
  bool get isActive => _currentSymbol != null && _pollTimer != null;

  Future<void> _switchTo(String symbol, String timeframe) async {
    _pollTimer?.cancel();
    _aggregator?.reset();

    _currentSymbol = symbol;
    _currentTimeframe = timeframe;
    _currentResolved = _resolver.resolve(symbol, timeframe);
    _lastCandleTimestamp = null;

    final history = await _fetchHistorical(_currentResolved!);
    print("Intake Source " + _currentResolved!.source.toString() + " returned " + history.length.toString() + " candles");
    if (history.isNotEmpty) {
      _lastCandleTimestamp = history.last.timestamp;
      _lastKnownClose = history.last.close;

      if (history.length >= 2) {
        final prevClose = history[history.length - 2].close;
        final changePercent = prevClose != 0
            ? (history.last.close - prevClose) / prevClose * 100
            : 0.0;
        onPriceUpdate?.call(history.last.close, changePercent);
      } else {
        onPriceUpdate?.call(history.last.close, 0.0);
      }
    }

    detectionEngine!.switchTicker(symbol, timeframe, history, source: _currentResolved!.source);
    _startPolling();
  }

  Future<List<Candle>> _fetchHistorical(ResolvedTicker resolved) async {
    try {
      switch (resolved.source) {
        case DataSource.alpaca:
          if (alpacaClient == null) return <Candle>[];
          return await alpacaClient!.getHistoricalBars(
            resolved.apiSymbol,
            timeframe: resolved.apiTimeframe,
            limit: 200,
          );
        case DataSource.binance:
          return await binanceClient.getKlines(
            resolved.apiSymbol,
            interval: resolved.apiTimeframe,
            limit: 200,
          );
        case DataSource.finnhub:
          if (finnhubClient == null) return <Candle>[];
          final now = DateTime.now().toUtc();
          final from = now.subtract(const Duration(days: 5));
          final candles = await finnhubClient!.getCandles(
            resolved.apiSymbol,
            resolution: resolved.apiTimeframe,
            from: from,
            to: now,
          );
          if (candles.length > 200) {
            return candles.sublist(candles.length - 200);
          }
          return candles;
        default:
          return <Candle>[];
      }
    } catch (e) {
      print('[IntakeService] Error fetching historical data: $e');
      return <Candle>[];
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _pollForNewCandles();
    });
    Future(() => _pollForNewCandles());
  }

  Future<double?> _fetchLatestPrice(ResolvedTicker resolved) async {
    try {
      switch (resolved.source) {
        case DataSource.alpaca:
          return await alpacaClient?.getLatestPrice(resolved.apiSymbol);
        case DataSource.binance:
          return await binanceClient.getLatestPrice(resolved.apiSymbol);
        case DataSource.finnhub:
          return await finnhubClient?.getLatestPrice(resolved.apiSymbol);
        default:
          return null;
      }
    } catch (e) {
      print('[IntakeService] Live-price error: $e');
      return null;
    }
  }

  Future<void> _pollForNewCandles() async {
    if (_currentResolved == null) return;

    try {
      List<Candle> recent;
      switch (_currentResolved!.source) {
        case DataSource.alpaca:
          if (alpacaClient == null) return;
          recent = await alpacaClient!.getHistoricalBars(
            _currentResolved!.apiSymbol,
            timeframe: _currentResolved!.apiTimeframe,
            limit: 5,
          );
          break;
        case DataSource.binance:
          recent = await binanceClient.getKlines(
            _currentResolved!.apiSymbol,
            interval: _currentResolved!.apiTimeframe,
            limit: 5,
          );
          break;
        case DataSource.finnhub:
          if (finnhubClient == null) return;
          final now = DateTime.now().toUtc();
          final from = now.subtract(const Duration(hours: 1));
          recent = await finnhubClient!.getCandles(
            _currentResolved!.apiSymbol,
            resolution: _currentResolved!.apiTimeframe,
            from: from,
            to: now,
          );
          break;
        default:
          return;
      }

      // Push the freshest price on every poll. We prefer a live-price
      // endpoint (latest trade / live quote / in-progress 1m bar) so the
      // badge keeps moving inside a single bar.
      if (recent.isNotEmpty) {
        final livePrice = await _fetchLatestPrice(_currentResolved!);

        // Binance klines include the in-progress bar as recent.last; Alpaca
        // and Finnhub return only closed bars. Pick the right reference:
        // we want the close of the most recently *finalized* bar.
        final isBinance = _currentResolved!.source == DataSource.binance;
        final closedCandleClose = isBinance
            ? (recent.length >= 2 ? recent[recent.length - 2].close : null)
            : recent.last.close;

        final double? latestClose;
        final double? refClose;
        if (livePrice != null) {
          latestClose = livePrice;
          refClose = closedCandleClose ?? _lastKnownClose;
        } else {
          // Fallback: no live endpoint available, use candle data only.
          latestClose = recent.last.close;
          refClose = isBinance
              ? closedCandleClose
              : (recent.length >= 2
                  ? recent[recent.length - 2].close
                  : _lastKnownClose);
        }

        if (latestClose != null && refClose != null && refClose != 0) {
          onPriceUpdate?.call(
            latestClose,
            (latestClose - refClose) / refClose * 100,
          );
        }
      }

      // Feed only genuinely new candles to the detection engine.
      for (final candle in recent) {
        if (_lastCandleTimestamp == null || candle.timestamp.isAfter(_lastCandleTimestamp!)) {
          _lastCandleTimestamp = candle.timestamp;
          _lastKnownClose = candle.close;
          detectionEngine!.onCandle(candle);
          final setups = detectionEngine!.onCandle(candle);

          // Fan out to the AI reasoning layer. The dispatcher handles its own
          // dedup, cooldowns, and failure cases — fire and forget.
          final dispatcher = verdictDispatcher;
          if (dispatcher != null && setups.isNotEmpty) {
            unawaited(dispatcher.handleSetups(
              setups: setups,
              atr: detectionEngine!.atr,
              currentPrice: candle.close,
              profile: detectionEngine!.profile,
              recentCandles: detectionEngine!.buffer.candles,
            ));
            eventBus.emit(AppEvent.newNotifcation);
          }
        }
      }
    } catch (e) {
      print('[IntakeService] Poll error: $e');
    }
  }
}
