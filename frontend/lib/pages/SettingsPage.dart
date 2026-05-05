import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/services/logout_service.dart';
import 'package:frontend/themes/halo_theme.dart';
import 'package:frontend/themes/theme_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(haloThemeProvider);
    final whiteColor = theme.whiteColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 56, 32, 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: whiteColor.withOpacity(0.92),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Personalize your workspace.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: whiteColor.withOpacity(0.42),
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 48),
              _SectionHeader(
                eyebrow: 'APPEARANCE',
                title: 'Theme',
                description: 'Choose how Halo looks. Changes apply instantly.',
              ),
              const SizedBox(height: 24),
              const _ThemeGrid(),
              const SizedBox(height: 56),
              _SectionHeader(
                eyebrow: 'ACCOUNT',
                title: 'Session',
                description: 'Manage your authenticated session.',
              ),
              const SizedBox(height: 24),
              const _SignOutRow(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends ConsumerWidget {
  final String eyebrow;
  final String title;
  final String description;
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(haloThemeProvider);
    final whiteColor = theme.whiteColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            color: whiteColor.withOpacity(0.54),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: whiteColor.withOpacity(0.92),
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: whiteColor.withOpacity(0.42),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _ThemeGrid extends ConsumerWidget {
  const _ThemeGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentType = ref.watch(haloThemeTypeProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth >= 640 ? 4 : 2;
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: HaloThemeType.values.map((type) {
            return SizedBox(
              width: cardWidth,
              child: _ThemeCard(
                type: type,
                isSelected: type == currentType,
                onTap: () async {
                  ref.read(haloThemeTypeProvider.notifier).state = type;
                  await ref.read(settingsProvider).applyTheme(type);
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ThemeCard extends ConsumerStatefulWidget {
  final HaloThemeType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  ConsumerState<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends ConsumerState<_ThemeCard> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(haloThemeProvider);
    final accent = widget.type.previewAccent;
    final whiteColor = theme.whiteColor;

    final double scale = _pressed ? 0.97 : (_hovering ? 1.015 : 1.0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? accent.withOpacity(0.07)
                  : (_hovering
                      ? whiteColor.withOpacity(0.04)
                      : whiteColor.withOpacity(0.02)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.isSelected
                    ? accent.withOpacity(0.55)
                    : whiteColor.withOpacity(_hovering ? 0.14 : 0.08),
                width: widget.isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 56,
                      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent,
                            accent.withOpacity(0.45),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    if (widget.isSelected)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: whiteColor.withOpacity(0.35),
                              width: 0.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.type.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.isSelected
                              ? whiteColor
                              : whiteColor.withOpacity(0.78),
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
                              ? accent.withOpacity(0.85)
                              : whiteColor.withOpacity(0.38),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignOutRow extends ConsumerStatefulWidget {
  const _SignOutRow();

  @override
  ConsumerState<_SignOutRow> createState() => _SignOutRowState();
}

class _SignOutRowState extends ConsumerState<_SignOutRow> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF87171);
    final theme = ref.watch(haloThemeProvider);
    final whiteColor = theme.whiteColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () async {
          final settings = ref.read(settingsProvider);
          await logoutAndReset(context, settings);
        },
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: _hovering
                  ? accent.withOpacity(0.12)
                  : accent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accent.withOpacity(_hovering ? 0.5 : 0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(_hovering ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: accent,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: whiteColor.withOpacity(0.92),
                          letterSpacing: 0.05,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Clears cookies and local settings.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: accent.withOpacity(0.75),
                          letterSpacing: 0.15,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: accent.withOpacity(_hovering ? 0.85 : 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
