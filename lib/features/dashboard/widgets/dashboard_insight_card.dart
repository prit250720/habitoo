import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_ui_tokens.dart';

class DashboardInsightCard extends StatelessWidget {
  const DashboardInsightCard({
    super.key,
    required this.completedCount,
    required this.totalCount,
  });

  final int completedCount;
  final int totalCount;

  String get _description {
    if (totalCount == 0) {
      return 'No habits are scheduled for today. Add a habit or review your schedule to get started.';
    }
    if (completedCount == totalCount) {
      return 'You have completed all $totalCount habits scheduled for today. Great job staying consistent!';
    }
    final remaining = totalCount - completedCount;
    return '$remaining ${remaining == 1 ? 'habit is' : 'habits are'} left for today. A small step now keeps your routine moving.';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Warm accent toned down in dark: use tertiaryContainer which adapts
        color: cs.tertiaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusLarge),
        border: Border.all(color: cs.surfaceContainerHighest),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: cs.primary,
              size: 36,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Insight',
                  style: AppTextStyles.headlineMd.copyWith(
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _description,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
