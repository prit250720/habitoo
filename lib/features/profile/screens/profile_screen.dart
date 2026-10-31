import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../controllers/phone_auth_controller.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/utils/profile_qr_code.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../utils/shared_prefs_helper.dart';
import '../providers/profile_provider.dart';
import '../widgets/achievement_card.dart';
import '../widgets/profile_header.dart';
import '../widgets/settings_tile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final profile = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);
    final userAsync = ref.watch(userDocProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppHeader(
        backgroundColor: cs.surface,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppUiTokens.screenPadding,
            12,
            AppUiTokens.screenPadding,
            120,
          ),
          children: [
            userAsync.when(
              loading: () => const _ProfileHeaderSkeleton(),
              error: (error, stackTrace) => ProfileHeader(profile: profile),
              data: (liveUser) => ProfileHeader(profile: profile),
            ),
            if (uid != null) ...[
              const SizedBox(height: 20),
              _buildProfileQrCard(context, cs, uid),
            ],
            const SizedBox(height: 24),
            _buildAchievementsSection(context, cs, profile),
            const SizedBox(height: 24),
            _buildSettingsSection(context, ref, cs, profile, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileQrCard(
    BuildContext context,
    ColorScheme cs,
    String uid,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Text(
            'Your unique Profile QR',
            style: AppTextStyles.headlineMd.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            'Show this code on another screen to dismiss a QR alarm.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: ProfileQrCode.dataForUid(uid),
              version: QrVersions.auto,
              size: 190,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(
      BuildContext context, ColorScheme cs, ProfileSettingsState profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievements',
              style: AppTextStyles.headlineMd.copyWith(color: cs.onSurface),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: AppTextStyles.labelMd.copyWith(color: cs.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: profile.achievements.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            return AchievementCard(achievement: profile.achievements[index]);
          },
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    WidgetRef ref,
    ColorScheme cs,
    ProfileSettingsState profile,
    ProfileNotifier notifier,
  ) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Settings',
              style: AppTextStyles.headlineMd.copyWith(color: cs.onSurface),
            ),
          ),
          Divider(height: 1, color: cs.surfaceContainerHighest),
          SettingsTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            description: 'Adjust visual appearance',
            trailing: Switch.adaptive(
              value: isDark,
              activeThumbColor: cs.primaryContainer,
              activeTrackColor: cs.primaryFixed,
              inactiveThumbColor: cs.surfaceContainerLowest,
              inactiveTrackColor: cs.surfaceContainerHighest,
              onChanged: (value) {
                ref.read(themeProvider.notifier).setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
              },
            ),
          ),
          Divider(height: 1, color: cs.surfaceContainerHighest),
          SettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            description: 'Manage habit alerts and sounds',
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ),
          Divider(height: 1, color: cs.surfaceContainerHighest),
          SettingsTile(
            icon: Icons.schedule,
            title: 'Reminders',
            description: 'Customize your daily nudge times',
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ),
          Divider(height: 1, color: cs.surfaceContainerHighest),
          SettingsTile(
            icon: Icons.security,
            title: 'Privacy & Security',
            description: 'Data usage and account safety',
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ),
          Divider(height: 1, color: cs.surfaceContainerHighest),
          SettingsTile(
            icon: Icons.logout,
            title: 'Logout',
            description: 'Sign out of your account',
            isDestructive: true,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        'Logout',
                        style: TextStyle(color: cs.error),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                final phone = await SharedPrefsHelper.getPhoneNumber();
                await ref
                    .read(phoneAuthControllerProvider.notifier)
                    .logout(phoneNumber: phone);
                await ref.read(authControllerProvider.notifier).signOut();
              }
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------

class _ProfileHeaderSkeleton extends StatelessWidget {
  const _ProfileHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
              _Shimmer(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Shimmer(
                      child: Container(
                        height: 20,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _Shimmer(
                      child: Container(
                        height: 14,
                        width: 140,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Flexible(
                          child: _Shimmer(
                            child: Container(
                              height: 28,
                              constraints: const BoxConstraints(maxWidth: 90),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: _Shimmer(
                            child: Container(
                              height: 28,
                              constraints: const BoxConstraints(maxWidth: 70),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Shimmer(
            child: Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});
  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}
