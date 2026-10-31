import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../shared/widgets/app_header.dart';
import '../providers/habits_provider.dart';
import '../widgets/habit_list_tile.dart';

class MyHabitsScreen extends ConsumerWidget {
  const MyHabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const AppHeader(),
      body: SafeArea(
        child: habitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 48, color: cs.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Could not load habits.\n$e',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (habits) {
            final sections = <HabitPeriod, List<HabitModel>>{
              HabitPeriod.morning: habits
                  .where((h) => h.period == HabitPeriod.morning)
                  .toList(),
              HabitPeriod.evening: habits
                  .where((h) => h.period == HabitPeriod.evening)
                  .toList(),
              HabitPeriod.night: habits
                  .where((h) => h.period == HabitPeriod.night)
                  .toList(),
            };

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppUiTokens.screenPadding,
                8,
                AppUiTokens.screenPadding,
                120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Habits',
                    style: AppTextStyles.headlineLg.copyWith(
                      color: cs.onSurface,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Building momentum, one small win at a time.',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context: context,
                    ref: ref,
                    title: 'Morning',
                    icon: Icons.wb_sunny,
                    color: const Color(0xFFB24A1D),
                    habits: sections[HabitPeriod.morning] ?? [],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    context: context,
                    ref: ref,
                    title: 'Evening',
                    icon: Icons.light_mode,
                    color: const Color(0xFF2A8A58),
                    habits: sections[HabitPeriod.evening] ?? [],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    context: context,
                    ref: ref,
                    title: 'Night',
                    icon: Icons.bedtime,
                    color: const Color(0xFF7A2E2E),
                    habits: sections[HabitPeriod.night] ?? [],
                  ),
                  const SizedBox(height: 24),
                  _buildWeeklyGoalCard(context, habits),
                  const SizedBox(height: AppUiTokens.sectionSpacing),
                  _buildInsightCard(context, habits),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required IconData icon,
    required Color color,
    required List<HabitModel> habits,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.headlineMd.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 12),
        if (habits.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'No habits yet for this period.',
              style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant),
            ),
          )
        else
          ...habits.map(
            (habit) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HabitListTile(
                habit: habit,
                onToggle: () => ref
                    .read(habitsActionsProvider.notifier)
                    .toggleHabitDone(habit),
                onEdit: () => context.pushNamed('editHabit', extra: habit),
                onDelete: () => ref
                    .read(habitsActionsProvider.notifier)
                    .deleteHabit(habit.id),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWeeklyGoalCard(BuildContext context, List<HabitModel> habits) {
    final total = habits.length;
    final completed = habits.where((h) => h.isCompleted).length;
    final pct = total == 0 ? 0 : ((completed / total) * 100).round();

    // This card uses a branded dark-green gradient — kept as-is since it's
    // intentionally opaque and looks fine in both light and dark mode.
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F5132),
        borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusLarge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF1B7A4B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Goal',
                  style: AppTextStyles.headlineMd.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$pct% complete',
                  style: AppTextStyles.headlineLg.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$completed of $total habits done today',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: const Color(0xFFE6FFF4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, List<HabitModel> habits) {
    final cs = Theme.of(context).colorScheme;
    final topStreak = habits.isEmpty
        ? 0
        : habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusLarge),
        border: Border.all(color: cs.secondaryContainer.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.psychology, color: cs.secondary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sustainable Momentum',
                      style: AppTextStyles.headlineMd.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      topStreak > 0
                          ? 'Your longest active streak is $topStreak days. Keep it up!'
                          : 'Start a habit to build your streak!',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
