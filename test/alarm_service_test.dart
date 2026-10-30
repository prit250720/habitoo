import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habitoo/models/habit_model.dart';
import 'package:habitoo/services/alarm_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cancelAll clears all persisted alarm ids', () async {
    SharedPreferences.setMockInitialValues({
      'alarm_habit_map': jsonEncode({
        'habit-1': [101, 102],
        'habit-2': [203],
      }),
    });

    await AlarmService.cancelAll();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('alarm_habit_map'), isNull);
  });

  test('notification content uses the habit title and reminder message', () {
    final habit = HabitModel(
      id: 'habit-1',
      name: 'Drink water',
      category: 'Health',
      frequency: 'Daily',
      selectedDays: [0, 1, 2, 3, 4],
      reminderTime: '08:00',
      goalType: GoalType.simpleCheck,
      streak: 2,
      period: HabitPeriod.morning,
      accentColorValue: 0,
      iconCodePoint: 0,
      isCompleted: false,
    );

    final content = AlarmService.notificationContent(habit);

    expect(content['title'], 'Drink water');
    expect(content['body'], contains('Ready to check this off?'));
  });
}
