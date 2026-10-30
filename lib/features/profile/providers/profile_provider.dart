import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileSettingsState {
  const ProfileSettingsState({
    required this.name,
    required this.title,
    required this.level,
    required this.xp,
    required this.xpGoal,
    required this.avatarUrl,
    required this.isDarkMode,
    required this.notificationsEnabled,
    required this.remindersEnabled,
    required this.privacyEnabled,
    required this.achievements,
  });

  final String name;
  final String title;
  final int level;
  final int xp;
  final int xpGoal;
  final String avatarUrl;
  final bool isDarkMode;
  final bool notificationsEnabled;
  final bool remindersEnabled;
  final bool privacyEnabled;
  final List<ProfileAchievement> achievements;

  ProfileSettingsState copyWith({
    String? name,
    String? title,
    int? level,
    int? xp,
    int? xpGoal,
    String? avatarUrl,
    bool? isDarkMode,
    bool? notificationsEnabled,
    bool? remindersEnabled,
    bool? privacyEnabled,
    List<ProfileAchievement>? achievements,
  }) {
    return ProfileSettingsState(
      name: name ?? this.name,
      title: title ?? this.title,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      xpGoal: xpGoal ?? this.xpGoal,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      privacyEnabled: privacyEnabled ?? this.privacyEnabled,
      achievements: achievements ?? this.achievements,
    );
  }
}

class ProfileAchievement {
  const ProfileAchievement({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isLocked,
  });

  final String title;
  final String subtitle;
  final String icon;
  final String color;
  final bool isLocked;
}

class ProfileNotifier extends Notifier<ProfileSettingsState> {
  @override
  ProfileSettingsState build() {
    return const ProfileSettingsState(
      name: 'Alex Rivers',
      title: 'Sustainable Growth Enthusiast',
      level: 1,
      xp: 0,
      xpGoal: 100,
      avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCcKjPeMM4ygu32QAFBGPtx1RGYUY1C9K3_O92Xx3WmYiZTqz9t9aKaG5GydRcJCHkdgzt_s8Xb0_rwh9BKVShITt2TYRJ7M-ocY4WOhmOw3gIpQ4j0CmSJESxFSvXwLKWEUU9jQ9oDAN7vXWDMSQ7W7CF9WYVVBntV1U_gs0iiZqnfHdsV5rRi8xPmlKghc4489SdPkzrTghcSRZGuT19E-u85_knk8LsJ8_pf0wb_rpD6NUYIyEOR',
      isDarkMode: false,
      notificationsEnabled: true,
      remindersEnabled: true,
      privacyEnabled: false,
      achievements: [
        ProfileAchievement(
          title: '7-Day Streak',
          subtitle: 'Consistency is key',
          icon: 'workspace_premium',
          color: 'tertiary',
          isLocked: false,
        ),
        ProfileAchievement(
          title: 'Zen Master',
          subtitle: '30 sessions completed',
          icon: 'eco',
          color: 'primary',
          isLocked: false,
        ),
        ProfileAchievement(
          title: 'Fast Starter',
          subtitle: 'Morning routine locked',
          icon: 'bolt',
          color: 'secondary',
          isLocked: false,
        ),
        ProfileAchievement(
          title: 'Goal Crusher',
          subtitle: 'Reach Level 15',
          icon: 'lock',
          color: 'surface',
          isLocked: true,
        ),
      ],
    );
  }

  void toggleDarkMode(bool value) {
    state = state.copyWith(isDarkMode: value);
  }

  void toggleNotifications(bool value) {
    state = state.copyWith(notificationsEnabled: value);
  }

  void toggleReminders(bool value) {
    state = state.copyWith(remindersEnabled: value);
  }

  void togglePrivacy(bool value) {
    state = state.copyWith(privacyEnabled: value);
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileSettingsState>(
  ProfileNotifier.new,
);
