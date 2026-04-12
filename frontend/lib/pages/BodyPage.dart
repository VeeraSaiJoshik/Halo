import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/controllers/AppController.dart';
import 'package:frontend/pages/views/AISummaryView.dart';
import 'package:frontend/pages/views/WebView.dart';
import 'package:frontend/widgets/OverlayWidgets/AddSubSection.dart';
import 'package:frontend/widgets/OverlayWidgets/BottomNavModal.dart';

class BodyPageDart extends ConsumerStatefulWidget {
  final AppController webController;
  const BodyPageDart({super.key, required this.webController});

  @override
  ConsumerState<BodyPageDart> createState() => _BodyPageDartState();
}

class _BodyPageDartState extends ConsumerState<BodyPageDart> {
  // Fractions for each panel (sum to 1.0). Reset whenever panel count changes.
  List<double> _fractions = [];

  void _syncFractions(int count) {
    if (_fractions.length != count) {
      _fractions = List.filled(count, 1.0 / count);
    }
  }

  Widget _buildPanel(AppPage page, WindowInfo tab) {
    switch (page) {
      case AppPage.PORTAL:
        return CustomWebView(controller: tab.portalController!, appController: widget.webController, pageType: AppPage.PORTAL);
      case AppPage.GRAPH_VIEWER:
        return CustomWebView(controller: tab.chartController!, appController: widget.webController, pageType: AppPage.GRAPH_VIEWER);
      case AppPage.NOTIFICATIONS:
        return AISummaryView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool tabExists = widget.webController.getCurrentTab() != null;
    final WindowInfo? currentTab = widget.webController.getCurrentTab();
    final List<AppPage> pages = tabExists ? currentTab!.pages : [];

    _syncFractions(pages.length);

    return Container(
      margin: EdgeInsets.fromLTRB(5, 0, 5, 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: EdgeInsets.all(5),
                  child: pages.isEmpty
                      ? const SizedBox.expand()
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            const double dividerWidth = 6;
                            final int dividerCount = pages.length - 1;
                            final double availableWidth =
                                constraints.maxWidth - dividerCount * dividerWidth;

                            final List<Widget> children = [];
                            for (int i = 0; i < pages.length; i++) {
                              children.add(SizedBox(
                                width: _fractions[i] * availableWidth,
                                child: _buildPanel(pages[i], currentTab!),
                              ));

                              if (i < pages.length - 1) {
                                final int leftIndex = i;
                                children.add(_PanelDivider(
                                  width: dividerWidth,
                                  onDrag: (double delta) {
                                    setState(() {
                                      const double minFraction = 0.1;
                                      final double frac = delta / availableWidth;
                                      final double newLeft = (_fractions[leftIndex] + frac)
                                          .clamp(minFraction, _fractions[leftIndex] + _fractions[leftIndex + 1] - minFraction);
                                      _fractions[leftIndex + 1] =
                                          _fractions[leftIndex] + _fractions[leftIndex + 1] - newLeft;
                                      _fractions[leftIndex] = newLeft;
                                    });
                                  },
                                ));
                              }
                            }

                            return Row(children: children);
                          },
                        ),
                ),
                tabExists
                    ? AddSubSection(side: Side.left, controller: widget.webController)
                    : const SizedBox(),
                tabExists
                    ? AddSubSection(side: Side.right, controller: widget.webController)
                    : const SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Draggable divider between panels ────────────────────────────────────────

class _PanelDivider extends StatefulWidget {
  final double width;
  final void Function(double delta) onDrag;

  const _PanelDivider({required this.width, required this.onDrag});

  @override
  State<_PanelDivider> createState() => _PanelDividerState();
}

class _PanelDividerState extends State<_PanelDivider> {
  bool _hovered  = false;
  bool _dragging = false;

  bool get _active => _hovered || _dragging;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onHorizontalDragStart:  (_) => setState(() => _dragging = true),
        onHorizontalDragEnd:    (_) => setState(() => _dragging = false),
        onHorizontalDragUpdate: (details) => widget.onDrag(details.delta.dx),
        child: SizedBox(
          width: widget.width,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _active ? 2 : 1,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(_active ? 0.55 : 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
