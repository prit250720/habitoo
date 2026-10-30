import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../models/habit_model.dart';

class DashboardHabitCard extends StatelessWidget {
  const DashboardHabitCard({
    super.key,
    required this.habit,
    required this.onToggle,
  });

  final HabitModel habit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCompleted = habit.isCompleted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCompleted
            ? cs.surfaceContainerLow
            : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusMedium),
        border: Border.all(
          color: isCompleted
              ? cs.surfaceContainerHighest
              : cs.primaryContainer.withValues(alpha: 0.25),
          width: isCompleted ? 1 : 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: habit.accentColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: AppTextStyles.labelMd.copyWith(
                    color: cs.onSurface,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: cs.onSurface,
                    decorationThickness: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${habit.reminderTime} • ${habit.category}',
                  style: AppTextStyles.labelSm.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isCompleted
                    ? cs.primaryContainer
                    : cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isCompleted
                      ? cs.primaryContainer
                      : cs.outlineVariant,
                  width: 2,
                ),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: isCompleted
                    ? cs.onPrimaryContainer
                    : cs.outline,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
