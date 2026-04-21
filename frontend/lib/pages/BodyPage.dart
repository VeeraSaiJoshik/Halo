import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/controllers/AppController.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/pages/views/AISummaryView.dart';
import 'package:frontend/pages/views/WebView.dart';
import 'package:frontend/services/app_event_bus.dart';
import 'package:frontend/themes/theme_provider.dart';
import 'package:frontend/widgets/OverlayWidgets/AddSubSection.dart';
import 'package:frontend/widgets/OverlayWidgets/BottomNavModal.dart';

class BodyPageDart extends ConsumerStatefulWidget {
  const BodyPageDart({super.key});

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

  void initState() {
    super.initState();
    final bus = ref.read(appEventBusProvider);
    bus.stream.listen((event) {
      if (event == AppEvent.portalView) {
        final controller = ref.read(appControllerProvider);
        controller.switchTabSubPage(AppPage.PORTAL);
      } else if (event == AppEvent.graphView) {
        final controller = ref.read(appControllerProvider);
        controller.switchTabSubPage(AppPage.GRAPH_VIEWER);
      } else if (event == AppEvent.toggleNotificaitonView) {
        final controller = ref.read(appControllerProvider);
        controller.toggleNotifications();
      }
    });
    bus.tabSwitchStream.listen((index) {
      final controller = ref.read(appControllerProvider);
      if (index < controller.tabs.length) {
        controller.switchTab(controller.tabs[index]);
      }
    });
  }

  Widget _buildPanel(AppPage page, WindowInfo tab) {
    switch (page) {
      case AppPage.PORTAL:
        return CustomWebView(controller: tab.portalController!, pageType: AppPage.PORTAL, context: tab);
      case AppPage.GRAPH_VIEWER:
        return CustomWebView(controller: tab.chartController!, pageType: AppPage.GRAPH_VIEWER, context: tab);
      case AppPage.NOTIFICATIONS:
        return AISummaryView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appController = ref.watch(appControllerProvider);
    final theme = ref.watch(haloThemeProvider);
    final bool tabExists = appController.getCurrentTab() != null;
    final WindowInfo? currentTab = appController.getCurrentTab();
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
              border: Border.all(color: theme.whiteColor.withOpacity(0.10)),
            ),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: EdgeInsets.all(5),
                  child: pages.isEmpty
                      ? _EmptyState()
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
                    ? AddSubSection(side: Side.left)
                    : const SizedBox(),
                tabExists
                    ? AddSubSection(side: Side.right)
                    : const SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(haloThemeProvider);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade700.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade700.withOpacity(0.5)),
            ),
            child: Text('⌘T to search', style: theme.titleMedium.copyWith(color: theme.whiteColor)),
          ),
        ],
      ),
    );
  }
}

// ─── Draggable divider between panels ────────────────────────────────────────

class _PanelDivider extends ConsumerStatefulWidget {
  final double width;
  final void Function(double delta) onDrag;

  const _PanelDivider({required this.width, required this.onDrag});

  @override
  ConsumerState<_PanelDivider> createState() => _PanelDividerState();
}

class _PanelDividerState extends ConsumerState<_PanelDivider> {
  bool _hovered  = false;
  bool _dragging = false;

  bool get _active => _hovered || _dragging;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(haloThemeProvider);
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
                color: theme.whiteColor.withOpacity(_active ? 0.55 : 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
