import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Manages the one-time download and local caching of the Halo LLM model file.
///
/// Flow:
///   1. On first app launch, check [isDownloaded].
///   2. If false, show a download UI and call [download] with an [onProgress] callback.
///   3. Once complete, [HaloLlm.load] will find the file and succeed.
///
/// The file is written to a .tmp path and renamed atomically on completion.
/// Interrupted downloads are detected and cleaned up automatically.
class ModelDownloader {
  static const String _modelFilename = 'halo-qwen1.5b-q4_k_m.gguf';

  /// Direct download URL for the model GGUF.
  ///
  /// Currently points to the base Qwen2.5-1.5B-Instruct GGUF on Hugging Face
  /// for immediate smoke-testing. Replace with the fine-tuned model URL from
  /// GitHub Releases after running scripts/finetune/train.py.
  static const String modelUrl =
      'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/'
      'qwen2.5-1.5b-instruct-q4_k_m.gguf';

  /// Human-readable size hint for the download UI.
  static const String expectedSizeLabel = '~1.0 GB';

  /// Returns the full path where the model file is cached on this device.
  ///
  /// macOS: ~/Library/Application Support/<bundle-id>/models/
  /// Linux: ~/.local/share/<bundle-id>/models/
  /// Windows: %APPDATA%\<bundle-id>\models\
  static Future<String> modelFilePath() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'models', _modelFilename);
  }

  /// Returns true if the model is present and complete.
  ///
  /// Cleans up any .tmp leftover from an interrupted download.
  static Future<bool> isDownloaded() async {
    final path = await modelFilePath();
    final tmp = File('$path.tmp');
    if (tmp.existsSync()) await tmp.delete();
    return File(path).existsSync();
  }

  /// Downloads the model file with streaming progress.
  ///
  /// [onProgress] receives (bytesReceived, totalBytes). totalBytes is -1 if
  /// the server doesn't include Content-Length.
  ///
  /// Throws [Exception] on HTTP error or IO failure. Caller should show an
  /// error message and offer a retry button.
  static Future<void> download({
    void Function(int received, int total)? onProgress,
  }) async {
    final finalPath = await modelFilePath();
    final tmpPath = '$finalPath.tmp';

    await Directory(p.dirname(finalPath)).create(recursive: true);

    final request = http.Request('GET', Uri.parse(modelUrl));
    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception(
          'Model download failed: HTTP ${response.statusCode}. '
          'Check your connection and try again.');
    }

    final total = response.contentLength ?? -1;
    int received = 0;
    final sink = File(tmpPath).openWrite();

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.close();
      await File(tmpPath).rename(finalPath);
    } catch (e) {
      await sink.close();
      final tmp = File(tmpPath);
      if (tmp.existsSync()) await tmp.delete();
      rethrow;
    }
  }

  /// Removes the cached model file (e.g. to force a re-download after an update).
  static Future<void> clearCache() async {
    final path = await modelFilePath();
    final f = File(path);
    if (f.existsSync()) await f.delete();
  }
}
