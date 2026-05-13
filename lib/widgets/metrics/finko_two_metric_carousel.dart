import 'package:flutter/material.dart';

/// Horizontal swipe hosting two [FinkoMetricCarouselCard] children.
class FinkoTwoMetricCarousel extends StatelessWidget {
  const FinkoTwoMetricCarousel({
    super.key,
    required this.first,
    required this.second,
    this.height = 244,
  });

  final Widget first;
  final Widget second;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: PageView(
        padEnds: true,
        controller: PageController(viewportFraction: 0.92),
        children: [
          SizedBox(height: height, width: double.infinity, child: first),
          SizedBox(height: height, width: double.infinity, child: second),
        ],
      ),
    );
  }
}
