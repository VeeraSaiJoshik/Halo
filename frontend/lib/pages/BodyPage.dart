import 'package:flutter/material.dart';
import 'package:frontend/controllers/AppController.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/pages/views/AISummaryView.dart';
import 'package:frontend/pages/views/SearchView.dart';
import 'package:frontend/pages/views/WebView.dart';
import 'package:frontend/widgets/OverlayWidgets/BottomNavModal.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BodyPageDart extends StatefulWidget {
  final AppController webController;
  const BodyPageDart({super.key, required this.webController});

  @override
  State<BodyPageDart> createState() => _BodyPageDartState();
}

class _BodyPageDartState extends State<BodyPageDart> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      padding: EdgeInsets.all(7.5),
      decoration: BoxDecoration(
        color: CustomColors.primary,
        borderRadius: BorderRadius.circular(10)
      ),
      child: Stack(
        children: [
          Container(
            width: double.infinity, 
            height: double.infinity,
            child: Row(
              children: [
                widget.webController.getCurrentTab() == null ? Container() : 
                Expanded(
                  child: widget.webController.getCurrentTab()!.currentPage == AppPage.STOCKS ?  
                      CustomWebView(controller: widget.webController.getCurrentTab()!.webController!) : 
                    widget.webController.getCurrentTab()!.currentPage == AppPage.BROWSE ?  
                      SearchView() : 
                      AISummaryView()
                )
              ],
            ),
          ), 
          widget.webController.getCurrentTab() == null ? Container() : Positioned(
            left: 0, 
            right: 0,
            bottom: 8,
            child:Center(
              child: BottomNavModal(controller: widget.webController,),
            ),
          ),
        ],
      )
    );
  }
}