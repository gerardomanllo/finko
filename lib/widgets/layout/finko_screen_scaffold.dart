import 'package:flutter/material.dart';

/// Consistent title + actions for stack-pushed routes (outside tab shell).
class FinkoScreenScaffold extends StatelessWidget {
  const FinkoScreenScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: body,
    );
  }
}
