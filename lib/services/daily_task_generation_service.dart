import 'dart:math';

import '../models/habit_model.dart';
import '../models/daily_task_model.dart';

/// Generates a small personalized daily task set for a user based on their
/// habits and any available health context.
class DailyTaskGenerationService {
  static final Random _random = Random();
  static const _hydrationPrompts = [
    _TaskPrompt(
      'Hydration check-in',
      'Drink a full glass of water and reset your focus for the next block.',
    ),
    _TaskPrompt(
      'Start hydrated',
      'Have a glass of water before moving on to your next activity.',
    ),
    _TaskPrompt(
      'Take a water break',
      'Pause for a drink of water and give yourself a moment to reset.',
    ),
    _TaskPrompt(
      'Refill and reset',
      'Refill your water and keep it nearby while you work.',
    ),
    _TaskPrompt(
      'Hydration check',
      'Check in with yourself and have some water if you need it.',
    ),
    _TaskPrompt(
      'Sip with intention',
      'Take a mindful water break before your next task.',
    ),
    _TaskPrompt(
      'Midday water break',
      'Step away briefly for a glass of water and a fresh start.',
    ),
  ];
  static const _movementPrompts = [
    _TaskPrompt(
      'Move for 10 minutes',
      'Take a brisk walk or complete a quick mobility session.',
    ),
    _TaskPrompt(
      'Take a brisk walk',
      'Get outside or walk indoors for a short movement break.',
    ),
    _TaskPrompt(
      'Stretch and reset',
      'Spend a few minutes stretching to loosen up and recharge.',
    ),
    _TaskPrompt(
      'Add a little movement',
      'Take the stairs or walk around for a few minutes.',
    ),
    _TaskPrompt(
      'Try a quick mobility break',
      'Move your shoulders, hips, and back through a few comfortable stretches.',
    ),
    _TaskPrompt(
      'Get your steps in',
      'Take a short walk and build some movement into your day.',
    ),
    _TaskPrompt(
      'Wake up your body',
      'Do a few minutes of light movement at a pace that feels good.',
    ),
  ];
  static const _sleepPrompts = [
    _TaskPrompt(
      'Protect your sleep routine',
      'Create a calm bedtime routine so your recovery gets a strong start.',
    ),
    _TaskPrompt(
      'Prepare for better sleep',
      'Set aside a few screen-free minutes to wind down before bed.',
    ),
    _TaskPrompt(
      'Make room for rest',
      'Choose a relaxing activity to help you ease into bedtime.',
    ),
    _TaskPrompt(
      'Set a sleep-friendly routine',
      'Dim the lights and give yourself time to settle before bed.',
    ),
    _TaskPrompt(
      'Wind down for sleep',
      'Put away screens a little earlier and let your mind slow down.',
    ),
    _TaskPrompt(
      'Give sleep a head start',
      'Get your bedtime essentials ready so the end of the day feels calmer.',
    ),
    _TaskPrompt(
      'Build a calmer bedtime',
      'Try a quiet, relaxing routine before you turn in for the night.',
    ),
  ];
  static const _mindfulnessPrompts = [
    _TaskPrompt(
      'Mindful breathing break',
      'Spend 5 minutes breathing slowly and reset your stress before your next task.',
    ),
    _TaskPrompt(
      'Pause and breathe',
      'Take five slow breaths and notice how you feel in this moment.',
    ),
    _TaskPrompt(
      'Take a mindful pause',
      'Step away for a few minutes and focus on your breathing.',
    ),
    _TaskPrompt(
      'Reset your focus',
      'Close your eyes briefly and take a few calm, steady breaths.',
    ),
    _TaskPrompt(
      'Find a quiet moment',
      'Give yourself five minutes without distractions to recharge.',
    ),
    _TaskPrompt(
      'Practice being present',
      'Notice what is around you and take a few slow breaths.',
    ),
    _TaskPrompt(
      'Make space to unwind',
      'Pause between tasks and relax your shoulders as you breathe.',
    ),
  ];
  static const _habitPrompts = [
    _TaskPrompt('Complete your main habit', 'Keep your streak alive'),
    _TaskPrompt('Make progress on your main habit', 'Build on your routine'),
    _TaskPrompt(
      'Show up for your main habit',
      'Consistency starts with showing up',
    ),
    _TaskPrompt('Take one step on your main habit', 'Every small step counts'),
    _TaskPrompt(
      'Keep your habit streak moving',
      'Give your routine some attention',
    ),
    _TaskPrompt(
      'Make time for your main habit',
      'Protect a little time for your goal',
    ),
    _TaskPrompt('Finish a habit task today', 'Turn your intention into action'),
  ];

  static List<DailyTaskModel> generateTasks({
    required String uid,
    required List<HabitModel> habits,
    Map<String, dynamic>? userData,
    DateTime? date,
  }) {
    final now = date ?? DateTime.now();
    final dateKey = _dateKey(now);
    final promptIndex = _dayOfYear(now) % _hydrationPrompts.length;
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
      title: _hydrationPrompts[promptIndex].title,
      description: hydrationGoal != null
          ? 'Aim for $hydrationGoal glasses of water today and keep your energy steady.'
          : _hydrationPrompts[promptIndex].description,
      habitId: null,
      category: 'Hydration',
      xp: _randomXP(),
    );
    tasks.add(hydrationTask);

    final movementTask = _buildTask(
      uid: uid,
      dateKey: dateKey,
      title: _movementPrompts[promptIndex].title,
      description: activityLevel.isNotEmpty
          ? 'A short movement session fits your $activityLevel routine and keeps momentum going.'
          : _movementPrompts[promptIndex].description,
      habitId: fitnessHabit.id.isNotEmpty ? fitnessHabit.id : null,
      category: 'Fitness',
      xp: _randomXP(),
    );
    tasks.add(movementTask);

    final sleepTask = _buildTask(
      uid: uid,
      dateKey: dateKey,
      title: _sleepPrompts[promptIndex].title,
      description: healthGoal.isNotEmpty
          ? 'Support your goal to $healthGoal by keeping tonight calm and screen-free before bed.'
          : _sleepPrompts[promptIndex].description,
      habitId: null,
      category: 'Sleep',
      xp: _randomXP(),
    );
    tasks.add(sleepTask);

    final mindfulnessTask = _buildTask(
      uid: uid,
      dateKey: dateKey,
      title: _mindfulnessPrompts[promptIndex].title,
      description: _mindfulnessPrompts[promptIndex].description,
      habitId: null,
      category: 'Mindfulness',
      xp: _randomXP(),
    );
    tasks.add(mindfulnessTask);

    final habitTask = _buildTask(
      uid: uid,
      dateKey: dateKey,
      title: habits.isNotEmpty
          ? _habitPrompts[promptIndex].title
          : 'Start a small win',
      description: habits.isNotEmpty
          ? '${_habitPrompts[promptIndex].description} with ${habits.first.name.toLowerCase()} and make today count.'
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

  static int _dayOfYear(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.difference(DateTime(date.year)).inDays;
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _TaskPrompt {
  const _TaskPrompt(this.title, this.description);

  final String title;
  final String description;
}
