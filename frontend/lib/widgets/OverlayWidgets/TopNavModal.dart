import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/models/customColors.dart';

class TopNavModel extends StatelessWidget {
  final Function closeTab;
  final Function reload;
  final String url;

  const TopNavModel({
    super.key,
    required this.closeTab,
    required this.reload,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        color: CustomColors.primary.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: CustomColors.background.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          _NavButton(icon: FontAwesomeIcons.x, onTap: () => closeTab()),
          _UrlPill(url: url),
          _NavButton(icon: FontAwesomeIcons.arrowRotateRight, onTap: () => reload(), reverse: true),
        ],
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final FaIconData icon;
  final VoidCallback onTap;
  final bool reverse;

  const _NavButton({required this.icon, required this.onTap, this.reverse = false});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _hovered ? 1.12 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedRotation(
          turns: _hovered ? 0.025 * (widget.reverse ? -1 : 1) : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: GestureDetector(
            onTap: widget.onTap,
            child: SizedBox(
              width: 30,
              height: 30,
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _hovered
                          ? CustomColors.background.withValues(alpha: 0.1)
                          : CustomColors.accent,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: CustomColors.background
                            .withValues(alpha: _hovered ? 0.4 : 0.07),
                        width: 1,
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _hovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.18),
                            Colors.white.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: FaIcon(
                      widget.icon,
                      color: CustomColors.background
                          .withValues(alpha: _hovered ? 1.0 : 0.85),
                      size: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UrlPill extends StatefulWidget {
  final String url;

  const _UrlPill({required this.url});

  @override
  State<_UrlPill> createState() => _UrlPillState();
}

class _UrlPillState extends State<_UrlPill> {
  bool _hovered = false;
  bool _copied = false;

  String get _displayUrl => widget.url
      .replaceFirst('https://', '')
      .replaceFirst('http://', '')
      .replaceFirst('www.', '');

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    setState(() => _copied = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _copyToClipboard,
        child: AnimatedScale(
          scale: _hovered ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 130,
            height: 30,
            decoration: BoxDecoration(
              color: _copied
                  ? Colors.green.withValues(alpha: 0.2)
                  : _hovered
                      ? CustomColors.background.withValues(alpha: 0.1)
                      : CustomColors.accent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: _copied
                    ? Colors.green.withValues(alpha: 0.5)
                    : CustomColors.background
                        .withValues(alpha: _hovered ? 0.3 : 0.07),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              spacing: 5,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _copied
                      ? FaIcon(
                          FontAwesomeIcons.check,
                          key: const ValueKey('check'),
                          size: 8,
                          color: Colors.green.withValues(alpha: 0.9),
                        )
                      : FaIcon(
                          FontAwesomeIcons.lock,
                          key: const ValueKey('lock'),
                          size: 8,
                          color: CustomColors.background
                              .withValues(alpha: _hovered ? 0.6 : 0.3),
                        ),
                ),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: _copied
                          ? Colors.green.withValues(alpha: 0.9)
                          : CustomColors.background
                              .withValues(alpha: _hovered ? 0.9 : 0.55),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                    child: Text(
                      _copied ? 'Copied!' : _displayUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
