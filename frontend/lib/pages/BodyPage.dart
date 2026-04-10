import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/controllers/AppController.dart';
import 'package:frontend/pages/views/AISummaryView.dart';
import 'package:frontend/pages/views/SearchView.dart';
import 'package:frontend/pages/views/WebView.dart';
import 'package:frontend/widgets/OverlayWidgets/BottomNavModal.dart';

class BodyPageDart extends ConsumerStatefulWidget {
  final AppController webController;
  const BodyPageDart({super.key, required this.webController});

  @override
  ConsumerState<BodyPageDart> createState() => _BodyPageDartState();
}

class _BodyPageDartState extends ConsumerState<BodyPageDart> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(11.5, 0, 11.5, 11.5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.all(5),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: Row(
                    children: [
                      widget.webController.getCurrentTab() == null ? Expanded(
                        child: Container(height: double.infinity),
                      ) :
                      Expanded(
                        child:CustomWebView(controller: widget.webController.getCurrentTab()!.webController!)
                      )
                    ],
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
