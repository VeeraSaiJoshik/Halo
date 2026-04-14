# Halo Frontend — Macros & Constants Reference

---

## Enums

### `AppEvent`
**File:** `lib/services/app_event_bus.dart`
```dart
enum AppEvent {
  newTab, closeTab, openSearch,
  moveUp, moveDown, select,
  searchClosed, searchOpened,
  leftAdd, rightAdd,
  newNotifcation, graphView, portalView, toggleNotificaitonView,
}
```

### `AppPage`
**File:** `lib/controllers/AppController.dart`
```dart
enum AppPage { PORTAL, GRAPH_VIEWER, NOTIFICATIONS }
```

### `Side`
**File:** `lib/widgets/OverlayWidgets/AddSubSection.dart`
```dart
enum Side { left, right }
```

### `PatternType`
**File:** `lib/detection/confluence.dart`
```dart
enum PatternType {
  bullishFvg, bearishFvg,
  liquiditySweepBullish, liquiditySweepBearish,
  bullishBos, bearishBos,
  bullishFvgWithSweep, bearishFvgWithSweep,
  fullBullishConfluence, fullBearishConfluence,
}
```

### `DataSource`
**File:** `lib/engine/stocks/ticker_resolver.dart`
```dart
enum DataSource { alpaca, finnhub, binance, coinbase }
```

### `FvgDirection` / `FvgStatus`
**File:** `lib/detection/fvg.dart`
```dart
enum FvgDirection { bullish, bearish }

enum FvgStatus { active, partial, filled }
```

### `SwingType`
**File:** `lib/detection/swing_points.dart`
```dart
enum SwingType { high, low }
```

### `BosDirection`
**File:** `lib/detection/bos.dart`
```dart
enum BosDirection { bullish, bearish }
```

### `SweepDirection`
**File:** `lib/detection/liquidity_sweep.dart`
```dart
enum SweepDirection { bullish, bearish }
```

---

## Color Constants

**File:** `lib/models/customColors.dart`

| Name | Value |
|------|-------|
| `primary` | `Color(0xff131B23)` |
| `accent` | `Color.fromARGB(255, 25, 41, 58)` |
| `background` | `Color(0xffDDE6F0)` |
| `purple` | `Color.fromARGB(255, 66, 72, 207)` |
| `darkPurple` | `Color(0xFF1A1B2E)` |

---

## API & Network Constants

**File:** `lib/engine/clients/yahoo_finance_client.dart`
```dart
static const String route = "https://query1.finance.yahoo.com/v1/finance/search?q=";
const allowedTypes = {'EQUITY', 'ETF', 'INDEX', 'MUTUALFUND'};
```

**File:** `lib/engine/clients/alpha_advantage_client.dart`
```dart
static const String apiKey = String.fromEnvironment('ALPHA_VANTAGE_KEY');
static const String route   = "https://www.alphavantage.co/query";
```

**File:** `lib/config/api_config.dart`
```dart
alpacaBaseUrl  = 'https://data.alpaca.markets'
binanceBaseUrl = 'https://api.binance.com'
finnhubBaseUrl = 'https://finnhub.io/api/v1'
```

---

## Ticker Sets

**File:** `lib/engine/stocks/ticker_resolver.dart`

### `_cryptoPairs`
```
BTCUSD, BTCUSDT, ETHUSD, ETHUSDT, SOLUSD, SOLUSDT,
BNBUSD, BNBUSDT, XRPUSD, XRPUSDT, ADAUSD, ADAUSDT,
DOGEUSD, DOGEUSDT, AVAXUSD, AVAXUSDT, LINKUSD, LINKUSDT,
MATICUSD, MATICUSDT, DOTUSD, DOTUSDT
```

### `_forexPairs`
```
EURUSD, GBPUSD, USDJPY, USDCHF, AUDUSD, USDCAD,
NZDUSD, EURGBP, EURJPY, GBPJPY
```

---

## Pattern Base Scores

**File:** `lib/detection/confluence.dart`

