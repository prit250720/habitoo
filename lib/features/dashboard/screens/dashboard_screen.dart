import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../features/habits/providers/habits_provider.dart';
import '../../../shared/widgets/app_header.dart';
import '../providers/dashboard_provider.dart';
import '../providers/daily_tasks_provider.dart';
import '../widgets/dashboard_habit_card.dart';
import '../widgets/dashboard_insight_card.dart';
import '../widgets/dashboard_progress_card.dart';
import '../widgets/daily_task_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dailyTasksActionsProvider.notifier).ensureTodayTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dashboardAsync = ref.watch(dashboardProvider);
    final dailyTasksAsync = ref.watch(dailyTasksProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const AppHeader(
        avatarUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDppiJ6KNSQ_cj88gfQwiq_LsDzxTvZZ-1dK-G543mEbC6y8lYTO6vRDnYE-86S3o6UvZBChHE82jQHmz-vmJxPrzfZrpz36UNnLGHL89O1K2LQzRRfQ3HvtQ0NOPDse7uLs8vnoPyGANcf3uDzFJELkdNQZisUifj1ag1OjCGph7iiAP8a-mpjF31ecAzNfkyaGm_ArNXXWtEG-Tb-S83M8dcmyOnFY_eNebou9pmsMc5mRIWhbaaW',
      ),
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load habits.\n$e',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
          data: (state) => ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppUiTokens.screenPadding,
              16,
              AppUiTokens.screenPadding,
              140,
            ),
            children: [
              const SizedBox(height: AppUiTokens.sectionSpacing),
              Text(
                'Good morning',
                style: AppTextStyles.headlineLgMobile.copyWith(
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'ve stayed consistent. Keep the momentum going!',
                style: AppTextStyles.bodyMd.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              DashboardProgressCard(
                progressPercent: state.progressPercent,
                completedCount: state.completedCount,
                totalHabits: state.totalCount,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(
                    AppUiTokens.cardRadiusLarge,
                  ),
                  border: Border.all(color: cs.surfaceContainerHighest),
                  boxShadow: [
                    BoxShadow(
                      color: cs.onSurface.withValues(alpha: 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today\'s Habits',
                          style: AppTextStyles.headlineMd.copyWith(
                            color: cs.onSurface,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${state.totalCount} habits',
                            style: AppTextStyles.labelMd.copyWith(
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (state.habits.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No habits yet. Tap + to add your first one!',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...state.habits.map(
                        (habit) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DashboardHabitCard(
                            habit: habit,
                            onToggle: () => ref
                                .read(habitsActionsProvider.notifier)
                                .toggleHabitDone(habit),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(
                    AppUiTokens.cardRadiusLarge,
                  ),
                  border: Border.all(color: cs.surfaceContainerHighest),
                  boxShadow: [
                    BoxShadow(
                      color: cs.onSurface.withValues(alpha: 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today\'s Tasks',
                          style: AppTextStyles.headlineMd.copyWith(
                            color: cs.onSurface,
                          ),
                        ),
                        dailyTasksAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (e, st) => const SizedBox.shrink(),
                          data: (tasks) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${tasks.length} tasks',
                              style: AppTextStyles.labelMd.copyWith(
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    dailyTasksAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => Text(
                        'Could not load today\'s tasks. $error',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      data: (tasks) {
                        if (tasks.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Your daily tasks will appear here once they are generated.',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        return Column(
                          children: [
                            for (final task in tasks)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: DailyTaskCard(task: task),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppUiTokens.sectionSpacing),
              const DashboardInsightCard(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('addHabit'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
