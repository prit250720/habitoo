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
    final stats = ref.watch(progressStatsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppHeader(
        avatarUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBuw0_khAZCMuTWgiyenyOyBi6nL_Ey55Ki_utNaGBKqUimvxYpZWlY-Ub5fMH3oq2zNGXzw_tfl2iVb9bzIa7LGFsyJKA_NdMKoFHZjpH6QnDgAi1UQQyOfy5YgDtvocQPo9WRvI7J5OPTfvrccH2mYOBE7N2Ya2uEvxmtYVCIlCYd5jJmpeOSm3Xyg3KJj046h18usfIAfqGFNE6DotfG39e398OgILwUUVQKxJmqZz1qkGnzc8ZJ',
        backgroundColor: cs.surface,
      ),
      body: SafeArea(
        child: LayoutBuilder(
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
                  'Celebrating your consistent wins and growth momentum.',
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
                        title: 'Longest Streak',
                        label: 'Current streak',
                        value: '${stats.longestStreakDays}',
                        metricLabel: 'days',
                        trendText:
                            '${stats.longestStreakDays - 20}% better than last month',
                        accentColor: cs.primary,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Total Completed',
                        label: 'Lifetime completions',
                        value: '${stats.totalCompleted}',
                        metricLabel: '',
                        trendText: '+14% better than last month',
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
    );
  }
}