| Pattern | Score |
|---------|-------|
| `bullishFvg` | 1.5 |
| `bearishFvg` | 1.5 |
| `liquiditySweepBullish` | 2.0 |
| `liquiditySweepBearish` | 2.0 |
| `bullishBos` | 1.5 |
| `bearishBos` | 1.5 |
| `bullishFvgWithSweep` | 4.0 |
| `bearishFvgWithSweep` | 4.0 |
| `fullBullishConfluence` | 6.0 |
| `fullBearishConfluence` | 6.0 |

---

## Asset Profiles

**File:** `lib/detection/asset_profile.dart`

| Parameter | `crypto` | `usEquities` | `forex` |
|-----------|----------|--------------|---------|
| `staleCandles` | 30 | 20 | 25 |
| `minDispAtrMult` | 0.5 | 0.35 | 0.4 |
| `sweepRevMult` | 0.2 | 0.25 | 0.3 |
| `clusterTolMult` | 0.15 | 0.12 | 0.10 |
| `fvgMaxAtrMult` | 1.5 | 1.2 | 1.3 |
| `fvgMinAtrMult` | 0.1 | 0.08 | 0.08 |
| `largeDispAtrMult` | 1.5 | 1.2 | 1.3 |
| `veryLargeDispAtrMult` | 2.0 | 1.8 | 1.9 |
| `maxFillPct` | 0.9 | 0.9 | 0.9 |
| `fvgExpiryCandles` | 100 | 78 | 96 |
| `sweepExhaustionCount` | 4 | 3 | 3 |
| `chopZoneMultiplier` | 0.65 | 0.75 | 0.75 |
| `fvgMinGapAtrMult` | 0.12 | 0.15 | 0.12 |
| `sweepMinPenMult` | 0.04 | 0.06 | 0.05 |

---

## Technical Indicator Constants

**File:** `lib/detection/candle_buffer.dart`
```dart
static const int _atrPeriod = 14;
```

---

## UI / Layout Constants

**File:** `lib/widgets/OverlayWidgets/AddSubSection.dart`
```dart
static const double _iconSize    = 43;
static const double _iconSpacing = 35;
```

**File:** `lib/widgets/background_gradient_animation.dart`
```dart
static const int opacity = 25;
```

**File:** `lib/widgets/window_tab.dart`
```dart
static const _borderRadius = BorderRadius.only(
  topLeft:  Radius.circular(5),
  topRight: Radius.circular(5),
);
```

**File:** `lib/pages/BodyPage.dart`
```dart
const double dividerWidth  = 6;
const double minFraction   = 0.1;
```

**File:** `lib/engine/mouse_detection/customMouseRegion.dart`
```dart
const double kTitleBarHeight = 40;
```

---

## Riverpod Providers

**File:** `lib/models/providerModels.dart`

| Provider | Type |
|----------|------|
| `windowProvider` | `StateNotifierProvider<WindowNotifier, WindowParams>` |
| `appEventBusProvider` | `Provider<AppEventBus>` |
| `intakeServiceProvider` | `Provider<IntakeService>` |
| `appControllerProvider` | `ChangeNotifierProvider<AppController>` |

---

## CMake Defines

### Linux — `linux/CMakeLists.txt`
```cmake
BINARY_NAME         = "frontend"
APPLICATION_ID      = "com.example.frontend"
FLUTTER_MANAGED_DIR = "${CMAKE_CURRENT_SOURCE_DIR}/flutter"
BUILD_BUNDLE_DIR    = "${PROJECT_BINARY_DIR}/bundle"
INSTALL_BUNDLE_DATA_DIR  = "${CMAKE_INSTALL_PREFIX}/data"
FLUTTER_ASSET_DIR_NAME   = "flutter_assets"
# Release only:
NDEBUG
```

### Windows — `windows/CMakeLists.txt`
```cmake
BINARY_NAME              = "frontend"
INSTALL_BUNDLE_DATA_DIR  = "${CMAKE_INSTALL_PREFIX}/data"
INSTALL_BUNDLE_LIB_DIR   = "${CMAKE_INSTALL_PREFIX}"
FLUTTER_ASSET_DIR_NAME   = "flutter_assets"
# Always:
UNICODE, _UNICODE
_HAS_EXCEPTIONS=0
# Debug only:
_DEBUG
```
