import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/controllers/AppController.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/pages/SettingsPage.dart';
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
  @override
  void initState() {
    super.initState();
    final bus = ref.read(appEventBusProvider);
    bus.stream.listen((event) {
      if (event == AppEvent.portalView) {
        ref.read(appControllerProvider).switchTabSubPage(AppPage.PORTAL);
      } else if (event == AppEvent.graphView) {
        ref.read(appControllerProvider).switchTabSubPage(AppPage.GRAPH_VIEWER);
      } else if (event == AppEvent.toggleNotificaitonView) {
        ref.read(appControllerProvider).toggleNotifications();
      } else if (event == AppEvent.openSettings) {
        final controller = ref.read(appControllerProvider);
        if (controller.settingsOpen) {
          if (controller.tabs.isNotEmpty) {
            controller.switchTab(controller.tabs.first);
          } else {
            controller.closeSettings();
          }
        } else {
          controller.openSettings();
        }
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
        return CustomWebView(
          key: ValueKey('${tab.uuid}_portal'),
          controller: tab.portalController!,
          pageType: AppPage.PORTAL,
          context: tab,
        );
      case AppPage.GRAPH_VIEWER:
        final chart = tab.chartController;
        if (chart == null) {
          return const SizedBox.shrink();
        }
        return CustomWebView(
          key: ValueKey('${tab.uuid}_viewer'),
          controller: chart,
          pageType: AppPage.GRAPH_VIEWER,
          context: tab,
        );
      case AppPage.NOTIFICATIONS:
        return AISummaryView();
    }
  }

  // Builds the panel layout for a single tab.
  // Active panels are rendered in their pages-list order (preserving the
  // left/right side that was chosen when they were added).  Inactive WebViews
  // are kept at the end of the Row behind Offstage so WKWebView loads their
  // content in the background even while hidden.  Each panel carries a
  // ValueKey so Flutter reuses its element – and the native WebView – if the
  // panel moves position when panels are added or removed.
  Widget _buildTabContent(WindowInfo tab) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double dividerWidth = 6;

        final bool portalActive = tab.pages.contains(AppPage.PORTAL);
        final bool notifActive = tab.pages.contains(AppPage.NOTIFICATIONS);

        final List<AppPage> activeWebViews = tab.pages
            .where((p) => p == AppPage.PORTAL || p == AppPage.GRAPH_VIEWER)
            .toList();

        // Count dividers that will appear between adjacent visible panels.
        final int webViewDividers = activeWebViews.length > 1 ? 1 : 0;
        final int notifDividers =
            (notifActive && activeWebViews.isNotEmpty) ? 1 : 0;
        final double totalAvailable = constraints.maxWidth -
            (webViewDividers + notifDividers) * dividerWidth;

        // Notifications takes a fixed fraction; if it is the only active
        // panel it fills everything.
        final double notifWidth = notifActive
            ? (activeWebViews.isNotEmpty
                ? tab.notifFraction * totalAvailable
                : totalAvailable)
            : 0;
        final double webviewTotal = totalAvailable - notifWidth;

        // Width for the i-th webview in pages order.  The first one (left)
        // gets webviewSplit of the shared space; the second gets the rest.
        double webviewWidthFor(AppPage page) {
          if (activeWebViews.length <= 1) return webviewTotal;
          return page == activeWebViews.first
              ? tab.webviewSplit * webviewTotal
              : (1 - tab.webviewSplit) * webviewTotal;
        }

        final List<Widget> rowChildren = [];
        AppPage? prevPage;

        for (final page in tab.pages) {
          // Insert a divider between every pair of adjacent active panels.
          if (prevPage != null) {
            final bool notifLeft = prevPage == AppPage.NOTIFICATIONS;
            final bool notifRight = page == AppPage.NOTIFICATIONS;

            if (notifLeft || notifRight) {
              // Divider between a WebView and the Notifications panel.
              // Dragging right expands the left panel.
              // If Notifications is on the left, its fraction grows; if on
              // the right, it shrinks.
              final double sign = notifLeft ? 1.0 : -1.0;
              rowChildren.add(_PanelDivider(
                width: dividerWidth,
                onDrag: (delta) => setState(() {
                  tab.notifFraction =
                      (tab.notifFraction + sign * delta / totalAvailable)
                          .clamp(0.15, 0.6);
                }),
              ));
            } else {
              // Divider between two WebView panels.
              // webviewSplit is always the fraction for the first WebView in
              // pages order (the left one), so dragging right always increases it.
              rowChildren.add(_PanelDivider(
                width: dividerWidth,
                onDrag: (delta) => setState(() {
                  tab.webviewSplit =
                      (tab.webviewSplit + delta / webviewTotal).clamp(0.1, 0.9);
                }),
              ));
            }
          }

          if (page == AppPage.NOTIFICATIONS) {
            rowChildren.add(SizedBox(
              width: notifWidth,
              height: double.infinity,
              child: _buildPanel(AppPage.NOTIFICATIONS, tab),
            ));
          } else {
            // Wrap in Offstage(offstage: false) so the key travels with the
            // element if pages order changes, preserving WebView state.
            rowChildren.add(Offstage(
              key: ValueKey('${tab.uuid}_${page.name}'),
              offstage: false,
              child: SizedBox(
                width: webviewWidthFor(page),
                height: double.infinity,
                child: _buildPanel(page, tab),
              ),
            ));
          }

          prevPage = page;
        }

        // Inactive WebViews are appended hidden so WKWebView pre-loads their
        // content.  The same key as above lets Flutter match the element if
        // the page later becomes active and moves into the loop above.
        if (!portalActive) {
          rowChildren.add(Offstage(
            key: ValueKey('${tab.uuid}_${AppPage.PORTAL.name}'),
            offstage: true,
            child: SizedBox(
              width: 0,
              height: double.infinity,
              child: _buildPanel(AppPage.PORTAL, tab),
            ),
          ));
        }
        // Chart is created lazily on first request, so no preload Offstage here.

        return Row(children: rowChildren);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appController = ref.watch(appControllerProvider);
    final theme = ref.watch(haloThemeProvider);
    final bool tabExists = appController.getCurrentTab() != null;
    final bool showSettings = appController.settingsOpen;

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
                  // All tabs are rendered simultaneously. Inactive tabs are
                  // wrapped in Offstage so their WebViews stay loaded while
                  // hidden, making tab switches instant.
                  child: showSettings
                      ? const SettingsPage()
                      : (appController.tabs.isEmpty
                          ? _EmptyState()
                          : Stack(
                              children: [
                                for (final tab in appController.tabs)
                                  Positioned.fill(
                                    child: Offstage(
                                      offstage: !tab.isActive,
                                      child: _buildTabContent(tab),
                                    ),
                                  ),
                              ],
                            )),
                ),
                (tabExists && !showSettings) ? AddSubSection(side: Side.left) : const SizedBox(),
                (tabExists && !showSettings) ? AddSubSection(side: Side.right) : const SizedBox(),
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
            child: Text(
              '⌘T to search',
              style: theme.titleMedium.copyWith(color: theme.whiteColor),
            ),
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
  bool _hovered = false;
  bool _dragging = false;

  bool get _active => _hovered || _dragging;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(haloThemeProvider);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragEnd: (_) => setState(() => _dragging = false),
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
