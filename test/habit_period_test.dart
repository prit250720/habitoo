import 'package:flutter_test/flutter_test.dart';
import 'package:habitoo/models/habit_model.dart';

void main() {
  test('selects a habit period from its reminder time', () {
    expect(habitPeriodForReminderTime('10:00'), HabitPeriod.morning);
    expect(habitPeriodForReminderTime('12:00'), HabitPeriod.evening);
    expect(habitPeriodForReminderTime('19:59'), HabitPeriod.evening);
    expect(habitPeriodForReminderTime('20:00'), HabitPeriod.night);
    expect(habitPeriodForReminderTime('04:59'), HabitPeriod.night);
  });

  test('stores night period in firestore payload', () {
    final habit = HabitModel(
      id: '1',
      name: 'Test',
      category: 'Health',
      frequency: 'Daily',
      selectedDays: [0, 1, 2, 3, 4],
      reminderTime: '20:00',
      goalType: GoalType.simpleCheck,
      streak: 0,
      period: HabitPeriod.night,
      accentColorValue: 0,
      iconCodePoint: 0,
      isCompleted: false,
    );

    expect(habit.toFirestore()['period'], 'night');
  });

  test('marks completion only for the selected date', () {
    final habit = HabitModel(
      id: '2',
      name: 'Test',
      category: 'Health',
      frequency: 'Daily',
      selectedDays: [0, 1, 2, 3, 4],
      reminderTime: '08:00',
      goalType: GoalType.simpleCheck,
      streak: 1,
      period: HabitPeriod.morning,
      accentColorValue: 0,
      iconCodePoint: 0,
      isCompleted: false,
      completedOnDate: '2026-07-24',
    );

    expect(habit.isCompletedForDate(DateTime(2026, 7, 24)), isTrue);
    expect(habit.isCompletedForDate(DateTime(2026, 7, 25)), isFalse);
  });
}
