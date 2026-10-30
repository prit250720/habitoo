import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_ui_tokens.dart';

class DashboardProgressCard extends StatelessWidget {
  const DashboardProgressCard({
    super.key,
    required this.progressPercent,
    required this.completedCount,
    required this.totalHabits,
  });

  final double progressPercent;
  final int completedCount;
  final int totalHabits;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progressValue = (progressPercent / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusLarge),
        border: Border.all(color: cs.surfaceContainerHighest),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useRowLayout = constraints.maxWidth > 520;

          return useRowLayout
              ? Row(
                  children: [
                    Expanded(child: _buildContent(context, cs)),
                    const SizedBox(width: 24),
                    _buildProgressRing(cs, progressValue),
                  ],
                )
              : Column(
                  children: [
                    _buildContent(context, cs),
                    const SizedBox(height: 24),
                    _buildProgressRing(cs, progressValue),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: AppTextStyles.headlineMd.copyWith(color: cs.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          'You have completed $completedCount out of $totalHabits habits for today.',
          style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant),
          maxLines: 3,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 44,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: () {},
            child: Text(
              'View Stats',
              style: AppTextStyles.labelMd.copyWith(color: cs.onPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressRing(ColorScheme cs, double progressValue) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: CircularProgressIndicator(
            value: progressValue,
            strokeWidth: 12,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(cs.primaryContainer),
          ),
        ),
        Text(
          '${progressPercent.round()}%',
          style: AppTextStyles.headlineLg.copyWith(color: cs.primary),
        ),
      ],
    );
  }
}
