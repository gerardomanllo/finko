import 'package:finko/widgets/surfaces/finko_paper_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FinkoPaperCard renders child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FinkoPaperCard(child: Text('inside'))),
      ),
    );
    expect(find.text('inside'), findsOneWidget);
  });
}
