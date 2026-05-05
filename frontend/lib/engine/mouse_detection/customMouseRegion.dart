import 'package:flutter/material.dart';
import 'package:frontend/services/app_event_bus.dart';

class CustomMouseRegion {
    /// Size of the region. Values < 1 are treated as fractions of screen
    /// width/height; values >= 1 are treated as absolute pixel values.
    double r_width;
    double r_height;

    /// Raw fractional position (0–1). Ignored when [alignment] is provided.
    double r_x;
    double r_y;

    /// When set, overrides [r_x]/[r_y] and positions the region using Flutter's
    /// standard [Alignment] coordinates:
    ///   x: -1 = left edge,  0 = center,  1 = right edge
    ///   y: -1 = top edge,   0 = center,  1 = bottom edge
    ///
    /// Examples:
    ///   Alignment.centerLeft   → flush left, vertically centered
    ///   Alignment.topCenter    → flush top,  horizontally centered
    ///   Alignment.bottomRight  → bottom-right corner
    Alignment? alignment;

    /// When > 0, vertical alignment is computed relative to the area BELOW
    /// this offset (e.g. pass the title-bar height so that
    /// [Alignment.centerLeft] centres within the content area, not the full
    /// screen).  Has no effect when [alignment] is null.
    double topBarOffset;

    AppEvent event;

    CustomMouseRegion({
        required this.r_width,
        required this.r_height,
        this.r_x = 0,
        this.r_y = 0,
        this.alignment,
        this.topBarOffset = 0,
        required this.event,
    });

    Widget getPositioned(BuildContext context, Widget child) {
        final width  = MediaQuery.of(context).size.width;
        final height = MediaQuery.of(context).size.height;

        final double resolvedWidth  = r_width  < 1 ? r_width  * width  : r_width;
        final double resolvedHeight = r_height < 1 ? r_height * height : r_height;

        if (alignment != null) {
            // Map alignment x [-1, 1] → [0, width - resolvedWidth]
            final double left = (alignment!.x + 1) / 2 * (width - resolvedWidth);

            // Map alignment y [-1, 1] → [topBarOffset, height - resolvedHeight]
            // topBarOffset shrinks the available vertical space so that y=0
            // (center) lands in the middle of the content area, not the full screen.
            final double availableHeight = height - topBarOffset - resolvedHeight;
            final double top = topBarOffset + (alignment!.y + 1) / 2 * availableHeight;

            return Positioned(
                left:   left,
                top:    top,
                width:  resolvedWidth,
                height: resolvedHeight,
                child:  child,
            );
        }

        // Legacy r_x / r_y path
        final bool isLeft = r_x < 0.5;
        final bool isTop  = r_y < 0.5;

        final double resolvedX = r_x * width;
        final double resolvedY = r_y * height;

        if (isLeft && isTop) {
            return Positioned(left: resolvedX,          top:    resolvedY,           width: resolvedWidth, height: resolvedHeight, child: child);
        } else if (!isLeft && isTop) {
            return Positioned(right: width - resolvedX, top:    resolvedY,           width: resolvedWidth, height: resolvedHeight, child: child);
        } else if (isLeft && !isTop) {
            return Positioned(left: resolvedX,          bottom: height - resolvedY,  width: resolvedWidth, height: resolvedHeight, child: child);
        } else {
            return Positioned(right: width - resolvedX, bottom: height - resolvedY,  width: resolvedWidth, height: resolvedHeight, child: child);
        }
    }
}

const double kTitleBarHeight = 40;

List<CustomMouseRegion> regions = [
    CustomMouseRegion(r_width: 15, r_height: 200, alignment: Alignment.centerLeft,  topBarOffset: kTitleBarHeight, event: AppEvent.leftAdd),
    CustomMouseRegion(r_width: 15, r_height: 200, alignment: Alignment.centerRight, topBarOffset: kTitleBarHeight, event: AppEvent.rightAdd),
];
