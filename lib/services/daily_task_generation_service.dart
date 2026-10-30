import 'dart:math';

import '../models/habit_model.dart';
import '../models/daily_task_model.dart';

/// Generates a small personalized daily task set for a user based on their
/// habits and any available health context.
class DailyTaskGenerationService {
  static final Random _random = Random();

  static List<DailyTaskModel> generateTasks({
    required String uid,
    required List<HabitModel> habits,
    Map<String, dynamic>? userData,
    DateTime? date,
  }) {
    final now = date ?? DateTime.now();
    final dateKey = _dateKey(now);
    final userPayload = userData ?? const <String, dynamic>{};
    final healthGoal = userPayload['healthGoal']?.toString() ?? '';
    final hydrationGoal = userPayload['hydrationGoal'];
    final activityLevel = userPayload['activityLevel']?.toString() ?? '';

    final tasks = <DailyTaskModel>[];

    final fitnessHabit = habits.firstWhere(
      (habit) =>
          habit.category.toLowerCase().contains('fitness') ||
          habit.name.toLowerCase().contains('run') ||
          habit.name.toLowerCase().contains('workout'),
      orElse: () => habits.isNotEmpty
          ? habits.first
          : const HabitModel(
              id: '',
              name: 'Move your body',
              category: 'Fitness',
              frequency: 'Daily',
              selectedDays: [0, 1, 2, 3, 4],
              reminderTime: '08:00',
              goalType: GoalType.simpleCheck,
              streak: 0,
              period: HabitPeriod.morning,
              accentColorValue: 0xFF4CAF50,
              iconCodePoint: 0xE1A4,
              isCompleted: false,
            ),
    );

    final hydrationTask = _buildTask(
      uid: uid,
      dateKey: dateKey,
      title: 'Hydration check-in',
      description: hydrationGoal != null
          ? 'Aim for $hydrationGoal glasses of water today and keep your energy steady.'
          : 'Drink a full glass of water and reset your focus for the next block.',
      habitId: null,
      category: 'Hydration',
      xp: _randomXP(),
    );
    tasks.add(hydrationTask);

    final movementTask = _buildTask(
      uid: uid,
      dateKey: dateKey,
      title: 'Move for 10 minutes',
      description: activityLevel.isNotEmpty
          ? 'A short movement session fits your $activityLevel routine and keeps momentum going.'
          : 'Take a brisk walk or complete a quick mobility session.',
      habitId: fitnessHabit.id.isNotEmpty ? fitnessHabit.id : null,
      category: 'Fitness',
      xp: _randomXP(),
    );
    tasks.add(movementTask);

    final sleepTask = _buildTask(
      uid: uid,
      dateKey: dateKey,
      title: 'Protect your sleep routine',
      description: healthGoal.isNotEmpty
          ? 'Support your goal to $healthGoal by keeping tonight calm and screen-free before bed.'
          : 'Create a calm bedtime routine so your recovery gets a strong start.',
      habitId: null,
      category: 'Sleep',
      xp: _randomXP(),
    );
    tasks.add(sleepTask);

    final mindfulnessTask = _buildTask(
      uid: uid,
      dateKey: dateKey,
      title: 'Mindful breathing break',
      description:
          'Spend 5 minutes breathing slowly and reset your stress before your next task.',
      habitId: null,
      category: 'Mindfulness',
      xp: _randomXP(),
    );
    tasks.add(mindfulnessTask);

    final habitTask = _buildTask(
      uid: uid,
      dateKey: dateKey,
      title: habits.isNotEmpty
          ? 'Complete your main habit'
          : 'Start a small win',
      description: habits.isNotEmpty
          ? 'Keep your streak alive with ${habits.first.name.toLowerCase()} and make today count.'
          : 'Pick one simple action you can finish in the next 10 minutes.',
      habitId: habits.isNotEmpty ? habits.first.id : null,
      category: habits.isNotEmpty ? habits.first.category : 'Health',
      xp: _randomXP(),
    );
    tasks.add(habitTask);

    return tasks;
  }

  static DailyTaskModel _buildTask({
    required String uid,
    required String dateKey,
    required String title,
    required String description,
    required String? habitId,
    required String category,
    required int xp,
  }) {
    final now = DateTime.now();
    return DailyTaskModel(
      id: '',
      taskId: '${uid}_${dateKey}_${category.toLowerCase()}',
      userId: uid,
      title: title,
      description: description,
      habitId: habitId,
      category: category,
      date: dateKey,
      xp: xp,
      completed: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  static int _randomXP() => 1 + _random.nextInt(15);

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
