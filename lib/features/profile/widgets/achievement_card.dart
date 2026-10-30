import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../providers/profile_provider.dart';

class AchievementCard extends StatelessWidget {
  const AchievementCard({super.key, required this.achievement});

  final ProfileAchievement achievement;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = _colorFor(achievement.color, cs);
    final backgroundColor = _backgroundFor(achievement.color, cs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusSmall),
        border: Border.all(color: cs.surfaceContainerHighest, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _iconFor(achievement.icon),
                color: iconColor,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: AppTextStyles.labelMd.copyWith(color: cs.onSurface),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            achievement.subtitle,
            style: AppTextStyles.labelSm.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _colorFor(String colorKey, ColorScheme cs) {
    switch (colorKey) {
      case 'primary':
        return cs.primary;
      case 'secondary':
        return cs.secondary;
      case 'tertiary':
        return cs.tertiary;
      default:
        return cs.onSurfaceVariant;
    }
  }

  Color _backgroundFor(String colorKey, ColorScheme cs) {
    switch (colorKey) {
      case 'primary':
        return cs.primary.withValues(alpha: 0.1);
      case 'secondary':
        return cs.secondaryContainer.withValues(alpha: 0.25);
      case 'tertiary':
        return cs.tertiaryContainer.withValues(alpha: 0.35);
      default:
        return cs.surfaceContainerHighest;
    }
  }

  IconData _iconFor(String iconKey) {
    switch (iconKey) {
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'eco':
        return Icons.eco;
      case 'bolt':
        return Icons.bolt;
      default:
        return Icons.lock;
    }
  }
}
