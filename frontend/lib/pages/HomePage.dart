import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/controllers/AppController.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/pages/BodyPage.dart';
import 'package:frontend/pages/TitleBar.dart';
import 'package:frontend/widgets/background_gradient_animation.dart';
import 'package:frontend/widgets/searchBar.dart';
import 'package:window_manager/window_manager.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  AppController controller = AppController();
  GlobalKey<CustomSearchBarState> searchBarKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller, builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900
          ),
          width: double.infinity,
          child: BackgroundGradientAnimation(
            child: Stack(
              children: [
                Column(
                  children: [
                    TitleBar(controller: controller),
                    Expanded(
                      child: BodyPageDart(webController: controller,)
                    )
                  ],
                ),
                Positioned(
                  left: 0, right: 0, top: MediaQuery.of(context).size.height * 0.45,
                  child: Center(
                    child: CustomSearchBar(
                      key: searchBarKey,
                    ),
                  ),
                ), 
                Positioned(
                  bottom: 20, 
                  right: 20, 
                  child: InkWell(
                    onTap: () => {
                      searchBarKey.currentState?.toggleSearchBarState()
                    },
                    child: Container(
                      height: 20, 
                      width: 20, 
                      color: Colors.red,
                    )
                  ),
                )
              ],
            )
          ),
        );
      }
    );
  }
}
