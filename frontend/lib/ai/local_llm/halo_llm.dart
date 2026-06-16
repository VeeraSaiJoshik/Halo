import 'dart:convert';
import 'dart:io';

import 'package:llamadart/llamadart.dart';

import '../verdict.dart';
import 'llm_request.dart';
import 'local_llm.dart';
import 'model_downloader.dart';

/// Real local LLM implementation using llamadart + llama.cpp.
///
/// Runs Qwen2.5-1.5B-Instruct (or the fine-tuned Halo variant) entirely
/// on-device. No network calls after the one-time model download.
class HaloLlm implements LocalLlm {
  LlamaEngine? _engine;
  bool _ready = false;

  @override
  String get modelId => 'qwen2.5-1.5b-halo-q4';

  @override
  bool get isReady => _ready;

  @override
  Future<void> load() async {
    if (_ready) return;
    final path = await ModelDownloader.modelFilePath();
    if (!File(path).existsSync()) {
      throw LlmLoadException(
          'Model file not found at $path. '
          'Download via ModelDownloader.download() before first use.');
    }
    try {
      _engine = LlamaEngine(LlamaBackend());
      await _engine!.loadModel(path);
      _ready = true;
    } catch (e) {
      _engine = null;
      throw LlmLoadException('llamadart failed to load model: $e');
    }
  }

