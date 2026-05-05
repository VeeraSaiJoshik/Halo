import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/NotificationController.dart';
import 'insight_repository.dart';
import 'local_llm/echo_llm.dart';
import 'local_llm/local_llm.dart';
import 'local_reasoning_service.dart';
import 'verdict_dispatcher.dart';

/// Provider for the local LLM implementation. Override this in main.dart
/// once your partner's real model is wired in:
///
///   ProviderScope(
///     overrides: [
///       localLlmProvider.overrideWithValue(MyLlamaCppLlm(modelPath: '...')),
///     ],
///     child: HaloApp(),
///   )
///
/// The default ([EchoLlm]) is a deterministic stub so the rest of the system
/// runs end-to-end during development. It does no real reasoning — see
/// `docs/LOCAL_LLM_INTEGRATION.md` for what to build.
final localLlmProvider = Provider<LocalLlm>((_) => EchoLlm());

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
