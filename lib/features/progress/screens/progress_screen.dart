import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../shared/widgets/app_header.dart';
import '../providers/progress_provider.dart';
import '../widgets/activity_heatmap.dart';
import '../widgets/insight_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/weekly_activity_card.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final statsAsync = ref.watch(progressStatsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppHeader(
        backgroundColor: cs.surface,
      ),
      body: SafeArea(
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load your progress.\n$error',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
          data: (stats) => LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final cardWidth = isWide
                  ? (constraints.maxWidth - 20) / 2
                  : constraints.maxWidth;

              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppUiTokens.screenPadding,
                  8,
                  AppUiTokens.screenPadding,
                  120,
                ),
                children: [
                  Text(
                    'Progress Dashboard',
                    style: AppTextStyles.headlineLgMobile.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your habit activity updates as you complete habits.',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    runSpacing: 20,
                    spacing: 20,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: StatCard(
                          title: 'Strongest Current Streak',
                          label: 'Across your active habits',
                          value: '${stats.longestStreakDays}',
                          metricLabel: 'days',
                          trendText: stats.longestStreakDays == 0
                              ? 'Complete a habit to start a streak'
                              : 'Live from your current habit streaks',
                          accentColor: cs.primary,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: StatCard(
                          title: 'Total Completed',
                          label: 'Recorded habit completions',
                          value: '${stats.totalCompleted}',
                          metricLabel: '',
                          trendText: 'Updated from your completion history',
                          accentColor: cs.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  WeeklyActivityCard(weeklyActivity: stats.weeklyActivity),
                  const SizedBox(height: 24),
                  ActivityHeatmap(
                    heatmapDays: stats.heatmapDays,
                    consistencyPercent: stats.consistencyPercent,
                    activeDays: stats.activeDays,
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: isWide
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: SizedBox(
                      width: isWide ? 460 : double.infinity,
                      child: InsightCard(
                        title: stats.insightTitle,
                        description: stats.insightDescription,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