  @override
  Future<Verdict> generate(LlmRequest request) async {
    if (!_ready || _engine == null) {
      throw LlmGenerationException('Model not loaded — call load() first.');
    }

    final prompt = _buildPrompt(request);
    final buffer = StringBuffer();

    await for (final token in _engine!.generate(prompt)) {
      buffer.write(token);
    }

    final raw = buffer.toString().trim();
    final preprocessed = _preprocessJson(raw);
    final json = _extractJson(preprocessed);

    if (json == null) {
      throw LlmGenerationException(
          'No valid JSON in model output. '
          'Raw: ${raw.length > 300 ? '${raw.substring(0, 300)}…' : raw}');
    }

    // Hard-enforce fields the model must not override
    json['direction'] = request.setup.direction;
    json['confidence'] = _computeConfidence(request); // always deterministic
    json['modelId'] = modelId;
    json['generatedAt'] = DateTime.now().toIso8601String();
    json['cached'] = false;

    _repairLevels(json, request);

    try {
      final verdict = Verdict.fromJson(json);
      _validateLevels(verdict, request);
      return verdict;
    } catch (e) {
      throw LlmGenerationException('Verdict validation failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await _engine?.dispose();
    _engine = null;
    _ready = false;
  }

  // ── Confidence (deterministic, same rules as EchoLlm) ────────────────────

  static int _computeConfidence(LlmRequest req) {
    final s = req.setup;
    var c = s.score.floor();
    for (final flag in s.flags) {
      switch (flag) {
        case 'chopZone':
          c -= 2;
        case 'sameBarSweep':
          c -= 1;
        case 'fastFill':
          c -= 1;
        case 'counterTrend':
          c -= 1;
      }
    }
    if (s.score >= 4.5 && s.flags.isEmpty) c += 1;
    return c.clamp(1, 10);
  }

  // ── Prompt ─────────────────────────────────────────────────────────────────

  static const _systemPrompt =
      'You are a financial trading setup analyzer for the Halo app. '
      'Analyze the provided market setup JSON and output a structured trading verdict.\n\n'
      'CRITICAL: Output ONLY a valid JSON object. No explanation, no markdown, no code fences. '
      'Your response must begin with { and end with }.\n\n'
      'CRITICAL: ALL numeric values must be pre-calculated literal decimal numbers '
      '(e.g. 523.45, -67890.0). NEVER write arithmetic expressions, formulas, or equations '
      'in any JSON field. Example: write 529.98 NOT "521.18 + 0.88 * 10". '
      'Calculate all numbers in your head first, then output only the final result.\n\n'
      'CRITICAL: Respond ONLY in English. Do not use any other language.\n\n'
      'REQUIRED OUTPUT FIELDS:\n'
      '- "direction": must exactly match input setup.direction\n'
      '- "confidence": integer 1–10\n'
      '- "entry": object with "type" ("limit"), "price" (float INSIDE the zone, '
      'between zoneLower and zoneUpper), "zone" ([zoneLower, zoneUpper])\n'
      '- "invalidation": float — for bearish: a value ABOVE zoneUpper (e.g. zoneUpper + 1×atr); '
      'for bullish: a value BELOW zoneLower (e.g. zoneLower − 1×atr)\n'
      '- "target": float — for bearish: BELOW currentPrice (profit target); '
      'for bullish: ABOVE currentPrice (profit target)\n'
      '- "thesis": string — max 400 chars, plain English prose, specific to this setup\n'
      '- "keyRisks": array of 0–3 English strings, each specific to this setup\n\n'
      'CONFIDENCE CALIBRATION (start from floor(setup.score)):\n'
      '- chopZone flag: −2\n'
      '- sameBarSweep flag: −1\n'
      '- fastFill flag: −1\n'
      '- counterTrend flag: −1\n'
      '- score ≥ 4.5 and no flags: +1\n'
      '- Clamp final value to [1, 10]';

  String _buildPrompt(LlmRequest request) =>
      '<|im_start|>system\n$_systemPrompt\n<|im_end|>\n'
      '<|im_start|>user\n${jsonEncode(request.toJson())}\n<|im_end|>\n'
      '<|im_start|>assistant\n';

  // ── JSON preprocessing ─────────────────────────────────────────────────────

  /// Evaluates arithmetic expressions in JSON numeric value positions before parsing.
  /// Handles patterns the base model sometimes emits: "521.18 + 0.88 * 10",
  /// "-312.5 / 312.5 = -1", "68240.12 * (1 + 0.1)".
  String _preprocessJson(String raw) {
    // Step 1: "expr = result" — take the result; most reliable signal
    var s = raw.replaceAllMapped(
      RegExp(r'([-\d.e+*/\s()]+)=\s*([-\d.]+)'),
      (m) => m.group(2)!,
    );

    // Step 2: evaluate remaining arithmetic in JSON value positions
    // Group 1: colon + whitespace, Group 2: expression, Group 3: JSON terminator
    s = s.replaceAllMapped(
      RegExp(
          r'(:\s*)([-\d.()\s]*\d[\d.()\s]*(?:[+\-*/][-\d.()\s]*)+)([,}\]])'),
      (m) {
        final expr = m.group(2)!.trim();
        // Only evaluate if there's an operator between two numbers
        if (!RegExp(r'\d\s*[+\-*/]\s*[\d(]').hasMatch(expr)) {
          return m.group(0)!;
        }
        final p = _ArithParser(expr);
        try {
          final result = p.parse();
          if (p.done) {
            return '${m.group(1)}${_fmtDouble(result)}${m.group(3)}';
          }
        } catch (_) {}
        return m.group(0)!;
      },
    );

    return s;
  }

  static String _fmtDouble(double v) {
    if (v.isInfinite || v.isNaN) return '0';
    final s = v.toStringAsFixed(6);
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  // ── JSON extraction ────────────────────────────────────────────────────────

  Map<String, dynamic>? _extractJson(String text) {
    // Strategy 1: whole response is already valid JSON
    try {
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {}

    // Strategy 2: inside ```json ... ``` or ``` ... ``` fences
    final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(text);
    if (fenced != null) {
      try {
        return jsonDecode(fenced.group(1)!.trim()) as Map<String, dynamic>;
      } catch (_) {}
    }

    // Strategy 3: first { to last }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      try {
        return jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
      } catch (_) {}
    }

    // Strategy 4: truncated JSON — close unclosed braces/brackets/strings
    if (start >= 0) {
      final closed = _closeTruncatedJson(text.substring(start));
      if (closed != null) {
        try {
          return jsonDecode(closed) as Map<String, dynamic>;
        } catch (_) {}
      }
    }

    return null;
  }

  /// Closes a JSON object that was cut off mid-generation.
  static String? _closeTruncatedJson(String s) {
    final stack = <String>[];
    bool inString = false;
    bool escape = false;

    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (escape) {
        escape = false;
        continue;
      }
      if (c == r'\' && inString) {
        escape = true;
        continue;
      }
      if (c == '"') {
        inString = !inString;
        continue;
      }
      if (inString) continue;
      if (c == '{') {
        stack.add('}');
      } else if (c == '[') {
        stack.add(']');
      } else if (c == '}' || c == ']') {
        if (stack.isNotEmpty) stack.removeLast();
      }
    }

    if (stack.isEmpty && !inString) return null; // already well-formed

    var result = s;
    // Close an unclosed string by discarding partial value and appending null
    if (inString) {
      // Find the last complete value boundary before the unclosed string
      final lastColon = s.lastIndexOf(':', s.lastIndexOf('"') - 1);
      if (lastColon >= 0) {
        result = '${s.substring(0, lastColon + 1)}null';
      } else {
        result = '$s"';
      }
    }
    // Close any trailing array that had a partial string element
    // (e.g. "keyRisks": ["partial — drop the partial element)
    while (stack.isNotEmpty) {
      result += stack.removeLast();
    }
    return result;
  }

  // ── Level repair ──────────────────────────────────────────────────────────

  /// Fixes entry, invalidation, and target to be on the geometrically correct
  /// side of the zone / current price. The base model sometimes negates values
  /// or places them on the wrong side.
  void _repairLevels(Map<String, dynamic> json, LlmRequest req) {
    final s = req.setup;
    final isBull = s.direction == 'bullish';

    // Clamp entry.price to zone
    final entryObj = json['entry'];
    if (entryObj is Map<String, dynamic>) {
      final raw = (entryObj['price'] as num?)?.toDouble();
      entryObj['price'] = raw != null
          ? raw.clamp(s.zoneLower, s.zoneUpper)
          : (s.zoneLower + s.zoneUpper) / 2;
    }

    // Fix invalidation: must be above zoneUpper (bearish) or below zoneLower (bullish)
    final rawInv = (json['invalidation'] as num?)?.toDouble();
    if (rawInv == null || (isBull && rawInv >= s.zoneLower) || (!isBull && rawInv <= s.zoneUpper)) {
      json['invalidation'] = isBull ? s.zoneLower - req.atr : s.zoneUpper + req.atr;
    }

    // Fix target: must be above currentPrice (bullish) or below currentPrice (bearish)
    final rawTarget = (json['target'] as num?)?.toDouble();
    if (rawTarget == null || (isBull && rawTarget <= req.currentPrice) || (!isBull && rawTarget >= req.currentPrice)) {
      json['target'] = isBull
          ? req.currentPrice + req.atr * 3
          : req.currentPrice - req.atr * 3;
    }
  }

  // ── Post-parse validation ──────────────────────────────────────────────────

  void _validateLevels(Verdict v, LlmRequest req) {
    final s = req.setup;
    final isBull = s.direction == 'bullish';

    if (v.entry.price < s.zoneLower - 1e-9 || v.entry.price > s.zoneUpper + 1e-9) {
      throw LlmGenerationException(
          'Entry ${v.entry.price} outside zone [${s.zoneLower}, ${s.zoneUpper}]');
    }
    if (isBull && v.invalidation >= s.zoneLower) {
      throw LlmGenerationException(
          'Bullish invalidation ${v.invalidation} must be below ${s.zoneLower}');
    }
    if (!isBull && v.invalidation <= s.zoneUpper) {
      throw LlmGenerationException(
          'Bearish invalidation ${v.invalidation} must be above ${s.zoneUpper}');
    }
    if (isBull && v.target <= req.currentPrice) {
      throw LlmGenerationException(
          'Bullish target ${v.target} must be above currentPrice ${req.currentPrice}');
    }
    if (!isBull && v.target >= req.currentPrice) {
      throw LlmGenerationException(
          'Bearish target ${v.target} must be below currentPrice ${req.currentPrice}');
    }
  }
}

// ── Arithmetic expression parser ──────────────────────────────────────────────

/// Minimal recursive-descent parser: handles +, -, *, /, parentheses, unary minus.
class _ArithParser {
  final String _s;
  int _pos = 0;

