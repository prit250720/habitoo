import 'package:flutter_test/flutter_test.dart';
import 'package:habitoo/features/progress/providers/progress_provider.dart';
import 'package:habitoo/models/habit_completion_model.dart';
import 'package:habitoo/models/habit_model.dart';

void main() {
  test('calculates live weekly and 30-day stats from completion history', () {
    final habits = [
      _habit(
        id: 'daily',
        frequency: 'Daily',
        selectedDays: const [0, 1, 2, 3, 4, 5, 6],
        createdAt: DateTime(2026, 1, 1),
        streak: 6,
      ),
      _habit(
        id: 'custom',
        frequency: 'Custom',
        selectedDays: const [0, 2],
        createdAt: DateTime(2026, 3, 3),
      ),
    ];
    final history = [
      _completion('daily', '2026-03-02'),
      _completion('daily', '2026-03-03'),
      _completion('daily', '2026-03-04'),
      _completion('custom', '2026-03-04'),
    ];

    final stats = ProgressStats.calculate(
      habits: habits,
      completionHistory: history,
      asOf: DateTime(2026, 3, 4),
    );

    expect(stats.longestStreakDays, 6);
    expect(stats.totalCompleted, 4);
    expect(stats.weeklyActivity, hasLength(7));
    expect(stats.weeklyActivity[0].completionPercent, 100);
    expect(stats.weeklyActivity[1].completionPercent, 100);
    expect(stats.weeklyActivity[2].completionPercent, 100);
    expect(stats.weeklyActivity[2].isHighlight, isTrue);
    expect(stats.heatmapDays, hasLength(30));
    expect(stats.heatmapDays.last.dateLabel, 'Mar 4');
    expect(stats.heatmapDays.last.completedHabits, 2);
    expect(stats.heatmapDays.last.intensity, HeatmapIntensity.top);
    expect(stats.activeDays, 3);
    expect(stats.consistencyPercent, 13);
  });

  test('does not count completions on unscheduled days', () {
    final stats = ProgressStats.calculate(
      habits: [
        _habit(
          id: 'weekly',
          frequency: 'Custom',
          selectedDays: const [0],
        ),
      ],
      completionHistory: [_completion('weekly', '2026-03-04')],
      asOf: DateTime(2026, 3, 4),
    );

    expect(stats.weeklyActivity[2].completionPercent, 0);
    expect(stats.activeDays, 0);
    expect(stats.consistencyPercent, 0);
  });
}

HabitModel _habit({
  required String id,
  required String frequency,
  required List<int> selectedDays,
  DateTime? createdAt,
  int streak = 0,
}) {
  return HabitModel(
    id: id,
    name: id,
    category: 'Health',
    frequency: frequency,
    selectedDays: selectedDays,
    reminderTime: '08:00',
    goalType: GoalType.simpleCheck,
    streak: streak,
    period: HabitPeriod.morning,
    accentColorValue: 0,
    iconCodePoint: 0,
    isCompleted: false,
    createdAt: createdAt,
  );
}

HabitCompletionModel _completion(String habitId, String dateKey) {
  return HabitCompletionModel(
    habitId: habitId,
    dateKey: dateKey,
    wasCompleted: true,
    completedAt: DateTime.parse(dateKey),
    autoCompleted: false,
  );
}
