# Local LLM Setup Guide — End-to-End

Everything you need to go from zero to a packaged, fine-tuned model running inside the Halo Flutter app. This covers model selection, fine-tuning, quantization, distribution, and Flutter integration.

---

## Part 1 — The Model

### Why Qwen2.5-1.5B-Instruct

You want something small enough to download quickly, fast enough to not frustrate users, and capable enough to produce coherent financial JSON. Qwen2.5-1.5B-Instruct hits all three:

- **~1.0 GB** after Q4_K_M quantization — downloads in 60-90 seconds on a typical home connection
- **10-20 tokens/sec** on Apple Silicon with Metal, 1-3 tok/sec on pure CPU (still fine for a 200-token response)
- **Best-in-class structured output** at this size — Alibaba trained the Qwen2.5 series specifically on code and structured data, so it follows JSON schemas more reliably than Llama or TinyLlama at equivalent size
- **Open weights** on Hugging Face — `Qwen/Qwen2.5-1.5B-Instruct`

Bigger models (Phi-4-mini 3.8B, Llama-3.2-3B) would be better reasoners, but their GGUF files cross GitHub's 2 GB release-asset limit and are slower to download and load. After fine-tuning on your specific task, 1.5B is more than enough — you're not asking it to write poetry, you're asking it to fill a ~10-field JSON from labeled structured inputs.

---

## Part 2 — Fine-Tuning

You don't have to fine-tune to ship. The base `Qwen2.5-1.5B-Instruct` with a good system prompt and grammar sampling (see Part 4) will produce usable verdicts. But fine-tuning makes the thesis sentences genuinely specific to the setup — less generic, fewer hallucinated levels — and is worth doing once you have real data from the detection engine.

### 2.1 Training data format

Each training example is a chat turn pair: the detection engine's `LlmRequest` JSON as the user message, a hand-verified `Verdict` JSON as the assistant reply.

```jsonl
{"messages": [
  {"role": "system", "content": "<system prompt — see Part 4>"},
  {"role": "user", "content": "{\"symbol\": \"AAPL\", \"timeframe\": \"5m\", ...}"},
  {"role": "assistant", "content": "{\"direction\": \"bearish\", \"confidence\": 7, ...}"}
]}
```

Store these as a `.jsonl` file in `scripts/finetune/data/training.jsonl`.

**How many examples:** 200 is enough for reliable structured output. 500 is better for diverse, specific theses. Getting to 200:
- Run the detection engine on 30 days of historical data for 3-4 symbols — you'll get hundreds of raw `LlmRequest` objects automatically
- Write ideal verdicts for the 50 most interesting setups by hand (entry, stop, target from the zone + ATR, thesis that references the actual events)
- Use Claude (not the local model — use the API) to generate the rest: paste each LlmRequest and ask for a Verdict JSON following your schema. Review and fix obvious errors.

### 2.2 Fine-tuning with Unsloth (free Colab A100)

Unsloth dramatically speeds up QLoRA training — 2x faster than standard PEFT on the same GPU with half the VRAM.

**Setup (run in Google Colab with A100):**

```python
# Install
!pip install unsloth
!pip install --upgrade --no-cache-dir "unsloth[colab-new] @ git+https://github.com/unslothai/unsloth.git"

from unsloth import FastLanguageModel
import torch

# Load base model in 4-bit
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="Qwen/Qwen2.5-1.5B-Instruct",
    max_seq_length=2048,
    dtype=None,          # auto-detect
    load_in_4bit=True,
)

# Attach LoRA adapters
model = FastLanguageModel.get_peft_model(
    model,
    r=16,                 # LoRA rank — 16 is fine for this task
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj",
                    "gate_proj", "up_proj", "down_proj"],
    lora_alpha=16,
    lora_dropout=0,       # 0 works well with Unsloth
    bias="none",
    use_gradient_checkpointing="unsloth",
    random_state=42,
)
```

