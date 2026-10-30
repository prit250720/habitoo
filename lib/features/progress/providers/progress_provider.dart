import 'package:flutter_riverpod/flutter_riverpod.dart';

final progressStatsProvider = Provider<ProgressStats>((ref) {
  return ProgressStats(
    longestStreakDays: 24,
    totalCompleted: 412,
    weeklyActivity: const [
      DailyProgress(dayLabel: 'Mon', completionPercent: 60, isHighlight: false),
      DailyProgress(dayLabel: 'Tue', completionPercent: 85, isHighlight: false),
      DailyProgress(dayLabel: 'Wed', completionPercent: 95, isHighlight: true),
      DailyProgress(dayLabel: 'Thu', completionPercent: 45, isHighlight: false),
      DailyProgress(dayLabel: 'Fri', completionPercent: 70, isHighlight: false),
      DailyProgress(dayLabel: 'Sat', completionPercent: 30, isHighlight: false),
      DailyProgress(dayLabel: 'Sun', completionPercent: 50, isHighlight: false),
    ],
    heatmapDays: List.generate(30, (index) {
      final paletteIndex = index % HeatmapIntensity.values.length;
      return HeatmapDay(
        dayIndex: index + 1,
        intensity: HeatmapIntensity.values[paletteIndex],
        completedHabits: 1 + (index % 6),
      );
    }),
    consistencyPercent: 92,
    activeDays: 28,
    insightTitle: 'Smart Insight',
    insightDescription:
        "You're most productive on Wednesdays. Consider scheduling your toughest habits for mid-week.",
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
    required this.intensity,
    required this.completedHabits,
  });

  final int dayIndex;
  final HeatmapIntensity intensity;
  final int completedHabits;
}

enum HeatmapIntensity { low, medium, high, top }
