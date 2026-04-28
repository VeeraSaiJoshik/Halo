import '../verdict.dart';
import 'llm_request.dart';

/// Pluggable interface for whatever local LLM Halo ends up packaging.
///
/// Your partner should pick a small model (3B-ish quantized works well for
/// this kind of structured-output task on consumer hardware) and write a
/// single class that extends this interface. Everything else in Halo —
/// dispatcher, repository, sidebar UI, notifications — is model-agnostic.
///
/// **What to implement:**
///   1. [load] — open the model file, allocate buffers, warm it up. Called
///      once at app startup (or lazily on first request).
///   2. [generate] — take a structured [LlmRequest], reason about it, return
///      a [Verdict]. The implementation owns prompt templating, JSON parsing,
///      retries, and any model-specific quirks.
///   3. [dispose] — release weights, close file handles. Called on app exit.
///
/// **Implementation notes:**
///   - This runs on the **main isolate** by default. If your model takes more
///     than ~50ms per token, wrap your generate call in a Dart `Isolate` so
///     the UI doesn't freeze. The interface intentionally returns a Future so
///     you can swap to async backgrounded execution without changing callers.
///   - Output MUST be a valid [Verdict]. If the model produces malformed JSON
///     or hallucinated fields, throw [LlmGenerationException] — the caller
///     handles it gracefully and shows the user a "model failed" card.
///   - Do NOT make network calls. Halo's whole point of going local is privacy
///     and offline operation. If your model needs an external resource, bundle
///     it as an asset.
abstract class LocalLlm {
  /// Free-form id of the model. Surfaced in the UI and logs so users / devs
  /// can tell which model produced a verdict. Examples:
  ///   "llama-3.2-3b-instruct-q4_k_m"
  ///   "phi-3-mini-4k-instruct-q4"
  ///   "echo-stub" (the no-op dev implementation)
  String get modelId;

  /// True after [load] has completed successfully and [generate] is ready.
  bool get isReady;

  /// Initialize the model. Idempotent — calling twice is a no-op.
  /// Throws [LlmLoadException] on failure (missing file, OOM, unsupported
  /// quantization, etc.). The dispatcher catches this and disables the AI
  /// layer for the session — the rest of Halo keeps working.
  Future<void> load();

  /// Run inference against the structured request. Must return a [Verdict]
  /// whose `direction` matches [LlmRequest.setup.direction] and whose price
  /// levels are sane (entry inside the zone, invalidation past it, etc.).
  ///
  /// Throws [LlmGenerationException] if the model fails to produce parseable
  /// output after the implementation's internal retry budget.
  Future<Verdict> generate(LlmRequest request);

  /// Release the model and any allocated resources.
  Future<void> dispose();
}

/// Thrown when a model can't be loaded (file missing, format unsupported, OOM).
class LlmLoadException implements Exception {
  final String message;
  const LlmLoadException(this.message);
  @override
  String toString() => 'LlmLoadException: $message';
}

/// Thrown when generation fails (bad JSON, timeout, runtime error).
class LlmGenerationException implements Exception {
  final String message;
  const LlmGenerationException(this.message);
  @override
  String toString() => 'LlmGenerationException: $message';
}