```python
from datasets import load_dataset
from trl import SFTTrainer
from transformers import TrainingArguments

# Load your JSONL
dataset = load_dataset("json", data_files="training.jsonl", split="train")

# Apply chat template
def format_example(example):
    return {"text": tokenizer.apply_chat_template(
        example["messages"],
        tokenize=False,
        add_generation_prompt=False
    )}

dataset = dataset.map(format_example)

trainer = SFTTrainer(
    model=model,
    tokenizer=tokenizer,
    train_dataset=dataset,
    dataset_text_field="text",
    max_seq_length=2048,
    args=TrainingArguments(
        per_device_train_batch_size=4,
        gradient_accumulation_steps=4,
        warmup_steps=10,
        num_train_epochs=3,         # 3 epochs on 200-500 examples is plenty
        learning_rate=2e-4,
        fp16=not torch.cuda.is_bf16_supported(),
        bf16=torch.cuda.is_bf16_supported(),
        logging_steps=10,
        output_dir="halo-qwen-lora",
        optim="adamw_8bit",
    ),
)
trainer.train()
```

**Expected training time:** ~20-40 minutes on a free Colab A100 for 200 examples × 3 epochs.

### 2.3 Export to GGUF

After training, merge the LoRA adapter into the base weights and export:

```python
# Merge LoRA into base
model.save_pretrained_merged("halo-qwen-merged", tokenizer, save_method="merged_16bit")

# Export directly to GGUF Q4_K_M from Unsloth
model.save_pretrained_gguf("halo-qwen-gguf", tokenizer, quantization_method="q4_k_m")
```

This produces `halo-qwen-gguf/halo-qwen1.5b-ft-q4_k_m.gguf` — approximately 1.0 GB.

---

## Part 3 — Hosting the GGUF (Distribution)

### Why not bundle it in the app

A 1 GB file in a Flutter app binary is unacceptable — it bloats the installer, GitHub rejects files over 100 MB in-repo (even with LFS the bandwidth limits hurt), and app stores reject binaries that large. The model lives outside the app and downloads once.

### Option A: GitHub Releases (recommended for now)

GitHub Release assets support up to **2 GB per file**, which covers the 1.0 GB GGUF.

**Steps:**
1. On GitHub, go to the Halo repo → Releases → Draft a new release
2. Tag it `model-v1` (separate from code releases)
3. Drag `halo-qwen1.5b-ft-q4_k_m.gguf` into the asset uploader
4. Publish

The direct download URL will be:
```
https://github.com/VeeraSaiJoshik/Halo/releases/download/model-v1/halo-qwen1.5b-ft-q4_k_m.gguf
```

This URL is stable — it won't change unless you delete the release. Hardcode it in `model_downloader.dart`.

**Bandwidth:** GitHub gives you 1 GB/month bandwidth on the free tier for release downloads. That covers ~1,000 downloads. Once you have real users, move to Option B.

### Option B: Hugging Face Hub (recommended at scale)

Hugging Face hosts model files for free with no size limits and global CDN. Standard for GGUF distribution — most llama.cpp users already know to look here.

**Steps:**
1. Create a free account at huggingface.co
2. Create a new model repository: `VeeraSaiJoshik/halo-qwen1.5b-ft`
3. Install the HF CLI: `pip install huggingface_hub`
4. Upload:
```bash
huggingface-cli login
huggingface-cli upload VeeraSaiJoshik/halo-qwen1.5b-ft \
  halo-qwen1.5b-ft-q4_k_m.gguf \
  halo-qwen1.5b-ft-q4_k_m.gguf
```
5. The download URL becomes:
```
https://huggingface.co/VeeraSaiJoshik/halo-qwen1.5b-ft/resolve/main/halo-qwen1.5b-ft-q4_k_m.gguf
```

HF gives unlimited free bandwidth for public repos. This is the right long-term home.

### Switching between options

In `model_downloader.dart`, define a single const:

```dart
const _modelUrl = 'https://github.com/VeeraSaiJoshik/Halo/releases/download/model-v1/halo-qwen1.5b-ft-q4_k_m.gguf';
// or swap to HF URL when ready — one-line change
```

---

## Part 4 — The Download Flow (Flutter)

This is the part that needs to be airtight. The user opens the app for the first time, the model isn't there yet. You need a smooth download experience with progress feedback.

