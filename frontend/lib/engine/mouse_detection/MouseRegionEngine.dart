import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/engine/mouse_detection/customMouseRegion.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/services/app_event_bus.dart';
import 'package:frontend/themes/theme_provider.dart';

class MouseRegionEngine extends ConsumerStatefulWidget {
  List<CustomMouseRegion> regions;
  bool debug;
  MouseRegionEngine({super.key, required this.regions, this.debug = false});

  @override
  ConsumerState<MouseRegionEngine> createState() => _MouseRegionEngineState();
}

class _MouseRegionEngineState extends ConsumerState<MouseRegionEngine> {
  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(haloThemeProvider);
    return SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
              children: widget.regions.map((region) {
                  return region.getPositioned(context, MouseRegion(
                          opaque: false,
                          onEnter: (_) {
                              print(region.event);
                              ref.read(appEventBusProvider).emit(region.event);
                          },
                          child: Container(
                              decoration: BoxDecoration(
                                  color: widget.debug ? Colors.red : Colors.transparent
                              ),
                              child: widget.debug ?  Center(
                                  child: Text(
                                      region.event.toString(), 
                                      style: TextStyle(color: theme.whiteColor, fontSize: 10),
                                      textAlign: TextAlign.center,
                                  )
                               ) : null,
                          )
                      )
                  );
              }).toList(),
          ),
    );
  }
}