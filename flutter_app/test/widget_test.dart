// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: AjiTfarrajApp(),
      ),
    );

    // Verify that app loads (splash screen or any initial widget)
    await tester.pump();
    
    // Basic smoke test - app should build without errors
    expect(find.byType(AjiTfarrajApp), findsOneWidget);
  });
}
