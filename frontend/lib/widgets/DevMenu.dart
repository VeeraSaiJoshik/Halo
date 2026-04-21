import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../themes/halo_theme.dart';
import '../themes/theme_provider.dart';

class DevMenu extends ConsumerWidget {
  final VoidCallback onClose;
  const DevMenu({required this.onClose, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentType = ref.watch(haloThemeTypeProvider);

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'DESIGN LANGUAGE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                              color: Colors.white54,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: const Text(
                              '⌘ D',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white38,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      ...HaloThemeType.values.map(
                        (type) => _ThemeCard(
                          type: type,
                          isSelected: type == currentType,
                          onTap: () {
                            ref.read(haloThemeTypeProvider.notifier).state = type;
                            onClose();
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Press Esc or ⌘D to close',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white24,
                            letterSpacing: 0.3,
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
    );
  }
}

class _ThemeCard extends StatefulWidget {
  final HaloThemeType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard> {
  bool _hovering = false;

  Color get _accent {
    switch (widget.type) {
      case HaloThemeType.golden:
        return const Color(0xFFF59E0B);
      case HaloThemeType.terminal:
        return const Color(0xFF00D97A);
      case HaloThemeType.meridian:
        return const Color(0xFF3B82F6);
      case HaloThemeType.blue:
        return const Color(0xFF60A5FA);
      case HaloThemeType.green:
        return const Color(0xFF34D399);
      case HaloThemeType.pink:
        return const Color(0xFFF472B6);
      case HaloThemeType.red:
        return const Color(0xFFF87171);
    }
  }

  String get _fontPreview {
    switch (widget.type) {
      case HaloThemeType.golden:
      case HaloThemeType.blue:
      case HaloThemeType.green:
      case HaloThemeType.pink:
      case HaloThemeType.red:
        return 'Instrument Serif · Playfair · Inter · JetBrains';
      case HaloThemeType.terminal:
        return 'JetBrains Mono · IBM Plex Sans';
      case HaloThemeType.meridian:
        return 'Space Grotesk · DM Sans · Fira Code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? _accent.withOpacity(0.1)
                  : _hovering
                      ? Colors.white.withOpacity(0.05)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isSelected
                    ? _accent.withOpacity(0.45)
                    : Colors.white.withOpacity(widget.isSelected ? 0.15 : 0.07),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.isSelected ? _accent : Colors.white24,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.type.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.isSelected
                              ? Colors.white
                              : Colors.white70,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.type.tagline,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: widget.isSelected
                              ? _accent.withOpacity(0.8)
                              : Colors.white38,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fontPreview,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Colors.white24,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isSelected)
                  Icon(Icons.check_rounded, color: _accent, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
