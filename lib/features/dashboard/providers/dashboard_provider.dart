import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/habits/providers/habits_provider.dart';

// ---------------------------------------------------------------------------
// Dashboard state — derived from the live habitsProvider stream
// ---------------------------------------------------------------------------

class DashboardState {
  const DashboardState({required this.habits});

  final List<HabitModel> habits;

  List<HabitModel> get todaysHabits {
    final today = DateTime.now();
    final todayIndex = today.weekday - 1;
    return habits
        .where(
          (habit) =>
              habit.frequency == 'Daily' ||
              habit.selectedDays.contains(todayIndex),
        )
        .toList();
  }

  int get completedCount => todaysHabits.where((h) => h.isCompleted).length;
  int get totalCount => todaysHabits.length;

  double get progressPercent {
    if (totalCount == 0) return 0;
    return ((completedCount / totalCount) * 100).clamp(0.0, 100.0).roundToDouble();
  }
}

/// Derives dashboard state directly from the shared [habitsProvider] stream
/// so both screens always show the same data without duplication.
final dashboardProvider = Provider<AsyncValue<DashboardState>>((ref) {
  final habitsAsync = ref.watch(habitsProvider);
  return habitsAsync.whenData((habits) => DashboardState(habits: habits));
});

/// Convenience provider that returns today's habits (all habits for now;
/// can be filtered by date once per-day completion tracking is added).
final todaysHabitsProvider = Provider<AsyncValue<List<HabitModel>>>((ref) {
  final habitsAsync = ref.watch(habitsProvider);
  return habitsAsync.whenData((habits) => habits);
});
