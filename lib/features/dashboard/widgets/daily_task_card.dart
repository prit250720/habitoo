import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../services/sound_service.dart';
import '../providers/daily_tasks_provider.dart';

// ---------------------------------------------------------------------------
// Shared helper — shows the XP snackbar when XP is earned.
// ---------------------------------------------------------------------------

void _showXpSnackbar(BuildContext context, int xpAmount) {
  final cs = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      backgroundColor: cs.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusSmall),
      ),
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          Icon(Icons.bolt_rounded, color: cs.onPrimaryContainer, size: 20),
          const SizedBox(width: 10),
          Text(
            '+$xpAmount XP earned!',
            style: AppTextStyles.labelMd.copyWith(color: cs.onPrimaryContainer),
          ),
          const Spacer(),
          Icon(
            Icons.check_circle_rounded,
            color: cs.onPrimaryContainer.withValues(alpha: 0.6),
            size: 18,
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Card widget
// ---------------------------------------------------------------------------

class DailyTaskCard extends ConsumerWidget {
  const DailyTaskCard({super.key, required this.task});

  final DailyTaskModel task;

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref, {
    bool popAfter = false,
  }) async {
    // Capture whether this tap is marking the task complete (not undoing it).
    final isMarkingComplete = !task.completed;

    final result = await ref
        .read(dailyTasksActionsProvider.notifier)
        .toggleTaskCompletion(task);

    // Play the completion chime only when the user is completing (not unchecking).
    if (isMarkingComplete) {
      unawaited(SoundService.playTaskComplete());
    }

    if (!context.mounted) return;
    if (popAfter) Navigator.of(context).pop();
    if (result.xpAwarded) _showXpSnackbar(context, result.xpAmount);
  }

  void _showDetailDialog(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Theme.of(dialogCtx).colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusLarge),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(dialogCtx).height * 0.8,
          ),
          child: SingleChildScrollView(
            child: _DailyTaskDetailContent(
              task: task,
              onToggle: (ctx) => _toggle(ctx, ref, popAfter: true),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isCompleted = task.completed;

    return GestureDetector(
      onLongPress: () => _showDetailDialog(context, ref),
      child: Container(
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
            // Left accent bar
            Container(
              width: 4,
              height: 48,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: isCompleted ? cs.outlineVariant : cs.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: AppTextStyles.labelMd.copyWith(
                      color: cs.onSurface,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: cs.onSurface,
                      decorationThickness: 2,
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: AppTextStyles.labelSm.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _pill(context, task.category, cs),
                      const SizedBox(width: 8),
                      _pill(context, '+${task.xp} XP', cs),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Custom circular toggle
            GestureDetector(
              onTap: () => _toggle(context, ref),
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
                  color: isCompleted ? cs.onPrimaryContainer : cs.outline,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, String label, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(color: cs.primary),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Centered task detail dialog
// ---------------------------------------------------------------------------

class _DailyTaskDetailContent extends StatelessWidget {
  const _DailyTaskDetailContent({required this.task, required this.onToggle});

  final DailyTaskModel task;

  /// Called with the dialog's [BuildContext] so it can be closed after toggling.
  final Future<void> Function(BuildContext ctx) onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCompleted = task.completed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _statusBadge(cs, isCompleted),
                  _pill(task.category, cs),
                  _xpBadge(cs),
                ],
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                task.title,
                style: AppTextStyles.headlineMd.copyWith(
                  color: cs.onSurface,
                  decoration: isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: cs.onSurface,
                  decorationThickness: 2,
                ),
              ),

              // Description
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  task.description,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Divider(color: cs.surfaceContainerHighest, height: 1),
              const SizedBox(height: 20),

              // Meta rows
              _metaRow(
                cs,
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: task.date.isNotEmpty ? task.date : 'Today',
              ),
              if (task.habitId != null && task.habitId!.isNotEmpty) ...[
                const SizedBox(height: 14),
                _metaRow(
                  cs,
                  icon: Icons.loop_outlined,
                  label: 'Linked Habit',
                  value: task.habitId!,
                ),
              ],
              if (task.createdAt != null) ...[
                const SizedBox(height: 14),
                _metaRow(
                  cs,
                  icon: Icons.access_time_outlined,
                  label: 'Created',
                  value: _formatDateTime(task.createdAt!),
                ),
              ],

              // XP awarded indicator
              if (task.xpEverAwarded) ...[
                const SizedBox(height: 14),
                _metaRow(
                  cs,
                  icon: Icons.bolt_rounded,
                  label: 'XP Status',
                  value: '+${task.xp} XP already credited',
                ),
              ],

              const SizedBox(height: 28),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: isCompleted
                        ? cs.surfaceContainerHigh
                        : cs.primary,
                    foregroundColor: isCompleted
                        ? cs.onSurfaceVariant
                        : cs.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppUiTokens.buttonRadius,
                      ),
                    ),
                  ),
                  onPressed: () => onToggle(context),
                  icon: Icon(
                    isCompleted
                        ? Icons.undo_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 20,
                  ),
                  label: Text(
                    isCompleted ? 'Mark as Incomplete' : 'Mark as Complete',
                    style: AppTextStyles.labelMd.copyWith(
                      color: isCompleted ? cs.onSurfaceVariant : cs.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(ColorScheme cs, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted
            ? cs.primaryContainer.withValues(alpha: 0.25)
            : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: isCompleted ? cs.primary : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            isCompleted ? 'Completed' : 'Pending',
            style: AppTextStyles.labelSm.copyWith(
              color: isCompleted ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(color: cs.primary),
      ),
    );
  }

  Widget _xpBadge(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 14, color: cs.tertiary),
          const SizedBox(width: 4),
          Text(
            '+${task.xp} XP',
            style: AppTextStyles.labelSm.copyWith(color: cs.tertiary),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.labelMd.copyWith(color: cs.onSurface),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
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
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute';
  }
}
