import 'package:flutter/material.dart';

/// Horizontal swipe hosting two [FinkoMetricCarouselCard] children, with inset
/// between cards, a peek of the adjacent page, and dot pagination under the chart area.
class FinkoTwoMetricCarousel extends StatefulWidget {
  const FinkoTwoMetricCarousel({
    super.key,
    required this.first,
    required this.second,
    this.height = 244,
    this.viewportFraction = 0.88,
    this.cardHorizontalInset = 8,
  });

  final Widget first;
  final Widget second;
  final double height;

  /// Each page width as a fraction of the viewport; slightly below 1.0 keeps the next card barely visible.
  final double viewportFraction;

  /// Horizontal padding inside each page so neighboring cards do not visually touch.
  final double cardHorizontalInset;

  @override
  State<FinkoTwoMetricCarousel> createState() => _FinkoTwoMetricCarouselState();
}

class _FinkoTwoMetricCarouselState extends State<FinkoTwoMetricCarousel> {
  static const int _pageCount = 2;

  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: widget.viewportFraction);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget paddedPage(Widget child) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.cardHorizontalInset),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: child,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView(
            controller: _pageController,
            padEnds: true,
            onPageChanged: (int index) {
              setState(() => _pageIndex = index.clamp(0, _pageCount - 1));
            },
            children: [paddedPage(widget.first), paddedPage(widget.second)],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(_pageCount, (int i) {
            final selected = i == _pageIndex;
            return Padding(
              padding: EdgeInsets.only(left: i > 0 ? 6 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? scheme.primary
                      : scheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
