import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_ui_tokens.dart';
import 'app_avatar.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title = 'Habitoo',
    this.onMenuTap,
    this.avatarUrl,
    this.backgroundColor,
    this.avatarSize = 44,
    this.avatarRadius = 22,
  });

  final String title;
  final VoidCallback? onMenuTap;
  final String? avatarUrl;
  final Color? backgroundColor;
  final double avatarSize;
  final double avatarRadius;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return AppBar(
      backgroundColor: backgroundColor ?? cs.surface,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppUiTokens.screenPadding),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppUiTokens.buttonRadius),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.menu, color: cs.primary),
            onPressed: onMenuTap ?? () {},
          ),
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.headlineMd.copyWith(color: cs.primary),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppUiTokens.screenPadding),
          child: AppAvatar(
            imageUrl: avatarUrl,
            size: avatarSize,
            radius: avatarRadius,
            backgroundColor: cs.surfaceContainerLowest,
            foregroundColor: cs.primary,
          ),
        ),
      ],
    );
  }
}
