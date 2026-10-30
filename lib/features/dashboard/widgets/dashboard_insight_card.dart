import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_ui_tokens.dart';

class DashboardInsightCard extends StatelessWidget {
  const DashboardInsightCard({super.key});

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
                  'Sustainable Insight',
                  style: AppTextStyles.headlineMd.copyWith(
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Users who complete their reading habit before 9 PM are 35% more likely to maintain a 7-day streak. Try setting a reminder for 8:30 PM today.',
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
