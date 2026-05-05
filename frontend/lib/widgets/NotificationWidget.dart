import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/ai/verdict.dart';
import 'package:frontend/themes/halo_theme.dart';
import 'package:frontend/themes/theme_provider.dart';

class NotificationWidget extends ConsumerWidget {
  final Verdict verdict;
  final VoidCallback? onClose;

  const NotificationWidget({
    super.key,
    required this.verdict,
    this.onClose,
  });

  static OverlayEntry? _activeEntry;

  static Future<void> show(
    BuildContext context, {
    required Verdict verdict,
  }) {
    _activeEntry?.remove();
    _activeEntry = null;

    final overlay = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;
    final completer = Completer<void>();

    void remove() {
      if (_activeEntry == entry) {
        _activeEntry = null;
      }
      if (entry.mounted) {
        entry.remove();
      }
      if (!completer.isCompleted) completer.complete();
    }

    entry = OverlayEntry(
      builder: (ctx) => _NotificationOverlayHost(
        verdict: verdict,
        onClosed: remove,
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
    return completer.future;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(haloThemeProvider);
    final isBullish = verdict.isBullish;
    final dirColor = isBullish
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);
    final glow = theme.accentColor;

    final media = MediaQuery.of(context);
    final maxW = media.size.width < 420 ? media.size.width - 32 : 380.0;
    final maxH = media.size.height * 0.72;

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
        child: Semantics(
          liveRegion: true,
          label: '${isBullish ? 'Bullish' : 'Bearish'} verdict notification',
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.whiteColor.withValues(alpha: 0.20),
                width: 0.5,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: glow.withValues(alpha: 0.30),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: dirColor.withValues(alpha: 0.10),
                  blurRadius: 32,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ColoredBox(
                color: theme.primaryColor,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.whiteColor.withValues(alpha: 0.6),
                        width: 0.5,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.primaryColor.withValues(alpha: 0.92),
                          theme.backgroundColor.withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(
                          theme: theme,
                          dirColor: dirColor,
                          isBullish: isBullish,
                          cached: verdict.cached,
                          onClose: () {
                            if (onClose != null) {
                              onClose!();
                            } else {
                              Navigator.of(context).maybePop();
                            }
                          },
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ConfidenceBar(
                                  theme: theme,
                                  dirColor: dirColor,
                                  confidence: verdict.confidence,
                                ),
                                const SizedBox(height: 20),
                                _PriceGrid(
                                  theme: theme,
                                  dirColor: dirColor,
                                  entry: verdict.entry,
                                  invalidation: verdict.invalidation,
                                  target: verdict.target,
                                ),
                                const SizedBox(height: 20),
                                _Section(
                                  theme: theme,
                                  label: 'THESIS',
                                  child: Text(
                                    verdict.thesis,
                                    style: theme.bodyMedium.copyWith(
                                      color: theme.textPrimary,
                                      height: 1.5,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (verdict.keyRisks.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  _Section(
                                    theme: theme,
                                    label: 'KEY RISKS',
                                    child: _RiskList(
                                      theme: theme,
                                      items: verdict.keyRisks,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                _Footer(
                                  theme: theme,
                                  modelId: verdict.modelId,
                                  generatedAt: verdict.generatedAt,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationOverlayHost extends StatefulWidget {
  final Verdict verdict;
  final VoidCallback onClosed;

  const _NotificationOverlayHost({
    required this.verdict,
    required this.onClosed,
  });

  @override
  State<_NotificationOverlayHost> createState() =>
      _NotificationOverlayHostState();
}

class _NotificationOverlayHostState extends State<_NotificationOverlayHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (!reduceMotion) {
      await _controller.reverse();
    }
    if (mounted) widget.onClosed();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations;

    return Positioned(
      right: 24 + media.padding.right,
      bottom: 24 + media.padding.bottom,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (ctx, child) {
          final raw = _controller.value.clamp(0.0, 1.0);
          final t = reduceMotion ? raw : Curves.easeOutCubic.transform(raw);
          final dx = (1 - t) * 60;
          final dy = (1 - t) * 30;
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(dx, dy),
              child: child,
            ),
          );
        },
        child: NotificationWidget(
          verdict: widget.verdict,
          onClose: () {
            _dismiss();
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final HaloThemeData theme;
  final Color dirColor;
  final bool isBullish;
  final bool cached;
  final VoidCallback onClose;

  const _Header({
    required this.theme,
    required this.dirColor,
    required this.isBullish,
    required this.cached,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            dirColor.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.whiteColor.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _DirectionPill(theme: theme, dirColor: dirColor, isBullish: isBullish),
          if (cached) ...[
            const SizedBox(width: 8),
            _MetaPill(theme: theme, label: 'CACHED'),
          ],
          const Spacer(),
          _CloseButton(theme: theme, onTap: onClose),
        ],
      ),
    );
  }
}

class _DirectionPill extends StatelessWidget {
  final HaloThemeData theme;
  final Color dirColor;
  final bool isBullish;

  const _DirectionPill({
    required this.theme,
    required this.dirColor,
    required this.isBullish,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isBullish ? 'Bullish verdict' : 'Bearish verdict',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: dirColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: dirColor.withValues(alpha: 0.55),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              isBullish
                  ? FontAwesomeIcons.arrowTrendUp
                  : FontAwesomeIcons.arrowTrendDown,
              size: 11,
              color: dirColor,
            ),
            const SizedBox(width: 7),
            Text(
              isBullish ? 'BULLISH' : 'BEARISH',
              style: theme.labelSmall.copyWith(
                color: dirColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final HaloThemeData theme;
  final String label;

  const _MetaPill({required this.theme, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: theme.whiteColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.whiteColor.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: theme.labelSmall.copyWith(
          fontSize: 10,
          color: theme.textMuted,
        ),
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  final HaloThemeData theme;
  final VoidCallback onTap;

  const _CloseButton({required this.theme, required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.theme.whiteColor.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(
              FontAwesomeIcons.xmark,
              size: 16,
              color: widget.theme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final HaloThemeData theme;
  final Color dirColor;
  final int confidence;

  const _ConfidenceBar({
    required this.theme,
    required this.dirColor,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final value = confidence.clamp(0, 10);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'CONFIDENCE',
              style: theme.labelSmall,
            ),
            const Spacer(),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$value',
                    style: theme.tickerLarge.copyWith(
                      color: dirColor,
                      fontSize: 18,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  TextSpan(
                    text: ' / 10',
                    style: theme.ticker.copyWith(
                      color: theme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Confidence $value of 10',
          child: Row(
            children: List.generate(10, (i) {
              final filled = i < value;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i == 9 ? 0 : 4),
                  height: 6,
                  decoration: BoxDecoration(
                    color: filled
                        ? dirColor.withValues(alpha: 0.85)
                        : theme.whiteColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _PriceGrid extends StatelessWidget {
  final HaloThemeData theme;
  final Color dirColor;
  final EntryPlan entry;
  final double invalidation;
  final double target;

  const _PriceGrid({
    required this.theme,
    required this.dirColor,
    required this.entry,
    required this.invalidation,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PriceRow(
          theme: theme,
          accent: dirColor,
          icon: FontAwesomeIcons.crosshairs,
          label: 'ENTRY',
          subLabel: entry.type.toUpperCase(),
          price: entry.price,
          zoneLower: entry.zoneLower,
          zoneUpper: entry.zoneUpper,
          isFirst: true,
        ),
        _PriceRow(
          theme: theme,
          accent: const Color(0xFFEF4444),
          icon: FontAwesomeIcons.shieldHalved,
          label: 'INVALIDATION',
          price: invalidation,
        ),
        _PriceRow(
          theme: theme,
          accent: const Color(0xFF22C55E),
          icon: FontAwesomeIcons.flagCheckered,
          label: 'TARGET',
          price: target,
          isLast: true,
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final HaloThemeData theme;
  final Color accent;
  final FaIconData icon;
  final String label;
  final String? subLabel;
  final double price;
  final double? zoneLower;
  final double? zoneUpper;
  final bool isFirst;
  final bool isLast;

  const _PriceRow({
    required this.theme,
    required this.accent,
    required this.icon,
    required this.label,
    required this.price,
    this.subLabel,
    this.zoneLower,
    this.zoneUpper,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasZone = zoneLower != null &&
        zoneUpper != null &&
        (zoneLower! > 0 || zoneUpper! > 0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: theme.whiteColor.withValues(alpha: 0.025),
        border: Border(
          top: BorderSide(
            color: theme.whiteColor.withValues(alpha: 0.06),
            width: 1,
          ),
          left: BorderSide(
            color: theme.whiteColor.withValues(alpha: 0.06),
            width: 1,
          ),
          right: BorderSide(
            color: theme.whiteColor.withValues(alpha: 0.06),
            width: 1,
          ),
          bottom: BorderSide(
            color: theme.whiteColor.withValues(alpha: 0.06),
            width: isLast ? 1 : 0,
          ),
        ),
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(10) : Radius.zero,
          bottom: isLast ? const Radius.circular(10) : Radius.zero,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: FaIcon(icon, size: 12, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: theme.labelSmall),
                    if (subLabel != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.whiteColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          subLabel!,
                          style: theme.labelSmall.copyWith(
                            fontSize: 9,
                            color: theme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (hasZone) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_fmt(zoneLower!)} – ${_fmt(zoneUpper!)}',
                    style: theme.bodyMedium.copyWith(
                      fontSize: 11,
                      color: theme.textMuted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            _fmt(price),
            style: theme.tickerLarge.copyWith(
              color: theme.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000) return v.toStringAsFixed(2);
    if (v >= 100) return v.toStringAsFixed(2);
    return v.toStringAsFixed(2);
  }
}

class _Section extends StatelessWidget {
  final HaloThemeData theme;
  final String label;
  final Widget child;

  const _Section({
    required this.theme,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.labelSmall),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _RiskList extends StatelessWidget {
  final HaloThemeData theme;
  final List<String> items;

  const _RiskList({required this.theme, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.accentColor.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    items[i],
                    style: theme.bodyMedium.copyWith(
                      color: theme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final HaloThemeData theme;
  final String modelId;
  final DateTime generatedAt;

  const _Footer({
    required this.theme,
    required this.modelId,
    required this.generatedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.whiteColor.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.microchip,
            size: 10,
            color: theme.textMuted,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              modelId,
              overflow: TextOverflow.ellipsis,
              style: theme.ticker.copyWith(
                fontSize: 11,
                color: theme.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: theme.textMuted.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatTimestamp(generatedAt),
            style: theme.ticker.copyWith(
              fontSize: 11,
              color: theme.textMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final diff = DateTime.now().difference(local);
    final String relative;
    if (diff.inSeconds < 60) {
      relative = 'just now';
    } else if (diff.inMinutes < 60) {
      relative = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      relative = '${diff.inHours}h ago';
    } else {
      relative = '${diff.inDays}d ago';
    }
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$relative · $hh:$mm';
  }
}