### Where the model lives on disk

```dart
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<String> modelFilePath() async {
  final dir = await getApplicationSupportDirectory();
  return p.join(dir.path, 'models', 'halo-qwen1.5b-ft-q4_k_m.gguf');
}
```

`getApplicationSupportDirectory()` returns:
- macOS: `~/Library/Application Support/com.halo.app/`
- Linux: `~/.local/share/com.halo.app/`
- Windows: `C:\Users\<user>\AppData\Roaming\com.halo.app\`

The file persists across app restarts and survives app updates (unlike temp directories).

### Download with progress

Use Dart's `http` package (already in pubspec) for a streaming download so you can report byte progress:

```dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ModelDownloader {
  static const _url = 'https://github.com/VeeraSaiJoshik/Halo/releases/download/model-v1/halo-qwen1.5b-ft-q4_k_m.gguf';

  /// Returns true if the model file is already cached.
  static Future<bool> isDownloaded() async {
    final path = await modelFilePath();
    return File(path).existsSync();
  }

  /// Download with progress. [onProgress] receives bytes downloaded and total.
  static Future<void> download({
    required void Function(int received, int total) onProgress,
  }) async {
    final path = await modelFilePath();
    final file = File(path);
    await file.parent.create(recursive: true);

    final request = http.Request('GET', Uri.parse(_url));
    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Download failed: HTTP ${response.statusCode}');
    }

    final total = response.contentLength ?? -1;
    int received = 0;

    final sink = file.openWrite();
    await for (final chunk in response.stream) {
      sink.add(chunk);
      received += chunk.length;
      onProgress(received, total);
    }
    await sink.close();
  }

  static Future<String> modelFilePath() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'models', 'halo-qwen1.5b-ft-q4_k_m.gguf');
  }
}
```

**What the UI should show:**
- A blocking dialog/sheet on first launch if `!isDownloaded()`
- A linear progress bar driven by `onProgress`
- The download size ("Downloading Halo AI model (1.0 GB)…")
- A "This only happens once" subtitle so users understand it's a one-time cost
- Don't let the user into the main app until the download completes — verdicts won't work without it

**Handling interruptions:**
- Write to a `.tmp` path during download, rename to final path only on completion
- On next launch, check `.tmp` exists → delete it and restart download (incomplete file)
- This prevents a partially-downloaded GGUF from being loaded by fllama (which would crash)

```dart
static Future<void> download({...}) async {
  final finalPath = await modelFilePath();
  final tmpPath = '$finalPath.tmp';
  final tmpFile = File(tmpPath);
  await tmpFile.parent.create(recursive: true);

  // ... streaming download to tmpFile ...

  await tmpFile.rename(finalPath);  // atomic rename only on success
}

static Future<bool> isDownloaded() async {
  final path = await modelFilePath();
  final tmp = File('$path.tmp');
  if (tmp.existsSync()) await tmp.delete();  // clean interrupted download
  return File(path).existsSync();
}
```

---

## Part 5 — Flutter + fllama Integration

### Add the dependency

```yaml
# pubspec.yaml
dependencies:
  fllama: ^0.5.0   # verify latest on pub.dev
```

`fllama` bundles prebuilt llama.cpp native libraries for macOS (Metal), Linux (CPU/CUDA), and Windows (CPU/CUDA). You don't compile anything — `flutter pub get` handles it.

### The system prompt

Qwen2.5 uses `<|im_start|>` / `<|im_end|>` chat tokens. Your system prompt must:
1. State the exact Verdict JSON schema
2. List the calibration flag penalties (the model already knows these after fine-tuning, but it's a good anchor)
3. Lock the direction to match the input

```dart
const _systemPrompt = '''
You are a trading setup analyzer for the Halo app. Analyze the setup and output a single JSON verdict.

OUTPUT SCHEMA (output ONLY valid JSON, no prose before or after):
{
  "direction": "<must match input setup.direction exactly>",
  "confidence": <integer 1-10>,
  "entry": {"type": "limit", "price": <float inside zone>, "zone": [<zoneLower>, <zoneUpper>]},
  "invalidation": <float — above zoneUpper if bearish, below zoneLower if bullish>,
  "target": <float — lower than currentPrice if bearish, higher if bullish>,
  "thesis": "<max 400 chars, plain prose, no markdown, specific to this setup>",
  "keyRisks": ["<specific risk>"],
  "modelId": "qwen2.5-1.5b-halo-q4"
}

CALIBRATION FLAGS (discount confidence accordingly):
- chopZone: -2 (opposing BOS near zone — congested structure)
- sameBarSweep: -1 (sweep and FVG on same candle — one event not two)
- fastFill: -1 (FVG already 50-95% consumed)
- counterTrend: -1 (setup opposes recent BOS trend)
''';
```

### The implementation

```dart
import 'package:fllama/fllama.dart';
import '../verdict.dart';
import 'local_llm.dart';
import 'llm_request.dart';
import 'model_downloader.dart';
import 'verdict_grammar.dart';
import 'dart:convert';

