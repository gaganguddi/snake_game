import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:snake_game/main.dart';

void main() {
  testWidgets('Snake Game loads and shows title', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const SnakeApp());

    // Check if the app bar title "Snake" is found
    expect(find.text('Snake'), findsOneWidget);

    // Check if initial score text is visible
    expect(find.textContaining('Score:'), findsOneWidget);
  });
}
