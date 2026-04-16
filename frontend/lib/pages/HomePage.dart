import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/engine/mouse_detection/MouseRegionEngine.dart';
import 'package:frontend/engine/mouse_detection/customMouseRegion.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/pages/BodyPage.dart';
import 'package:frontend/pages/TitleBar.dart';
import 'package:frontend/services/app_event_bus.dart';
import 'package:frontend/widgets/OverlayWidgets/AddSubSection.dart';
import 'package:frontend/widgets/background_gradient_animation.dart';
import 'package:frontend/widgets/searchBar.dart';
import 'package:window_manager/window_manager.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  GlobalKey<CustomSearchBarState> searchBarKey = GlobalKey();
  late StreamSubscription<AppEvent> _sub;

  bool _searchActive = false;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(appEventBusProvider).stream.listen((event) {
      if (event == AppEvent.searchClosed) {
        print("the search has been closed");
        setState(() => _searchActive = false);
      } else if (event == AppEvent.searchOpened) {
        setState(() => _searchActive = true);
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appControllerProvider);
    return Container(
      decoration: const BoxDecoration(
        color: CustomColors.primary,
      ),
      width: double.infinity,
      child: BackgroundGradientAnimation(
        child: Stack(
          children: [
            Column(
              children: [
                TitleBar(),
                Expanded(
                  child: BodyPageDart()
                )
              ],
            ),
            if (_searchActive)
              Positioned.fill(
                child: InkWell(
                  onTap: () => ref.read(appEventBusProvider).emit(AppEvent.openSearch),
                  child: Container(width: double.infinity, height: double.infinity, color: Colors.black.withOpacity(0.5)),
                ),
              ),
            Positioned(
              left: 0, right: 0, top: MediaQuery.of(context).size.height * 0.45,
              child: Center(
                child: CustomSearchBar(
                  key: searchBarKey,
                ),
              ),
            ),
            MouseRegionEngine(regions: regions, debug: false,)
          ],
        )
      ),
    );
  }
}
