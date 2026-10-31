import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/habit_repository.dart';
import '../../../models/habit_completion_model.dart';
import '../../../models/habit_model.dart';
import '../../habits/providers/habits_provider.dart';

final habitCompletionHistoryProvider =
    StreamProvider<List<HabitCompletionModel>>((ref) {
      final uid = ref.watch(currentUidProvider);
      if (uid == null) {
        return Stream.value(const <HabitCompletionModel>[]);
      }

      final repository = ref.watch(habitRepositoryProvider);
      return repository.watchCompletionHistory(uid);
    });

final progressStatsProvider = Provider<AsyncValue<ProgressStats>>((ref) {
  final habitsAsync = ref.watch(habitsProvider);
  final historyAsync = ref.watch(habitCompletionHistoryProvider);

  return habitsAsync.when(
    data: (habits) => historyAsync.when(
      data: (history) => AsyncData(
        ProgressStats.calculate(
          habits: habits,
          completionHistory: history,
          asOf: DateTime.now(),
        ),
      ),
      loading: () => const AsyncLoading(),
      error: AsyncError.new,
    ),
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
  );
});

class ProgressStats {
  const ProgressStats({
    required this.longestStreakDays,
    required this.totalCompleted,
    required this.weeklyActivity,
    required this.heatmapDays,
    required this.consistencyPercent,
    required this.activeDays,
    required this.insightTitle,
    required this.insightDescription,
  });

  final int longestStreakDays;
  final int totalCompleted;
  final List<DailyProgress> weeklyActivity;
  final List<HeatmapDay> heatmapDays;
  final int consistencyPercent;
  final int activeDays;
  final String insightTitle;
  final String insightDescription;

