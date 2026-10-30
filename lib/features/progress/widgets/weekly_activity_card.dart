import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../providers/progress_provider.dart';

class WeeklyActivityCard extends StatelessWidget {
  const WeeklyActivityCard({super.key, required this.weeklyActivity});

  final List<DailyProgress> weeklyActivity;

  static const List<DailyProgress> _fallbackWeeklyActivity = [
    DailyProgress(dayLabel: 'Mon', completionPercent: 0, isHighlight: false),
    DailyProgress(dayLabel: 'Tue', completionPercent: 0, isHighlight: false),
    DailyProgress(dayLabel: 'Wed', completionPercent: 0, isHighlight: false),
    DailyProgress(dayLabel: 'Thu', completionPercent: 0, isHighlight: false),
    DailyProgress(dayLabel: 'Fri', completionPercent: 0, isHighlight: false),
    DailyProgress(dayLabel: 'Sat', completionPercent: 0, isHighlight: false),
    DailyProgress(dayLabel: 'Sun', completionPercent: 0, isHighlight: false),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentDayIndex = DateTime.now().weekday - 1;
    final chartData = weeklyActivity.isEmpty
        ? _fallbackWeeklyActivity
        : weeklyActivity.length >= 7
            ? weeklyActivity.sublist(0, 7)
            : List<DailyProgress>.generate(7, (index) {
                if (index < weeklyActivity.length) {
                  return weeklyActivity[index];
                }
                return const DailyProgress(
                  dayLabel: '',
                  completionPercent: 0,
                  isHighlight: false,
                );
              });

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusLarge),
        border: Border.all(color: cs.surfaceContainerHighest),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Activity',
                style: AppTextStyles.headlineMd.copyWith(
                  color: cs.onSurface,
                  fontSize: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'This Week',
                  style: AppTextStyles.labelSm.copyWith(color: cs.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.8,
            child: BarChart(
              BarChartData(
                maxY: 100,
                groupsSpace: 12,
                alignment: BarChartAlignment.spaceBetween,
                barTouchData: const BarTouchData(enabled: false),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= chartData.length) {
                          return const SizedBox.shrink();
                        }
                        final dayLabel = chartData[index].dayLabel;
                        if (dayLabel.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dayLabel,
                            style: AppTextStyles.labelSm.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: chartData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final day = entry.value;
                  final isCurrentDay = index == currentDayIndex;
                  return BarChartGroupData(
                    x: index,
                    barsSpace: 6,
                    barRods: [
                      BarChartRodData(
                        toY: day.completionPercent.toDouble(),
                        width: 24,
                        borderRadius: BorderRadius.circular(12),
                        color: day.isHighlight || isCurrentDay
                            ? cs.primary
                            : cs.primaryContainer,
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: cs.surfaceContainerLow,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
