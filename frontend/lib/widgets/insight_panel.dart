import 'package:flutter/material.dart';

import '../ai/verdict.dart';
import '../ai/insight_repository.dart';
import '../ai/verdict_dispatcher.dart';

/// Right-docked sidebar showing live trade insights.
///
/// Merges two sources:
///   1. `dispatcher.stream` — live events as setups are scored and verdicts arrive.
///   2. `repository.recent()` — persisted history so we don't lose insights
///      across app restarts.
///
/// Each insight renders as a card the user can expand, pin, or dismiss.
class InsightPanel extends StatefulWidget {
  final VerdictDispatcher dispatcher;
  final InsightRepository repository;
  final double width;

  const InsightPanel({
    super.key,
    required this.dispatcher,
    required this.repository,
    this.width = 320,
  });

  @override
  State<InsightPanel> createState() => _InsightPanelState();
}

class _InsightPanelState extends State<InsightPanel> {
  final List<_PanelEntry> _entries = [];
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
    widget.dispatcher.stream.listen(_onEvent);
  }

  Future<void> _loadHistory() async {
    final records = await widget.repository.recent(limit: 100);
    if (!mounted) return;
    setState(() {
      _entries.clear();
      for (final r in records) {
        _entries.add(_PanelEntry.fromRecord(r));
      }
    });
  }

  void _onEvent(InsightEvent event) {
    if (!mounted) return;
    setState(() {
      final idx = _entries.indexWhere((e) => e.id == event.fingerprint);
      final entry = _PanelEntry.fromEvent(event);
      if (idx >= 0) {
        _entries[idx] = entry;
      } else {
        _entries.insert(0, entry);
      }
    });
  }

  Future<void> _dismiss(_PanelEntry entry) async {
    await widget.repository.dismiss(entry.id);
    if (!mounted) return;
    setState(() => _entries.removeWhere((e) => e.id == entry.id));
  }

  Future<void> _togglePin(_PanelEntry entry) async {
    await widget.repository.pin(entry.id, pinned: !entry.pinned);
    if (!mounted) return;
    setState(() {
      final idx = _entries.indexWhere((e) => e.id == entry.id);
      if (idx >= 0) _entries[idx] = entry.copyWith(pinned: !entry.pinned);
    });
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(left: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(count: _entries.length),
          const Divider(height: 1),
          if (_entries.isEmpty)
            const Expanded(child: _EmptyState())
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _entries.length,
                itemBuilder: (_, i) {
                  final entry = _entries[i];
                  return _InsightCard(
                    entry: entry,
                    expanded: _expanded.contains(entry.id),
                    onToggleExpand: () => _toggleExpand(entry.id),
                    onDismiss: () => _dismiss(entry),
                    onTogglePin: () => _togglePin(entry),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  const _Header({required this.count});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          const Icon(Icons.insights_outlined, size: 18),
          const SizedBox(width: 8),
          const Text('Insights', style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('$count', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No active setups. The detection engine will surface high-confluence zones here as they form.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final _PanelEntry entry;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onDismiss;
  final VoidCallback onTogglePin;

  const _InsightCard({
    required this.entry,
    required this.expanded,
    required this.onToggleExpand,
    required this.onDismiss,
    required this.onTogglePin,
  });

  Color _confidenceColor() {
    final c = entry.verdict?.confidence ?? 0;
    if (c >= 7) return Colors.green;
    if (c >= 5) return Colors.amber;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final verdict = entry.verdict;
    final isBullish = verdict?.isBullish ?? entry.dominantBullish;
    final arrow = isBullish ? '▲' : '▼';
    final arrowColor = isBullish ? Colors.green : Colors.redAccent;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onToggleExpand,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(arrow, style: TextStyle(color: arrowColor, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  Text('${entry.symbol} ${entry.timeframe}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Text('· ${entry.setupScore.toStringAsFixed(1)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const Spacer(),
                  if (verdict != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _confidenceColor().withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${verdict.confidence}/10',
                        style: TextStyle(color: _confidenceColor(), fontSize: 12),
                      ),
                    ),
                  IconButton(
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onTogglePin,
                    icon: Icon(entry.pinned ? Icons.push_pin : Icons.push_pin_outlined),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _statusLine(entry),
              if (verdict != null) ...[
                const SizedBox(height: 6),
                Text(
                  verdict.thesis,
                  maxLines: expanded ? null : 2,
                  overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
                if (expanded) ...[
                  const SizedBox(height: 8),
                  _numbersRow(verdict),
                  if (verdict.keyRisks.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Key risks',
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                    for (final risk in verdict.keyRisks)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('• $risk', style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _numbersRow(Verdict verdict) {
    TextStyle small() => const TextStyle(fontSize: 11, color: Colors.grey);
    TextStyle strong() => const TextStyle(fontSize: 13, fontFeatures: [FontFeature.tabularFigures()]);
    return Row(
      children: [
        _col('Entry', verdict.entry.price.toStringAsFixed(2), small(), strong()),
        const SizedBox(width: 16),
        _col('Stop', verdict.invalidation.toStringAsFixed(2), small(), strong()),
        const SizedBox(width: 16),
        _col('Target', verdict.target.toStringAsFixed(2), small(), strong()),
      ],
    );
  }

  Widget _col(String label, String value, TextStyle s, TextStyle b) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: s),
        Text(value, style: b),
      ],
    );
  }

  Widget _statusLine(_PanelEntry e) {
    switch (e.status) {
      case InsightStatus.reasoning:
        return Row(children: const [
          SizedBox(
            width: 10, height: 10,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
          SizedBox(width: 8),
          Text('Reasoning…', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]);
      case InsightStatus.failed:
        return Text(e.message ?? 'Failed', style: const TextStyle(color: Colors.redAccent, fontSize: 12));
      case InsightStatus.ready:
        return const SizedBox.shrink();
    }
  }
}

class _PanelEntry {
  final String id;
  final String symbol;
  final String timeframe;
  final double setupScore;
  final bool dominantBullish;
  final InsightStatus status;
  final Verdict? verdict;
  final String? message;
  final bool pinned;

  const _PanelEntry({
    required this.id,
    required this.symbol,
    required this.timeframe,
    required this.setupScore,
    required this.dominantBullish,
    required this.status,
    required this.verdict,
    required this.message,
    required this.pinned,
  });

  factory _PanelEntry.fromEvent(InsightEvent e) => _PanelEntry(
        id: e.fingerprint,
        symbol: e.symbol,
        timeframe: e.timeframe,
        setupScore: e.setup.score,
        dominantBullish: e.setup.dominantPattern.name.contains('ullish'),
        status: e.status,
        verdict: e.verdict,
        message: e.message,
        pinned: false,
      );

  factory _PanelEntry.fromRecord(InsightRecord r) => _PanelEntry(
        id: r.id,
        symbol: r.symbol,
        timeframe: r.timeframe,
        setupScore: r.verdict.confidence.toDouble(),
        dominantBullish: r.verdict.isBullish,
        status: InsightStatus.ready,
        verdict: r.verdict,
        message: null,
        pinned: r.pinned,
      );

  _PanelEntry copyWith({bool? pinned}) => _PanelEntry(
        id: id,
        symbol: symbol,
        timeframe: timeframe,
        setupScore: setupScore,
        dominantBullish: dominantBullish,
        status: status,
        verdict: verdict,
        message: message,
        pinned: pinned ?? this.pinned,
      );
}