  _ArithParser(String input) : _s = input.replaceAll(' ', '');

  bool get done => _pos >= _s.length;

  double parse() => _expr();

  double _expr() {
    var v = _term();
    while (_pos < _s.length && (_s[_pos] == '+' || _s[_pos] == '-')) {
      final op = _s[_pos++];
      v = op == '+' ? v + _term() : v - _term();
    }
    return v;
  }

  double _term() {
    var v = _factor();
    while (_pos < _s.length && (_s[_pos] == '*' || _s[_pos] == '/')) {
      final op = _s[_pos++];
      final r = _factor();
      v = op == '*' ? v * r : v / r;
    }
    return v;
  }

  double _factor() {
    if (_pos < _s.length && _s[_pos] == '(') {
      _pos++;
      final v = _expr();
      if (_pos < _s.length && _s[_pos] == ')') _pos++;
      return v;
    }
    if (_pos < _s.length && _s[_pos] == '-') {
      _pos++;
      return -_factor();
    }
    return _number();
  }

  double _number() {
    final start = _pos;
    while (_pos < _s.length && RegExp(r'[0-9.]').hasMatch(_s[_pos])) _pos++;
    if (_pos == start) throw FormatException('Expected number at pos $_pos in "$_s"');
    return double.parse(_s.substring(start, _pos));
  }
}