  static ProgressStats calculate({
    required List<HabitModel> habits,
    required List<HabitCompletionModel> completionHistory,
    required DateTime asOf,
  }) {
    final today = DateTime(asOf.year, asOf.month, asOf.day);
    final completionDatesByHabit = <String, Set<String>>{};
    var totalCompleted = 0;

    for (final record in completionHistory) {
      if (!record.wasCompleted || _parseDateKey(record.dateKey) == null) {
        continue;
      }

      totalCompleted++;
      final habitId = record.habitId;
      if (habitId != null && habitId.isNotEmpty) {
        completionDatesByHabit
            .putIfAbsent(habitId, () => <String>{})
            .add(record.dateKey);
      }
    }

    final todayKey = _dateKey(today);
    for (final habit in habits) {
      if (habit.isCompleted && habit.isCompletedForDate(today)) {
        final dates = completionDatesByHabit.putIfAbsent(
          habit.id,
          () => <String>{},
        );
        if (dates.add(todayKey)) totalCompleted++;
      }
    }

    Set<String> scheduledHabitIdsOn(DateTime date) {
      return habits
          .where((habit) {
            if (!_isScheduled(habit, date)) return false;
            final createdAt = habit.createdAt;
            if (createdAt == null) return true;
            final createdDate = DateTime(
              createdAt.year,
              createdAt.month,
              createdAt.day,
            );
            return !createdDate.isAfter(date);
          })
          .map((habit) => habit.id)
          .toSet();
    }

    int completedOn(DateTime date) {
      final dateKey = _dateKey(date);
      final scheduledHabitIds = scheduledHabitIdsOn(date);
      return completionDatesByHabit.entries
          .where(
            (entry) =>
                scheduledHabitIds.contains(entry.key) &&
                entry.value.contains(dateKey),
          )
          .length;
    }

    int dueOn(DateTime date) {
      return scheduledHabitIdsOn(date).length;
    }

    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weeklyActivity = List<DailyProgress>.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final due = dueOn(date);
      final completed = completedOn(date);
      final percent = due == 0 ? 0 : (completed * 100 / due).round();
      return DailyProgress(
        dayLabel: _weekdayLabels[index],
        completionPercent: percent.clamp(0, 100).toInt(),
        isHighlight: false,
      );
    });

    final bestPercent = weeklyActivity
        .map((activity) => activity.completionPercent)
        .reduce((a, b) => a > b ? a : b);
    var bestDayIndex = weeklyActivity.indexWhere(
      (day) =>
          day.dayLabel == _weekdayLabels[today.weekday - 1] &&
          day.completionPercent == bestPercent,
    );
    if (bestDayIndex < 0) {
      bestDayIndex = weeklyActivity.indexWhere(
        (day) => day.completionPercent == bestPercent,
      );
    }
    if (bestDayIndex >= 0 &&
        weeklyActivity[bestDayIndex].completionPercent > 0) {
      weeklyActivity[bestDayIndex] = DailyProgress(
        dayLabel: weeklyActivity[bestDayIndex].dayLabel,
        completionPercent: weeklyActivity[bestDayIndex].completionPercent,
        isHighlight: true,
      );
    }

    final heatmapDays = <HeatmapDay>[];
    var dueOpportunities = 0;
    var completedOpportunities = 0;
    var activeDays = 0;
    for (var index = 0; index < 30; index++) {
      final date = today.subtract(Duration(days: 29 - index));
      final due = dueOn(date);
      final completed = completedOn(date);
      dueOpportunities += due;
      completedOpportunities += completed.clamp(0, due).toInt();
      if (completed > 0) activeDays++;

      heatmapDays.add(
        HeatmapDay(
          dayIndex: date.day,
          dateLabel: _dateLabel(date),
          intensity: _intensityFor(completed, due),
          completedHabits: completed,
        ),
      );
    }

    final bestStreak = habits.fold<int>(
      0,
      (best, habit) => habit.streak > best ? habit.streak : best,
    );
    final consistencyPercent = dueOpportunities == 0
        ? 0
        : (completedOpportunities * 100 / dueOpportunities)
              .round()
              .clamp(0, 100)
              .toInt();
    final insight = _buildInsight(
      habits: habits,
      totalCompleted: totalCompleted,
      bestStreak: bestStreak,
      weeklyActivity: weeklyActivity,
    );

    return ProgressStats(
      longestStreakDays: bestStreak,
      totalCompleted: totalCompleted,
      weeklyActivity: weeklyActivity,
      heatmapDays: heatmapDays,
      consistencyPercent: consistencyPercent,
      activeDays: activeDays,
      insightTitle: insight.$1,
      insightDescription: insight.$2,
    );
  }

  static (String, String) _buildInsight({
    required List<HabitModel> habits,
    required int totalCompleted,
    required int bestStreak,
    required List<DailyProgress> weeklyActivity,
  }) {
    if (habits.isEmpty) {
      return (
        'Start your progress',
        'Add a habit to begin tracking your consistency and activity.',
      );
    }
    if (totalCompleted == 0) {
      return (
        'Your next step',
        'Complete a scheduled habit today to start building your activity history.',
      );
    }
    if (bestStreak > 0) {
      return (
        'Keep your streak going',
        'Your strongest current habit streak is $bestStreak ${bestStreak == 1 ? 'day' : 'days'}. Keep showing up to extend it.',
      );
    }

    final bestDay = weeklyActivity.reduce(
      (best, day) =>
          day.completionPercent > best.completionPercent ? day : best,
    );
    if (bestDay.completionPercent > 0) {
      return (
        'Your weekly rhythm',
        '${bestDay.dayLabel} is your strongest day this week at ${bestDay.completionPercent}% completion.',
      );
    }
    return (
      'Build your rhythm',
      'Keep completing your scheduled habits to see your weekly patterns here.',
    );
  }

  static bool _isScheduled(HabitModel habit, DateTime date) {
    return habit.frequency == 'Daily' ||
        habit.selectedDays.contains(date.weekday - 1);
  }

  static HeatmapIntensity _intensityFor(int completed, int due) {
    if (completed <= 0 || due <= 0) return HeatmapIntensity.low;
    final percent = completed * 100 / due;
    if (percent >= 75) return HeatmapIntensity.top;
    if (percent >= 50) return HeatmapIntensity.high;
    if (percent >= 25) return HeatmapIntensity.medium;
    return HeatmapIntensity.low;
  }

  static DateTime? _parseDateKey(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;

    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _dateLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  static const _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
}

class DailyProgress {
  const DailyProgress({
    required this.dayLabel,
    required this.completionPercent,
    required this.isHighlight,
  });

  final String dayLabel;
  final int completionPercent;
  final bool isHighlight;
}

class HeatmapDay {
  const HeatmapDay({
    required this.dayIndex,
    required this.dateLabel,
    required this.intensity,
    required this.completedHabits,
  });

  final int dayIndex;
  final String dateLabel;
  final HeatmapIntensity intensity;
  final int completedHabits;
}

enum HeatmapIntensity { low, medium, high, top }
