import 'dart:async';
import 'dart:io';

import '../models/candle.dart';
import 'candle_aggregator.dart';
import 'clients/alpaca_client.dart';
import 'clients/binance_client.dart';
import 'clients/finnhub_client.dart';
import 'ticker_identifier.dart';
import 'ticker_resolver.dart';

typedef OnCandlesReady = void Function(
  String symbol,
  String timeframe,
  List<Candle> historicalCandles,
);
typedef OnNewCandle = void Function(Candle candle);

class IntakeService {
  final TickerIdentifier _identifier = TickerIdentifier();
  final TickerResolver _resolver = TickerResolver();

  final AlpacaClient? alpacaClient;
  final BinanceClient binanceClient;
  final FinnhubClient? finnhubClient;

  OnCandlesReady? onTickerSwitch;
  OnNewCandle? onNewCandle;

  String? _currentSymbol;
  String? _currentTimeframe;
  ResolvedTicker? _currentResolved;
  Timer? _pollTimer;
  CandleAggregator? _aggregator;
  DateTime? _lastCandleTimestamp;

  IntakeService({
    this.alpacaClient,
    BinanceClient? binanceClient,
    this.finnhubClient,
  }) : binanceClient = binanceClient ??
            BinanceClient(
              baseUrl: Platform.environment['BINANCE_BASE_URL'] ??
                  'https://api.binance.com',
            );

  Future<TickerInfo?> onTabTitleChanged(String tabTitle) async {
    final info = _identifier.identify(tabTitle);
    if (info == null) return null;

    if (info.symbol == _currentSymbol && info.timeframe == _currentTimeframe) {
      return info;
    }

    await _switchTo(info.symbol, info.timeframe);
    return info;
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
    if (history.isNotEmpty) {
      _lastCandleTimestamp = history.last.timestamp;
    }

    onTickerSwitch?.call(symbol, timeframe, history);
    _startPolling();
  }

  Future<List<Candle>> _fetchHistorical(ResolvedTicker resolved) async {
    try {
      switch (resolved.source) {
        case DataSource.alpaca:
          if (alpacaClient == null) return <Candle>[];
          return alpacaClient!.getHistoricalBars(
            resolved.apiSymbol,
            timeframe: resolved.apiTimeframe,
            limit: 200,
          );
        case DataSource.binance:
          return binanceClient.getKlines(
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
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await _pollForNewCandles();
    });
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

      for (final candle in recent) {
        if (_lastCandleTimestamp == null ||
            candle.timestamp.isAfter(_lastCandleTimestamp!)) {
          _lastCandleTimestamp = candle.timestamp;
          onNewCandle?.call(candle);
        }
      }
    } catch (e) {
      print('[IntakeService] Poll error: $e');
    }
  }
}
