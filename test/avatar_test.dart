import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habitoo/shared/widgets/app_avatar.dart';

void main() {
  testWidgets('shows a fallback icon when the avatar image cannot load', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppAvatar(
              imageUrl: 'https://example.invalid/avatar.jpg',
              radius: 24,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person), findsOneWidget);
  });
}
