import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../providers/profile_provider.dart';

class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key, required this.profile});

  final ProfileSettingsState profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    // Watch the live Firestore stream directly so this widget rebuilds
    // whenever XP or level changes in Firestore.
    final liveUser = ref.watch(userDocProvider).asData?.value;

    final name = liveUser?.name.isNotEmpty == true
        ? liveUser!.name
        : profile.name;
    final avatarUrl = liveUser?.avatarUrl.isNotEmpty == true
        ? liveUser!.avatarUrl
        : profile.avatarUrl;
    final level = liveUser?.level ?? profile.level;
    final xp = liveUser?.xp ?? profile.xp;
    final xpGoal = liveUser?.xpGoal ?? profile.xpGoal;
    final progress = xpGoal > 0 ? xp / xpGoal : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cs.primaryContainer,
                    width: 3,
                  ),
                ),
                child: AppAvatar(
                  imageUrl: avatarUrl,
                  size: 88,
                  radius: 44,
                  backgroundColor: cs.surfaceContainerLowest,
                  foregroundColor: cs.primary,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AppTextStyles.headlineLgMobile.copyWith(
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'LVL $level',
                            style: AppTextStyles.labelSm.copyWith(
                              color: cs.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.title,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _pill('Consistency King', cs.primaryContainer, cs),
                        _pill('Early Bird', cs.secondaryContainer, cs),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress to Level ${level + 1}',
                    style: AppTextStyles.labelMd.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '$xp / $xpGoal XP',
                    style: AppTextStyles.labelMd.copyWith(color: cs.primary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primaryContainer),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }
}