class HaloLlm implements LocalLlm {
  bool _ready = false;
  late String _modelPath;

  @override String get modelId => 'qwen2.5-1.5b-halo-q4';
  @override bool get isReady => _ready;

  @override
  Future<void> load() async {
    if (_ready) return;
    _modelPath = await ModelDownloader.modelFilePath();
    if (!File(_modelPath).existsSync()) {
      throw LlmLoadException('Model file not found at $_modelPath. Run the downloader first.');
    }
    _ready = true;
    // Optional: send a tiny warm-up prompt to pre-load weights into VRAM/Metal
    // await _rawPrompt('{}');
  }

  @override
  Future<Verdict> generate(LlmRequest request) async {
    if (!_ready) throw LlmGenerationException('Model not loaded');

    final userMessage = jsonEncode(request.toJson());
    final prompt = '<|im_start|>system\n$_systemPrompt<|im_end|>\n'
        '<|im_start|>user\n$userMessage<|im_end|>\n'
        '<|im_start|>assistant\n';

    final raw = await _rawPrompt(prompt);

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      // Force direction to match input — hard rule
      json['direction'] = request.setup.direction;
      json['modelId'] = modelId;
      json['generatedAt'] = DateTime.now().toIso8601String();
      json['cached'] = false;
      return Verdict.fromJson(json);
    } catch (e) {
      throw LlmGenerationException('JSON parse failed: $e\nRaw output: $raw');
    }
  }

  Future<String> _rawPrompt(String prompt) async {
    final result = await fllamaPrompt(FLlamaRunRequest(
      input: prompt,
      modelPath: _modelPath,
      maxTokens: 400,
      temperature: 0.1,    // low temp = consistent structured output
      topP: 0.9,
      grammar: verdictGbnfGrammar,   // see Part 6
    ));
    return result.trim();
  }

  @override
  Future<void> dispose() async {
    _ready = false;
  }
}
```

### Threading note

`fllamaPrompt()` already runs inference in a background isolate — you do NOT need to wrap it. The `await` in `generate()` yields to the Flutter event loop while inference runs, so the UI stays responsive. Don't add another `Isolate.spawn` on top; that would be double-wrapping.

---

## Part 6 — Grammar-Constrained JSON (the reliability lock)

llama.cpp supports **GBNF grammars** — a BNF-like format that constrains what tokens the model can emit. When you pass a grammar, the model's output is guaranteed to match the pattern. It literally cannot produce invalid JSON or omit required fields.

This is the difference between "the model usually works" and "the model always works".

### The grammar

```dart
// lib/ai/local_llm/verdict_grammar.dart

