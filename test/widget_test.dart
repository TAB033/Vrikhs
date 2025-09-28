// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:graph_builder/main.dart';

void main() {
  testWidgets('Graph Builder app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GraphBuilderApp());

    // Verify that the app loads with the Graph Builder title
    expect(find.text('Graph Builder'), findsOneWidget);
    
    // Verify that the root node "1" is present
    expect(find.text('1'), findsOneWidget);
  });
}
