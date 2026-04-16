import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/widgets/Buttons/plushyButton.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';

class Welcomewidget extends StatefulWidget {
  const Welcomewidget({super.key});

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
        SizedBox(
          height: 100,
          child: Image.asset(
            "assets/images/icon.png",
            fit: BoxFit.cover,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          "Welcome to Halo!",
          style: TextStyle(
            fontSize: 45,
            fontWeight: FontWeight.bold,
            color: CustomColors.background,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "Lorem ipsum dolor sit amet, consectetur adispiscing elit.",
          style: TextStyle(
            fontSize: 18,
            color: CustomColors.background.withOpacity(0.8),
          ),
        ),

        // Enough room to visually separate the CTA without pushing it away
        const SizedBox(height: 60),

        PlushyButton(),
      ],
    );
  }
}