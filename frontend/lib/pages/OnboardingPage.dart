import 'package:flutter/material.dart';
import 'package:frontend/widgets/OnboardingWidgets/FormWidget.dart';
import 'package:frontend/widgets/OnboardingWidgets/WelcomeWidget.dart';
import 'package:frontend/widgets/background_gradient_animation.dart';
import 'package:frontend/widgets/commandButtons.dart';

class FormController {
  int currentIndex = -1;
  VoidCallback? onChanged;

  void next() {
    currentIndex++;
    onChanged?.call();
  }
  void back() {
    currentIndex--;
    onChanged?.call();
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  bool showWelcome = true;
  FormController formController = FormController();

  void initState() {
    super.initState();
    formController.onChanged = () {
      setState(() {});
    };
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:const Color(0xFF0D0818)
      ),
      width: double.infinity,
      child: BackgroundGradientAnimation(
        child: Container(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                CommandButtons(), 
                Expanded(
                  child: formController.currentIndex == -1 ? 
                    Welcomewidget(formController: formController) :
                    FormWidget(formController: formController)
                )
              ],
            ),
          ),
        )
      )
    );
  }
}