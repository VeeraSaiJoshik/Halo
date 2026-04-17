import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/pages/OnboardingPage.dart';
import 'package:frontend/themes/halo_theme.dart';
import 'package:frontend/themes/theme_provider.dart';
import 'package:frontend/widgets/Buttons/plushyButton.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';

class Welcomewidget extends StatefulWidget {
  FormController formController;
  Welcomewidget({super.key, required this.formController});

  @override
  State<Welcomewidget> createState() => _WelcomewidgetState();
}

class _WelcomewidgetState extends State<Welcomewidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [

        Image.asset('assets/images/icon.png', width: 88, height: 88),

        const SizedBox(height: 24),

        Consumer(
          builder: (context, ref, _) {
            final theme = ref.watch(haloThemeProvider);
            return Text(
              "Welcome to Halo!",
              style: theme.displayMedium.copyWith(color: theme.textPrimary),
            );
          },
        ),

        const SizedBox(height: 8),

        Consumer(
          builder: (context, ref, _) {
            final theme = ref.watch(haloThemeProvider);
            return Text(
              "Lorem ipsum dolor sit amet, consectetur adispiscing elit.",
              style: theme.bodyLarge,
            );
          },
        ),

        const SizedBox(height: 36),

        PlushyButton(
          onPressed: widget.formController.next,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 12,
            children: [
              Text(
                "Get Started",
                style: TextStyle(
                  fontSize: 18,
                  color: CustomColors.background,
                  fontWeight: FontWeight.w600,
                ),
              ),
              FaIcon(
                FontAwesomeIcons.arrowRight,
                color: CustomColors.background,
                size: 15,
              ),
            ],
          ),
        ),
      ],
    );
  }
}