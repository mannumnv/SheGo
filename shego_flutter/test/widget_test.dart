import 'package:flutter_test/flutter_test.dart';

import 'package:shego_flutter/main.dart';

void main() {
  testWidgets('SheGo splash renders brand tagline', (WidgetTester tester) async {
    await tester.pumpWidget(const SheGoApp());

    expect(find.text('Ride Freely. Ride Safely.'), findsOneWidget);
  });

  testWidgets('SheGo navigates from splash to signup selection', (WidgetTester tester) async {
    await tester.pumpWidget(const SheGoApp());
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    expect(find.text('Continue as Rider'), findsOneWidget);
    expect(find.text('Continue as Driver'), findsOneWidget);
  });
}
