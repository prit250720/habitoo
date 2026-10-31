import 'package:flutter_test/flutter_test.dart';
import 'package:habitoo/models/habit_model.dart';
import 'package:habitoo/services/daily_task_generation_service.dart';

void main() {
  group('DailyTaskGenerationService', () {
    test('generates five personalized tasks from habits and health data', () {
      final habits = <HabitModel>[
        const HabitModel(
          id: 'habit-1',
          name: 'Morning Run',
          category: 'Fitness',
          frequency: 'Daily',
          selectedDays: [0, 1, 2, 3, 4],
          reminderTime: '07:00',
          goalType: GoalType.simpleCheck,
          streak: 4,
          period: HabitPeriod.morning,
          accentColorValue: 0xFF4CAF50,
          iconCodePoint: 0xE1A4,
          isCompleted: false,
        ),
      ];

      final tasks = DailyTaskGenerationService.generateTasks(
        uid: 'user-1',
        habits: habits,
        userData: {
          'healthGoal': 'sleep better',
          'hydrationGoal': 8,
          'activityLevel': 'active',
        },
        date: DateTime(2026, 7, 31),
      );

      expect(tasks, hasLength(5));
      expect(tasks.every((task) => task.date == '2026-07-31'), isTrue);
      expect(tasks.every((task) => task.completed == false), isTrue);
      expect(tasks.every((task) => task.xp >= 1 && task.xp <= 15), isTrue);
      expect(tasks.any((task) => task.category == 'Fitness'), isTrue);
      expect(tasks.any((task) => task.category == 'Hydration'), isTrue);
      expect(
        tasks.any((task) => task.title.toLowerCase().contains('sleep')),
        isTrue,
      );
    });

    test('rotates task prompts on consecutive days and is stable per date', () {
      List<String> titlesFor(DateTime date) {
        return DailyTaskGenerationService.generateTasks(
          uid: 'user-1',
          habits: const [],
          date: date,
        ).map((task) => task.title).toList();
      }

      final today = DateTime(2026, 7, 31);
      final todayTitles = titlesFor(today);

      expect(titlesFor(today.add(const Duration(days: 1))), isNot(todayTitles));
      expect(titlesFor(today), todayTitles);
    });
  });
}
