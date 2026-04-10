import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  const CustomSearchBar({super.key});

  @override
  State<CustomSearchBar> createState() => CustomSearchBarState();
}

class CustomSearchBarState extends State<CustomSearchBar> {
  double searchBarWidth = 0;
  double searchBarHeight = 0;

  bool active = false;

  void toggleSearchBarState() {
    active = !active;
    setState(() {
      if(active) {
        searchBarHeight = 40;
        searchBarWidth = 400;
      } else {
        searchBarHeight = 0;
        searchBarWidth = 0;
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500), 
      curve: Curves.bounceInOut,
      child: Container(
        width: searchBarWidth, 
        height: searchBarHeight,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75), 
          borderRadius: BorderRadius.circular(10), 
          //border: Border.all
        )
      ),
    );
  }
}