import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SearchField extends StatefulWidget {
  final double height;
  final double width;
  final TextEditingController controller;
  final Function onTextChange;

  const SearchField({super.key, this.height = 0, this.width = 0, required this.controller, required this.onTextChange});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(),
      margin: EdgeInsets.symmetric(horizontal: widget.width != 0 ? 20 : 0),
      curve: Curves.easeInOutCirc,
      height: widget.height, 
      width: widget.width,
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
            child: Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                    event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  return KeyEventResult.handled; // swallows the event
                }
                return KeyEventResult.ignored; // lets everything else through
              },
              child: TextField(
                style: TextStyle(color: Colors.white, fontSize: 16),
                onChanged: (value) => widget.onTextChange(value),
                decoration: InputDecoration(
                  hintText: "Search for stock or browse...",
                  hintStyle: TextStyle(color: Colors.white, fontSize: 16),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      )
    );
  }
}