import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habitoo/features/progress/providers/progress_provider.dart';
import 'package:habitoo/features/progress/screens/progress_screen.dart';
import 'package:habitoo/features/progress/widgets/stat_card.dart';
import 'package:habitoo/features/progress/widgets/weekly_activity_card.dart';
import 'package:habitoo/shared/widgets/app_header.dart';

void main() {
  testWidgets(
    'weekly activity card renders seven bars when no data is provided',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WeeklyActivityCard(weeklyActivity: [])),
        ),
      );

      await tester.pump();

      final chart = tester.widget<BarChart>(find.byType(BarChart));
      expect(chart.data.barGroups, hasLength(7));
    },
  );

  testWidgets('progress screen renders the redesigned dashboard sections', (
    WidgetTester tester,
  ) async {
    final stats = ProgressStats(
      longestStreakDays: 24,
      totalCompleted: 412,
      weeklyActivity: const [
        DailyProgress(
          dayLabel: 'Mon',
          completionPercent: 60,
          isHighlight: false,
        ),
        DailyProgress(
          dayLabel: 'Tue',
          completionPercent: 85,
          isHighlight: false,
        ),
        DailyProgress(
          dayLabel: 'Wed',
          completionPercent: 95,
          isHighlight: true,
        ),
        DailyProgress(
          dayLabel: 'Thu',
          completionPercent: 45,
          isHighlight: false,
        ),
        DailyProgress(
          dayLabel: 'Fri',
          completionPercent: 70,
          isHighlight: false,
        ),
        DailyProgress(
          dayLabel: 'Sat',
          completionPercent: 30,
          isHighlight: false,
        ),
        DailyProgress(
          dayLabel: 'Sun',
          completionPercent: 50,
          isHighlight: false,
        ),
      ],
      heatmapDays: const [],
      consistencyPercent: 92,
      activeDays: 28,
      insightTitle: 'Smart Insight',
      insightDescription:
          'You\'re most productive on Wednesdays. Consider scheduling your toughest habits for mid-week.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressStatsProvider.overrideWithValue(AsyncData(stats)),
        ],
        child: const MaterialApp(home: ProgressScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Progress Dashboard'), findsOneWidget);
    expect(find.text('Strongest Current Streak'), findsOneWidget);
    expect(find.byType(WeeklyActivityCard), findsOneWidget);
    expect(find.byType(StatCard), findsAtLeastNWidgets(2));
    expect(find.byType(AppHeader), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
  });
}
