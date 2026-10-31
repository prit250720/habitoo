import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../models/habit_model.dart';

class HabitListTile extends StatelessWidget {
  const HabitListTile({
    super.key,
    required this.habit,
    required this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  final HabitModel habit;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final periodColor = _periodColor(habit.period);

    return GestureDetector(
      onLongPress: () => _showOptionsMenu(context, cs, periodColor),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusMedium),
          border: Border(left: BorderSide(color: periodColor, width: 4)),
          boxShadow: [
            BoxShadow(
              color: cs.onSurface.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: AppTextStyles.headlineMd.copyWith(
                          color: cs.onSurface,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _chip(
                            label: habit.category,
                            background: periodColor.withValues(alpha: 0.12),
                            foreground: periodColor,
                          ),
                          _chip(
                            label: habit.frequency,
                            background: cs.surfaceContainerLow,
                            foreground: cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // ── More options button ──────────────────────────────────
                if (onEdit != null || onDelete != null)
                  GestureDetector(
                    onTap: () => _showOptionsMenu(context, cs, periodColor),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4, bottom: 4),
                      child: Icon(
                        Icons.more_vert,
                        color: cs.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                // ── Complete toggle ──────────────────────────────────────
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: habit.isCompleted
                          ? cs.primary
                          : periodColor.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      habit.isCompleted ? Icons.done_all : Icons.check,
                      color: habit.isCompleted ? cs.onPrimary : periodColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: cs.surfaceContainerHighest, thickness: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.local_fire_department, color: cs.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${habit.streak} day streak',
                  style: AppTextStyles.labelMd.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(
    BuildContext context,
    ColorScheme cs,
    Color periodColor,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    habit.name,
                    style: AppTextStyles.headlineMd.copyWith(
                      color: cs.onSurface,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Divider(color: cs.outlineVariant),
                // ── Edit ────────────────────────────────────────────────
                ListTile(
                  enabled: onEdit != null,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.edit_outlined, color: cs.primary),
                  ),
                  title: Text(
                    'Edit Habit',
                    style: AppTextStyles.bodyLg.copyWith(
                      color: onEdit != null
                          ? cs.onSurface
                          : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Change name, schedule or goal',
                    style: AppTextStyles.labelSm.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: onEdit == null
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                          onEdit?.call();
                        },
                ),
                // ── Delete ───────────────────────────────────────────────
                if (onDelete != null)
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cs.errorContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.delete_outline, color: cs.error),
                    ),
                    title: Text(
                      'Delete Habit',
                      style: AppTextStyles.bodyLg.copyWith(
                        color: cs.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'This cannot be undone',
                      style: AppTextStyles.labelSm.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      _confirmDelete(context, cs);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, ColorScheme cs) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text('"${habit.name}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(color: foreground),
      ),
    );
  }

  Color _periodColor(HabitPeriod period) {
    switch (period) {
      case HabitPeriod.morning:
        return const Color(0xFFB24A1D);
      case HabitPeriod.afternoon:
        return const Color(0xFF2A8A58);
      case HabitPeriod.evening:
        return const Color(0xFF7A2E2E);
      case HabitPeriod.night:
        return const Color(0xFF4F46E5);
    }
  }
}
