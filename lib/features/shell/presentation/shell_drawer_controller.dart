import 'package:flutter/widgets.dart';

class ShellDrawerController extends InheritedWidget {
  const ShellDrawerController({
    super.key,
    required super.child,
    required this.openDrawer,
  });

  final VoidCallback openDrawer;

  static ShellDrawerController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellDrawerController>();
  }

  static void open(BuildContext context) {
    maybeOf(context)?.openDrawer();
  }

  @override
  bool updateShouldNotify(covariant ShellDrawerController oldWidget) {
    return oldWidget.openDrawer != openDrawer;
  }
}
