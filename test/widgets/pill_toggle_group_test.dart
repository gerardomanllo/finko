import 'package:finko/widgets/layout/pill_toggle_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PillToggleGroup calls onChanged', (tester) async {
    String? last;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PillToggleGroup<String>(
            values: const ['a', 'b'],
            labelOf: (v) => v,
            selected: 'a',
            onChanged: (v) => last = v,
          ),
        ),
      ),
    );
    await tester.tap(find.text('b'));
    await tester.pump();
    expect(last, 'b');
  });
}