const verdictGbnfGrammar = r'''
root ::= "{" ws
  '"direction"' ws ":" ws direction "," ws
  '"confidence"' ws ":" ws confidence "," ws
  '"entry"' ws ":" ws entry "," ws
  '"invalidation"' ws ":" ws number "," ws
  '"target"' ws ":" ws number "," ws
  '"thesis"' ws ":" ws string "," ws
  '"keyRisks"' ws ":" ws risks "," ws
  '"modelId"' ws ":" ws string
ws "}"

direction ::= '"bullish"' | '"bearish"'
confidence ::= [1-9] | "10"
entry ::= "{" ws '"type"' ws ":" ws '"limit"' ws "," ws '"price"' ws ":" ws number ws "," ws '"zone"' ws ":" ws "[" ws number ws "," ws number ws "]" ws "}"
risks ::= "[" ws "]" | "[" ws string (ws "," ws string)* ws "]"
string ::= '"' [^"]* '"'
number ::= "-"? [0-9]+ ("." [0-9]+)?
ws ::= [ \t\n]*
''';
```

**What this enforces:**
- All required fields present, in order
- `direction` is exactly `"bullish"` or `"bearish"` — no typos
- `confidence` is 1–10
- `entry.zone` is a two-element array
- No extra fields, no trailing commas, no markdown

**What it doesn't validate** (enforce in Dart post-parse):
- `entry.price` is inside the zone
- `invalidation` is on the right side of the zone
- `target` is in the trade direction

Do those checks in `HaloLlm.generate()` after parsing and throw `LlmGenerationException` if violated.

---

## Part 7 — Wiring into the App

### Provider swap

In `ai_providers.dart`, change one line:

```dart
// Before:
final localLlmProvider = Provider<LocalLlm>((_) => EchoLlm());

// After:
final localLlmProvider = FutureProvider<LocalLlm>((ref) async {
  final llm = HaloLlm();
  await llm.load();   // load() checks file exists, throws LlmLoadException if not
  return llm;
});
```

Or keep it as a regular `Provider` and have the download UI gate entry into the main screen. The second approach is simpler:

```dart
// Keep as Provider<LocalLlm> returning HaloLlm()
final localLlmProvider = Provider<LocalLlm>((_) => HaloLlm());
// load() is called lazily on first generate() inside LocalReasoningService
```

### App startup flow

```
App opens
    │
    ├─ ModelDownloader.isDownloaded()?
    │       NO → show DownloadScreen (progress bar, blocks navigation)
    │               download completes → navigate to main app
    │       YES → go straight to main app
    │
    └─ Main app renders
           │
           └─ When first scored setup arrives:
                  LocalReasoningService.request()
                      └─ HaloLlm.load()  ← opens the GGUF file
                          └─ HaloLlm.generate()  ← inference
```

The GGUF file opening in `load()` takes ~1-2 seconds on M1. Since `LocalReasoningService` calls it lazily (on first request, not at app start), the user is already looking at the main chart by then — they won't notice.

---

## Part 8 — Testing Before Fine-Tuning

You don't need to fine-tune to test the integration. Steps to smoke-test:

1. Download the base (untuned) Qwen2.5-1.5B-Instruct GGUF from Hugging Face:
   ```
   https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf
   ```
   Drop it in `~/Library/Application Support/com.halo.app/models/` (rename to match the expected filename).

2. Run the Flutter app with `HaloLlm` active instead of `EchoLlm`.

3. Trigger a detection engine setup (or call `generate()` directly in a test with a hardcoded `LlmRequest`).

4. Verify:
   - No UI freeze (inference in fllama's background isolate)
   - Output parses as valid `Verdict`
   - Grammar constraint catches any malformed output before it hits `Verdict.fromJson()`

Once this baseline works, swap to the fine-tuned GGUF from GitHub Releases and the theses will be setup-specific.

---

## Summary Checklist

| Step | Who | When |
|---|---|---|
| Generate training data (LlmRequest → Verdict pairs) | You | Before fine-tuning |
| Fine-tune Qwen2.5-1.5B with Unsloth on Colab | You | ~45 min, one-time |
| Export to GGUF Q4_K_M | You | After training |
| Upload GGUF to GitHub Releases as `model-v1` | You | After export |
| Implement `ModelDownloader` + download UI | Partner | Sprint 4 |
| Implement `HaloLlm` with fllama | Partner | Sprint 4 |
| Implement `verdict_grammar.dart` | Partner | Sprint 4 |
| Swap provider from `EchoLlm` to `HaloLlm` | Partner | Sprint 4 |
| Smoke test with base GGUF | Partner | During integration |
| End-to-end test with fine-tuned GGUF | Both | After upload |
