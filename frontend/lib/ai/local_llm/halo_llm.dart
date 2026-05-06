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
///
/// To use: override [localLlmProvider] in main.dart with HaloLlm(), then call
/// ModelDownloader.download() on first launch before any generate() requests.
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
    final json = _extractJson(raw);

    if (json == null) {
      throw LlmGenerationException(
          'No valid JSON in model output. '
          'Raw: ${raw.length > 300 ? '${raw.substring(0, 300)}…' : raw}');
    }

    // Hard-enforce fields the model must not override
    json['direction'] = request.setup.direction;
    json['modelId'] = modelId;
    json['generatedAt'] = DateTime.now().toIso8601String();
    json['cached'] = false;

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

  // ── Prompt ─────────────────────────────────────────────────────────────────

  static const _systemPrompt =
      'You are a financial trading setup analyzer for the Halo app. '
      'Analyze the provided market setup JSON and output a structured trading verdict.\n\n'
      'CRITICAL: Output ONLY a valid JSON object. No explanation, no markdown, no code fences. '
      'Your response must begin with { and end with }.\n\n'
      'REQUIRED OUTPUT FIELDS:\n'
      '- "direction": must exactly match input setup.direction\n'
      '- "confidence": integer 1–10\n'
      '- "entry": object with "type" ("limit"), "price" (float inside the zone), '
      '"zone" ([zoneLower, zoneUpper])\n'
      '- "invalidation": float — above zoneUpper for bearish, below zoneLower for bullish\n'
      '- "target": float — below currentPrice for bearish, above currentPrice for bullish\n'
      '- "thesis": string — max 400 chars, plain prose, specific to this setup\n'
      '- "keyRisks": array of 0–3 strings, each specific to this setup\n\n'
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

    return null;
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
