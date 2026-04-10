import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
        searchBarHeight = 55;
        searchBarWidth = 550;
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
      width: searchBarWidth, 
      height: searchBarHeight,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95), 
        borderRadius: BorderRadius.circular(10), 
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5, strokeAlign: BorderSide.strokeAlignOutside)
      ),
      padding: EdgeInsets.all(10),
      child: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 10,
          children: [
            FaIcon(
              FontAwesomeIcons.magnifyingGlass,
              color: Colors.white,
              size: 14,
            ),
            Expanded(
              child: TextField(
                style: TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Search for stock or browse...",
                  hintStyle: TextStyle(color: Colors.white, fontSize: 16),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}