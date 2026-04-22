import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/themes/halo_theme.dart';
import 'package:frontend/themes/theme_provider.dart';
import 'package:frontend/widgets/Buttons/plushyButton.dart';
import 'package:frontend/widgets/OnboardingWidgets/Pages.dart';

// Imported so FormWidget can call back() / next() on the shared controller.
import 'package:frontend/pages/OnboardingPage.dart';

class FormWidget extends StatelessWidget {
  final FormController formController;
  final Function launchAuth;
  final void Function() launchLoad;
  final void Function() exitAuth;
  static const int _totalSteps = 4;


  const FormWidget({super.key, required this.formController, required this.launchAuth, required this.launchLoad, required this.exitAuth});

  Widget _pageForIndex(int index) {
    switch (index) {
      case 0:  return ChooseThemePage();
      case 1:  return BuyingPortalPage(formController: formController);
      case 2:  return PlatformAuthPage(authPlatform: formController.selectedBuyingPlatform!, launchAuthWebView: launchAuth, getReady: launchLoad, exitAuth: exitAuth);
      case 3:  return ChartingPlatformPage(formController: formController);
      case 4:  return PlatformAuthPage(authPlatform: formController.selectedChartingPlatform!, launchAuthWebView: launchAuth, getReady: launchLoad, exitAuth: exitAuth);
      default: return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final index    = formController.currentIndex;
    final progress = (index + 1) / _totalSteps;
    final isLast   = index == _totalSteps - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Column(
        spacing: 15,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProgressBar(progress: progress, width: 550),
          Expanded(child: _pageForIndex(index)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 15,
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final theme = ref.watch(haloThemeProvider);
                  return PlushyButton(
                    onPressed: formController.back,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(
                      spacing: 8,
                      children: [
                        FaIcon(FontAwesomeIcons.arrowLeft, size: 12, color: theme.whiteColor),
                        Text('Back', style: theme.titleLarge.copyWith(color: theme.whiteColor)),
                      ],
                    ),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final theme = ref.watch(haloThemeProvider);
                  return PlushyButton(
                    onPressed: formController.next,
                    disabled: !formController.nextAvailable(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(
                      spacing: 8,
                      children: [
                        Text(
                          isLast ? 'Finish' : 'Next',
                          style: theme.titleLarge.copyWith(color: theme.whiteColor),
                        ),
                        FaIcon(
                          isLast ? FontAwesomeIcons.check : FontAwesomeIcons.arrowRight,
                          size: 12,
                          color: theme.whiteColor,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProgressBar extends ConsumerWidget {
  final double progress;
  final double width;

  const ProgressBar({super.key, this.progress = 0.4, required this.width});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(haloThemeProvider);
    return Container(
      width: width,
      height: 4,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: theme.whiteColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: width * progress,
        height: 4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: CustomColors.background,
        ),
      ),
    );
  }
}