import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/controllers/AppController.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/themes/theme_provider.dart';

class TabSwitcherOverlay extends ConsumerWidget {
  final int highlightedIndex;

  const TabSwitcherOverlay({super.key, required this.highlightedIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final theme = ref.watch(haloThemeProvider);
    final tabs = controller.tabs;

    if (tabs.isEmpty) return const SizedBox.shrink();

    final safeIndex = highlightedIndex.clamp(0, tabs.length - 1);

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30), // More rounded pill shape
        child: BackdropFilter(
          // Increased blur for that "thick glass" look
          filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              // Smoother background transition
              color: theme.primaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: theme.whiteColor.withOpacity(0.15),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _TabIcon(
                      tab: tabs[i],
                      isHighlighted: i == safeIndex,
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

class _TabIcon extends ConsumerWidget {
  final WindowInfo tab;
  final bool isHighlighted;

  const _TabIcon({
    required this.tab,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(haloThemeProvider);
    
    // Smooth timing configuration
    const duration = Duration(milliseconds: 350);
    const curve = Curves.elasticOut; // Adds a tiny bit of "juice" to the movement

    return AnimatedScale(
      scale: isHighlighted ? 1.2 : 0.95,
      duration: duration,
      curve: curve,
      child: AnimatedRotation(
        turns: isHighlighted ? -0.015 : 0.0, // Reduced tilt for smoothness
        duration: duration,
        curve: curve,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeInOut,
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                // Color glows only when highlighted, but fades smoothly
                color: theme.accentColor.withOpacity(isHighlighted ? 0.4 : 0),
                blurRadius: isHighlighted ? 20 : 0,
                spreadRadius: isHighlighted ? 2 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeInOut,
              // Softening the color change: 
              // We move from a very faint white to the theme primary
              color: isHighlighted 
                  ? theme.accentColor.withOpacity(0.8) 
                  : theme.whiteColor.withOpacity(0.08),
              child: AnimatedContainer(
                duration: duration,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    // Subtle border that brightens up
                    color: theme.whiteColor.withOpacity(isHighlighted ? 0.5 : 0.1),
                    width: isHighlighted ? 1.2 : 1.0,
                  ),
                ),
                child: AnimatedOpacity(
                  duration: duration,
                  opacity: isHighlighted ? 1.0 : 0.6,
                  child: Image.network(
                    tab.Stock.imageUrl,
                    fit: BoxFit.contain,
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