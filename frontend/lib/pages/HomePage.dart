import 'package:flutter/material.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/pages/BodyPage.dart';
import 'package:frontend/pages/TitleBar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(15)),
        color: CustomColors.primary.withOpacity(0.4)
      ),
      width: double.infinity,
      child: Column(
        children: [
          TitleBar(),
          Expanded(
            child: BodyPageDart()
          )
        ],
      ),
    );
  }
}