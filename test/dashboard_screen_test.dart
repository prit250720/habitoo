import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habitoo/features/dashboard/screens/dashboard_screen.dart';
import 'package:habitoo/features/habits/providers/habits_provider.dart';

void main() {
  testWidgets(
    'dashboard screen shows a floating action button for adding habits',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override the habits stream with a test stream
            habitsProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    },
  );
}
