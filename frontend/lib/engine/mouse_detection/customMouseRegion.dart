import 'package:flutter/material.dart';
import 'package:frontend/services/app_event_bus.dart';

class CustomMouseRegion {
    double r_width;
    double r_height;
    double r_x;
    double r_y;
    AppEvent event;

    Widget getPositioned(BuildContext context, Widget child) {
        final width = MediaQuery.of(context).size.width;
        final height = MediaQuery.of(context).size.height;

        final bool isLeft = r_x < 0.5;
        final bool isTop = r_y < 0.5;

        final double resolvedWidth  = r_width  < 1 ? (r_width  + 0.01) * width  : r_width;
        final double resolvedHeight = r_height < 1 ? (r_height + 0.01) * height : r_height;
        final double resolvedX = r_x * width;
        final double resolvedY = r_y * height;

        if (isLeft && isTop) {
            return Positioned(
                left: resolvedX,
                top: resolvedY,
                width: resolvedWidth,
                height: resolvedHeight,
                child: child
            );
        } else if (!isLeft && isTop) {
            return Positioned(
                right: width - resolvedX,
                top: resolvedY,
                width: resolvedWidth,
                height: resolvedHeight,
                child: child
            );
        } else if (isLeft && !isTop) {
            return Positioned(
                left: resolvedX,
                bottom: height - resolvedY,
                width: resolvedWidth,
                height: resolvedHeight,
                child: child
            );
        } else {
            return Positioned(
                right: width - resolvedX,
                bottom: height - resolvedY,
                width: resolvedWidth,
                height: resolvedHeight,
                child: child
            );
        }
    }

    CustomMouseRegion({
        required this.r_width, 
        required this.r_height, 
        required this.r_x, 
        required this.r_y, 
        required this.event
    });
}

List<CustomMouseRegion> regions = [
    CustomMouseRegion(r_width: 150, r_height: 0.99, r_x: 0, r_y: 0, event: AppEvent.leftAdd),
    CustomMouseRegion(r_width: 150, r_height: 0.99, r_x: 1, r_y: 0, event: AppEvent.rightAdd),
];