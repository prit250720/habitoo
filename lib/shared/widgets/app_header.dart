import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../providers/user_provider.dart';
import 'app_avatar.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title = 'Habitoo',
    this.onMenuTap,
    this.onBackTap,
    this.backEnabled = true,
    this.avatarUrl,
    this.backgroundColor,
    this.showAvatar = true,
    this.avatarSize = 40,
    this.avatarRadius = 20,
  });

  final String title;
  final VoidCallback? onMenuTap;
  final VoidCallback? onBackTap;
  final bool backEnabled;
  final String? avatarUrl;
  final Color? backgroundColor;
  final bool showAvatar;
  final double avatarSize;
  final double avatarRadius;

  @override
  Size get preferredSize => const Size.fromHeight(AppUiTokens.appBarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final fallbackAvatarUrl = avatarUrl ?? ref.watch(profileProvider).avatarUrl;
    final userAvatarUrl = ref
        .watch(userDocProvider)
        .maybeWhen(
          data: (user) {
            final url = user?.avatarUrl.trim() ?? '';
            return url.isEmpty ? fallbackAvatarUrl : url;
          },
          orElse: () => fallbackAvatarUrl,
        );

    return AppBar(
      backgroundColor: backgroundColor ?? cs.surface,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppUiTokens.screenPadding),
        child: SizedBox(
          width: 36,
          height: 36,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppUiTokens.buttonRadius),
            ),
            child: onBackTap != null || onMenuTap != null
                ? IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: onBackTap != null ? 'Back' : 'Menu',
                    icon: Icon(
                      onBackTap != null
                          ? Icons.arrow_back_rounded
                          : Icons.menu_rounded,
                      color: cs.primary,
                    ),
                    onPressed: onBackTap != null && !backEnabled
                        ? null
                        : onBackTap ?? onMenuTap,
                  )
                : Icon(Icons.bolt_rounded, color: cs.primary, size: 25),
          ),
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.headlineMd.copyWith(
          color: cs.onSurface,
          fontSize: 20,
        ),
      ),
      actions: showAvatar
          ? [
              Padding(
                padding: const EdgeInsets.only(
                  right: AppUiTokens.screenPadding,
                ),
                child: AppAvatar(
                  imageUrl: userAvatarUrl,
                  size: avatarSize,
                  radius: avatarRadius,
                  backgroundColor: cs.surfaceContainerLowest,
                  foregroundColor: cs.primary,
                ),
              ),
            ]
          : null,
    );
  }
}
