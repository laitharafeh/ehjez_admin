import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Ehjez Admin'))),
    );
    expect(find.text('Ehjez Admin'), findsOneWidget);
  });
}
