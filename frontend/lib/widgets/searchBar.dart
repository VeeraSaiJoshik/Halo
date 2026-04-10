import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/engine/clients/alpha_advantage_client.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/models/stocks.dart';
import 'package:frontend/services/app_event_bus.dart';
import 'package:frontend/widgets/SearchWidgets/SearchField.dart';
import 'package:frontend/widgets/SearchWidgets/StockBar.dart';

class CustomSearchBar extends ConsumerStatefulWidget {
  const CustomSearchBar({super.key});

  @override
  ConsumerState<CustomSearchBar> createState() => CustomSearchBarState();
}

class CustomSearchBarState extends ConsumerState<CustomSearchBar> {
  double searchBarWidth = 0;
  double searchBarHeight = 0;

  bool active = false;
  int activeIndex = 0;

  TextEditingController searchField = TextEditingController();

  late StreamSubscription<AppEvent> _sub;

  List<StockName> stockSearchResults = [
    StockName(symbol: "AAPL", name: "Apple", region: "US", matchScore: 0.95),
    StockName(symbol: "AAPL", name: "Apple", region: "US", matchScore: 0.95),
    StockName(symbol: "AAPL", name: "Apple", region: "US", matchScore: 0.95),
    StockName(symbol: "VFIAX", name: "Apple", region: "US", matchScore: 0.95),
    StockName(symbol: "GOOG", name: "Apple", region: "US", matchScore: 0.95)
  ];


  @override
  void initState() {
    super.initState();
    _sub = ref.read(appEventBusProvider).stream.listen(_onEvent);
  }

  void searchStocks(String query) {
    alphaAdvantageClient.searchStocks(query).then((results) {
      setState(() {
        stockSearchResults = results;
      });
    }).catchError((error) {
      print('Error searching stocks: $error');
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  void _onEvent(AppEvent event) {
    if (!active || stockSearchResults.isEmpty) return;
    setState(() {
      if (event == AppEvent.moveDown) {
        activeIndex = (activeIndex + 1).clamp(0, stockSearchResults.length - 1);
      } else if (event == AppEvent.moveUp) {
        activeIndex = (activeIndex - 1).clamp(0, stockSearchResults.length - 1);
      }
    });
  }

  void toggleSearchBarState() {
    active = !active;
    setState(() {
      if (active) {
        searchBarHeight = 55;
        searchBarWidth = 550;
        activeIndex = 0;
      } else {
        searchBarHeight = 0;
        searchBarWidth = 0;
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300), 
      curve: Curves.easeInOutCirc,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95), 
        borderRadius: BorderRadius.circular(10), 
        border: Border.all(color: Colors.white.withOpacity(active ? 0.35 : 0), width: 1.25, strokeAlign: BorderSide.strokeAlignOutside)
      ),
      width: searchBarWidth + 30,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SearchField(
            height: searchBarHeight,
            width: searchBarWidth,
            controller: searchField,
          ), 
          if(stockSearchResults.isNotEmpty) ...[
            Container(
              height: 1,
              width: 555, 
              color: Colors.white.withOpacity(0.45),
            ),
            StockBar(stocks: stockSearchResults, activeIndex: activeIndex)
          ]
        ],
      )
    );
  }
}