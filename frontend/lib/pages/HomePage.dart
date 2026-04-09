import 'package:flutter/material.dart';
import 'package:frontend/controllers/AppController.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/pages/BodyPage.dart';
import 'package:frontend/pages/TitleBar.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AppController controller = AppController();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller, builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15)),
            color: CustomColors.accent.withOpacity(0.7)
          ),
          width: double.infinity,
          child: Column(
            children: [
              TitleBar(controller: controller),
              Expanded(
                child: BodyPageDart(webController: controller,)
              )
            ],
          ),
        );
      }
    );
  }
}