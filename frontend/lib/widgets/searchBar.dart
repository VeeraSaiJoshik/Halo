import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/controllers/AppController.dart';
import 'package:frontend/engine/clients/alpha_advantage_client.dart';
import 'package:frontend/engine/clients/yahoo_finance_client.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/models/stocks.dart';
import 'package:frontend/services/app_event_bus.dart';
import 'package:frontend/widgets/SearchWidgets/SearchField.dart';
import 'package:frontend/widgets/SearchWidgets/StockBar.dart';

class CustomSearchBar extends ConsumerStatefulWidget {
  AppController appController;
  CustomSearchBar({super.key, required this.appController});

  @override
  ConsumerState<CustomSearchBar> createState() => CustomSearchBarState();
}

class CustomSearchBarState extends ConsumerState<CustomSearchBar> {
  double searchBarWidth = 0;
  double searchBarHeight = 0;

  bool active = false;
  bool animationInProgress = false;
  int activeIndex = 0;

  TextEditingController searchField = TextEditingController();
  FocusNode searchFocus = FocusNode();

  late StreamSubscription<AppEvent> _sub;

  List<StockName> stockSearchResults = [];


  @override
  void initState() {
    super.initState();
    _sub = ref.read(appEventBusProvider).stream.listen(_onEvent);
  }

  void searchStocks(String query) {
    yahooFinanceClient.searchStocks(query).then((results) {
      setState(() {
        stockSearchResults = results;
      });
    }).catchError((error) {
      print('Error searching stocks: $error');
    });
  }

  @override
  void dispose() {
    searchFocus.dispose();
    searchField.dispose();
    _sub.cancel();
    super.dispose();
  }

  void _onEvent(AppEvent event) {
    if (event == AppEvent.openSearch) {
      toggleSearchBarState();
      return;
    }
    if (!active || stockSearchResults.isEmpty) return;
    setState(() {
      if (event == AppEvent.moveDown) {
        activeIndex = (activeIndex + 1).clamp(0, stockSearchResults.length - 1);
      } else if (event == AppEvent.moveUp) {
        activeIndex = (activeIndex - 1).clamp(0, stockSearchResults.length - 1);
      } else if (event == AppEvent.select) {
        if (stockSearchResults.isNotEmpty) {
          final selectedStock = stockSearchResults[activeIndex];
          widget.appController.newTab(selectedStock);
          toggleSearchBarState();
        }
      }
    });
  }

  void toggleSearchBarState() {
    active = !active;
    if (active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => searchFocus.requestFocus());
    } else {
      searchFocus.unfocus();
    }
    setState(() {
      if (active) {
        searchBarHeight = 55;
        searchBarWidth = 550;
        activeIndex = 0;
        searchField.clear();
        stockSearchResults = [];
        ref.read(appEventBusProvider).emit(AppEvent.searchOpened);
      } else {
        searchBarHeight = 0;
        searchBarWidth = 0;
        searchField.clear();
        stockSearchResults = [];
        ref.read(appEventBusProvider).emit(AppEvent.searchClosed);
      }
      animationInProgress = true;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300), 
      onEnd: () => {
        setState(() => animationInProgress = false)
      },
      curve: Curves.easeInOutCirc,
      clipBehavior: Clip.hardEdge,
      margin: EdgeInsets.only(
        top: searchBarHeight == 0 ? MediaQuery.of(context).size.height * 0.05 : 0
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(active ? 0.35 : 0), width: 1.25, strokeAlign: BorderSide.strokeAlignOutside)
      ),
      width: searchBarWidth + 30,
      child: AnimatedOpacity(
        opacity: animationInProgress ? 0 : 1,
        duration: Duration(milliseconds: 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SearchField(
              height: searchBarHeight,
              width: searchBarWidth,
              controller: searchField,
              focusNode: searchFocus,
              onTextChange: searchStocks,
            ), 
            if(stockSearchResults.isNotEmpty) ...[
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.45),
              ),
              StockBar(stocks: stockSearchResults, activeIndex: activeIndex)
            ]
          ],
        ),
      )
    );
  }
}