import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/NotificationController.dart';
import 'insight_repository.dart';
import 'local_llm/halo_llm.dart';
import 'local_llm/local_llm.dart';
import 'local_reasoning_service.dart';
import 'verdict_dispatcher.dart';

/// The active LLM. Defaults to [HaloLlm] (Qwen2.5-1.5B via llamadart).
///
/// HaloLlm.load() will throw [LlmLoadException] if the model file hasn't been
/// downloaded yet — the reasoning service catches this and shows a "model
/// unavailable" card in the sidebar instead of crashing.
///
/// For development without the model file, swap back to EchoLlm():
///   final localLlmProvider = Provider<LocalLlm>((_) => EchoLlm());
final localLlmProvider = Provider<LocalLlm>((_) => HaloLlm());

final insightRepositoryProvider = Provider<InsightRepository>((ref) {
  final repo = InsightRepository();
  ref.onDispose(repo.close);
  return repo;
});

final notificationControllerProvider = Provider<NotificationController>((ref) {
  return NotificationController();
});

final localReasoningServiceProvider = Provider<LocalReasoningService>((ref) {
  final llm = ref.watch(localLlmProvider);
  final service = LocalReasoningService(llm: llm);
  ref.onDispose(service.dispose);
  return service;
});

final verdictDispatcherProvider = Provider<VerdictDispatcher>((ref) {
  final dispatcher = VerdictDispatcher(
    service: ref.watch(localReasoningServiceProvider),
    notifications: ref.watch(notificationControllerProvider),
    repository: ref.watch(insightRepositoryProvider),
  );
  ref.onDispose(dispatcher.dispose);
  return dispatcher;
});
