import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habitoo/features/habits/providers/habits_provider.dart';
import 'package:habitoo/features/habits/screens/my_habits_screen.dart';
import 'package:habitoo/models/habit_model.dart';

void main() {
  testWidgets('habits screen shows live habits and reports button', (
    WidgetTester tester,
  ) async {
    final fakeHabits = [
      HabitModel(
        id: 'test-1',
        name: 'Morning Run',
        category: 'Health',
        frequency: 'Daily',
        selectedDays: [0, 1, 2, 3, 4, 5, 6],
        reminderTime: '07:00',
        goalType: GoalType.simpleCheck,
        streak: 5,
        period: HabitPeriod.morning,
        accentColorValue: Colors.green.toARGB32(),
        iconCodePoint: Icons.directions_run.codePoint,
        isCompleted: false,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitsProvider.overrideWith((ref) => Stream.value(fakeHabits)),
        ],
        child: const MaterialApp(home: MyHabitsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Morning Run'), findsOneWidget);
    expect(find.text('View Reports'), findsOneWidget);
  });
}
